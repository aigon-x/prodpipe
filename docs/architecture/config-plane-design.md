# Config Plane — architektura "najlepszego configu na świecie" dla szkieletu

> Design doc — źródło specyfikacji dla implementacji Config Plane.
> Status: DESIGN (do implementacji).

## Cel

Config Plane to warstwa konfiguracyjna, która pozwala systemowi **konfigurować sam siebie i sam to sprawdzać**. Każde zadanie dostaje swoje gate'y, każda zmiana configu przechodzi przez te same gate'y co kod (self-hosting), a każda decyzja jest audytowalna (snapshot + trace).

## Warstwy (L0-L7)

| Warstwa | Co | Kto edytuje |
|---|---|---|
| L0 | defaulty (registry) | platform |
| L1 | org floors (minimalne progi) | platform |
| L2 | profile (fast/full/release/genesis) | platform |
| L3 | profile override | platform |
| L4 | service config | service owner |
| L5 | hotfix / context rules (z diffu) | platform |
| L6 | waivers (wyjątki, wygasają) | approver |
| L7 | kill-switches (awaryjne, pełny audit) | platform |

## 4 prawa configu

1. **Tighten zawsze przechodzi** — podniesienie progu nie wymaga zgody.
2. **Relax wymaga waivera** — obniżenie progu poniżej floora = REJECTED bez waivera.
3. **Wyjątki wygasają** — waiver bez `expires_at` jest nielegalny.
4. **Każda decyzja ma trace** — resolver zapisuje pełny ślad (snapshot + trace).

## Definicja gate'a parametryzowana

```yaml
gates:
  coverage.min_percent:
    default: 80
    floor: 60                # L1: org nie pozwala niżej bez waivera
    ratchet: true            # anti-entropy: per-serwis może TYLKO rosnąć
    reload: hot
    doc: "Minimalne pokrycie branch coverage"
    owner: platform
    tier: stable
```

`ratchet: true` to anti-entropy wbudowane w config: resolver zapisuje per-serwis ostatnią osiągniętą wartość i nowy config nie może jej obniżyć (bez waivera). System sam się dokręca.

## Config serwisu — co wolno, czego nie

```yaml
# billing-api/.skeleton.yaml
service: { id: billing-api, tier: 1 }
gates:
  coverage.min_percent: 95        # ✅ tighten powyżej defaultu — przechodzi bez pytania
  # security.sast.max_critical: 3  # ❌ ODRZUONE: floor=0, to wymaga waivera
waivers:
  - check_id: e2e-legacy-suite
    justification: "migracja runnera, ticket PLAT-1234"
    approved_by: "@platform-lead"
    expires_at: 2026-09-01        # brak daty = config nie przechodzi walidacji
```

Resolver przy każdym runie liczy **effective config** i zapisuje pełny ślad:

```json
{
  "snapshot": "cfg-a3f9c2",
  "key": "gates.coverage.min_percent", "value": 95,
  "trace": [
    {"layer": "L0 default",  "value": 80},
    {"layer": "L1 floor",    "constraint": ">=60"},
    {"layer": "L3 profile",  "value": 80},
    {"layer": "L4 service",  "value": 95, "result": "WIN (tighten)"},
    {"layer": "L5 hotfix",   "value": 70, "result": "REJECTED (relax bez waivera)"}
  ]
}
```

To odpowiada na pytanie "dlaczego ten gate zablokował z takim progiem?" — na zawsze, z evidence, per run.

## Zmiana configu przechodzi przez te same gate'y (self-hosting)

```
PR do config/ → G1: review (CODEOWNERS: registry+ floors = tylko platform)
              → CFG-001..008: schema, klucze, docs, defaulty
              → CFG-SIM: symulacja dry-run (poniżej)
              → merge → config-deploy → kompilacja YAML→SQLite → nowy snapshot
```

**CFG-SIM — symulacja przed zastosowaniem** (zabójcza funkcja):

```sql
-- Dla każdego aktywnego serwisu × kontekstu: resolve(stary) vs resolve(nowy), diff:
SELECT service_id, gate_id, old_value, new_value, change_kind
FROM config_simulation
WHERE change_kind IN ('GATE_LOST', 'THRESHOLD_LOOSENED');
-- niepusty wynik = PR wymaga explicite aprobaty platformy albo waivera
```

Zmiana configu, która **odbiera komukolwiek gate'a albo luzuje próg, nie może przejść cicho**. To anti-drift dla samego configu.

## Schemat DB: snapshoty, waivers, ratchet

```sql
-- migrations/0006_config_plane.sql
CREATE TABLE config_snapshots (
  id INTEGER PRIMARY KEY,
  hash TEXT NOT NULL UNIQUE,          -- hash zmaterializowanego effective configu
  git_sha TEXT NOT NULL,              -- wersja źródeł configu
  waiver_set_version INTEGER NOT NULL,
  effective_json TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
-- evidence dostaje: ALTER TABLE evidence ADD COLUMN snapshot_id INTEGER REFERENCES config_snapshots(id);
-- → każdy wynik gate'a wskazuje DOKŁADNY config, który podjął decyzję (reprodukowalność!)

CREATE TABLE config_ratchet (          -- stan ratchetingu per serwis/klucz
  service_id TEXT NOT NULL,
  key TEXT NOT NULL,
  achieved_value REAL NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (service_id, key)
);

CREATE TABLE config_kill_switches (    -- L7: awaryjne, pełny audit
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL, value TEXT NOT NULL,
  activated_by TEXT NOT NULL, reason TEXT NOT NULL,
  expires_at TEXT NOT NULL,            -- nawet kill-switch wygasa
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
```

Reload: klucze `reload: hot` działają od następnego runu (resolver czyta świeży snapshot), `cold` wymagają redeployu. Każdy run zapisuje `snapshot_id` → brak "w połowie pipeline'u config się zmienił".

## Resolver: kolejność i fail-closed

```bash
# lib/config.sh — jedyny kanał dostępu (CFG-001 staje się pewnik: zakaz jq/getenv poza tym plikiem)
config_resolve() {  # context_json → snapshot_id
  # 1. wczytaj registry (L0) + org floors (L1)
  # 2. klasyfikacja kontekstu Z DIFFU (nie z deklaracji): task_type, files, tier
  # 3. dopasuj context rules (L5) → profil + tighten/relax + kompensacje
  # 4. nałóż L2→L3→L4→L5 z egzekwowaniem floorów: relax bez waivera = REJECTED (zapisane w trace)
  # 5. nałóż aktywne waivers (SELECT ... WHERE expires_at > now) — wygasły = nie istnieje
  # 6. walidacja finalna: schema + inwarianty + kompletność kompensacji
  # 7. zmaterializuj → hash → INSERT snapshot → zwróć id
  # KAŻDY błąd = exit 2 (fail-closed, zero fallbacków)
}
config_get() { # key → wartość z przypiętego snapshotu; klucz nieznany = FATAL (nie default!)
}
```

## Konstytucja — czego NIE wolno konfigurować

Paradoks najlepszego configu: **jego siłą jest lista rzeczy niekonfigurowalnych**. Inaczej zmiana configu może wyłączyć siatkę bezpieczeństwa (np. `gates.self-001.enabled: false` → ghost moduły wracają).

| Niekonfigurowalne | Dlaczego |
|---|---|
| evidence→baza (meta-gate) | bez tego audyt umiera |
| SELF-001 / fail-closed | bez tego FALSE GATE wraca |
| wygasanie waiverów | bez tego wyjątki są wieczne |
| mechanizm floorów | bez tego L1 jest dekoracją |
| walidacja configu przy loadzie | bez tego zły config = cichy fallback |
| jednokanałowość `config_get` | bez tego CFG-001 jest zgadywaniem |

Zmiana tych rzeczy = zmiana kodu + ADR + pełny proces. Root bootstrap (ścieżka do DB, ścieżka registry) to **jedyne stałe wpisy w `config_exemptions`** — bez daty wygaśnięcia, explicite.

## Migracja z obecnego stanu

| Krok | Co | Zależność |
|---|---|---|
| 1 | `config/registry.yaml` + `config_get` + zakaz bezpośredniego `getenv` | fundament, ~1 dzień |
| 2 | Migracja 0006 (snapshoty) + `snapshot_id` w evidence | resolver v1 (tylko L0+L3) |
| 3 | `profiles.sh` → `config/profiles/*.yaml` (generowane, nie utrzymywane ręcznie) | S0 metadata-driven |
| 4 | Floors (L1) + walidacja tighten/relax w resolverze | po 2 |
| 5 | Context rules + klasyfikacja z diffu + kompensacje | po 4 |
| 6 | CFG-SIM w pipeline configu | po 5 |
| 7 | Ratchet + kill-switches | po 2 |

Po kroku 5 masz już pełną odpowiedź na "każde zadanie dostaje swoje gate'y". Kroki 6–7 to dopracowanie do poziomu "najlepszy na świecie".

## TL;DR — dlaczego ten design jest kompletny

```
skuteczność configu = trafność(rules z diffu) × bezpieczeństwo(floory + waivery) × audytowalność(snapshot + trace) × anty-drift(CFG-SIM + ratchet)
```

I każdy czynnik jest **sprawdzalny przez gate'y, które już zaprojektowaliśmy** — CFG-001..008 pilnują pokrycia, VV pilnuje jakości, EFF pilnuje kosztu, INTEG pilnuje spójności. Config Plane domyka pętlę: **system konfiguruje sam siebie, i sam to sprawdza**.
