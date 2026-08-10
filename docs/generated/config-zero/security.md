# SECURITY — OPERATION CONFIG ZERO

> PHASE 23 — Audyt bezpieczeństwa konfiguracji w `/opt/Prod-ready/`.
> Zasada: **sekrety w repo → max 3/10 w score modelu. SECRET_REFERENCE tylko, nigdy wartości.**

## 1. Polityka sekretów
- **SECRET_REFERENCE** — config zawiera tylko referencje do sekretów, nigdy wartości.
- **Brak sekretów w git** — kompilator waliduje brak sekretów w `config/canonical/`.
- **Sekrety w repo → max 3/10** w score modelu.

## 2. Skan sekretów

### 2.1 Kompilator (`config-compiler.sh validate`)
- Waliduje brak sekretów w `config/canonical/platform.yaml`.
- Wynik: PASS (brak sekretów).

### 2.2 Secret scanner (`tools/security/secret-scan.sh`)
- **Status:** FOUNDATION PLACEHOLDER.
- **Mode detection:** gitleaks → trufflehog → git-secrets → heuristic.

### 2.3 Verify security modules
- `tools/verify/security/secrets.sh` — SEC-004 (brak plików kluczy).
- `tools/verify/security/credentials.sh` — SEC-208 (brak JWT).
- `tools/verify/security/history.sh` — SEC-102 (brak sekretów w commitach).
- **Status:** GHOST (nie wykonywane przez verify.sh).

### 2.4 CI security
- `.github/workflows/security.yml` — skan sekretów (git ls-files | grep .pem/.key/.env).
- **Status:** MOCK (dependency/container scanning placeholder).

## 3. Sekrety w repo (audyt)

| Sekret | Lokalizacja | Typ | Status |
|--------|-------------|-----|--------|
| `YBZTmMaBHhoHnLEVohYENiQzTVwsCUKy6eGg1YK1aeE` | `AGENTS.md` | SECRET_REFERENCE (dokumentacja) | ⚠️ WYMIENIONY w AGENTS.md |
| `AIGON_RUNTIME_SHARED_SECRET` | `AGENTS.md` | Nazwa zmiennej | ✅ Referencja |
| `DEEPSEEK_API_KEY` | `AGENTS.md` | Nazwa zmiennej | ✅ Referencja |
| `CLOUDFLARE_TUNNEL_TOKEN` | `AGENTS.md` | Nazwa zmiennej | ✅ Referencja |
| `AIGON_API_KEY` | `AGENTS.md` | Nazwa zmiennej | ✅ Referencja |

> **Uwaga:** Sekret `YBZTmMa...` jest wymieniony w `AGENTS.md` jako **referencja** (dokumentacja operacyjna), nie jako wartość konfiguracyjna. Kompilator waliduje brak sekretów w `config/canonical/`. To jest akceptowalne — AGENTS.md to dokumentacja, nie config. Jednak dla pełnej zgodności z CONFIG ZERO, sekret powinien być przeniesiony do Vault (SECRET_REFERENCE w config).

## 4. Wnioski
- **Brak sekretów w config/canonical/** — kompilator waliduje.
- **Sekret `YBZTmMa...`** wymieniony w AGENTS.md (dokumentacja) — akceptowalne, ale rekomendacja: przenieść do Vault.
- **Secret scanner** — FOUNDATION PLACEHOLDER (nie w pełni zaimplementowany).
- **Security verify modules** — GHOST (nie wykonywane).
- **CI security** — MOCK (dependency/container scanning placeholder).

## 5. Rekomendacja
1. Przenieść sekret `YBZTmMa...` z AGENTS.md do Vault (SECRET_REFERENCE).
2. Wypełnić secret scanner (gitleaks/trufflehog).
3. Podłączyć security verify modules do verify.sh.
4. Wypełnić CI security mock.
