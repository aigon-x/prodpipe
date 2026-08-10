#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# debt/scanner.sh — AIGON Production Platform — Reconciliation Engine
# Moduł: HISTORICAL DEBT SCANNER (L4 HISTORY)
# Skanuje repo pod kątem długu historycznego: starych portów,
# nazw usług, nazw kontenerów, tagów obrazów, hostname, node ID,
# endpointów, ENV, sieci Docker, usług compose, crate'ów, feature
# flag, configów, docs, skilli, instrukcji agentów, API, SoT,
# schematów, migracji, backupów, symlinków, artefaktów generated.
#
# Każdy znaleziony element dostaje status:
#   CURRENT / CANONICAL / DEPRECATED / QUARANTINED / ARCHIVED /
#   ALLOWED_LEGACY / UNKNOWN / DRIFT
#   UNKNOWN i DRIFT są CZERWONE (fail).
#
# Poziomy:
#   L0 FILESYSTEM — symlinki, generated, backupi
#   L1 REPOSITORY — config, docs, schemas, migracje, crates, feature flags
#   L4 HISTORY    — legacy porty/nazwy/obrazy/hostname/node ID/endpoint
#
# Checki:
#   DEBT-001  Legacy porty (L4)
#   DEBT-002  Legacy nazwy usług (L4)
#   DEBT-003  Legacy nazwy kontenerów (L4)
#   DEBT-004  Legacy tagi obrazów (L4)
#   DEBT-005  Legacy hostname / node ID (L4)
#   DEBT-006  Legacy endpointy (L4)
#   DEBT-007  Legacy ENV (L1)
#   DEBT-008  Legacy sieci Docker / usługi compose (L1)
#   DEBT-009  Legacy crate'y / feature flagi (L1)
#   DEBT-010  Legacy configi / schemas / migracje (L1)
#   DEBT-011  Legacy docs / skille / instrukcje agentów (L1)
#   DEBT-012  Legacy API / SoT (L1)
#   DEBT-013  Backupi / symlinki / generated (L0)
#   DEBT-014  Status UNKNOWN (czerwony) — element bez klasyfikacji
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"
# shellcheck source=../core/reconcile.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/reconcile.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== HISTORICAL DEBT SCANNER (L4 HISTORY) ==="

# ── Katalogi wykluczone ze skanowania ───────────────────────
# .qwen/ = artefakty robocze agenta (worktree, nieśledzone) — nie wchodzą do repo.
# UWAGA: to musi być poprawny regex alternatyw (grep -vE), nie lista ze spacjami —
# wzorzec ze spacjami był NO-OP i nie wykluczał niczego (ukryty bug).
EXCLUDE='(\./\.git/|\./archive/|\./tools/verify/|\./\.qwen/)'

# ── Katalogi, w których legacy jest DOZWOLONE (ALLOWED_LEGACY)
# archive/ = świadomie archiwizowane; tools/verify = nowy engine.
ALLOWED_DIRS='./archive/'

# ── Katalogi, w których legacy jest QUARANTINED ─────────────
QUARANTINE_DIRS='./archive/quarantine/'

# ── Legacy porty (znane z historii AIGON-X) ─────────────────
# Format: <port>:<opis>
LEGACY_PORTS=(
  "17000:legacy aigon-runtime"
  "11408:legacy aigon-router"
  "7009:legacy maips UDP"
  "14008:stary magic-router (przeniesiony)"
  "8080:stary aigon-code-serwer"
  "58200:stary vault"
)

# ── Legacy nazwy usług / kontenerów / obrazów ───────────────
LEGACY_NAMES=(
  "aigon-nats"
  "aigon-runtime"
  "aigon-router"
  "aigon-code-serwer"
  "aigon-code-server"
  "aigon-infra-vault"
  "rtv2-runtime-master"
  "runtime-v2-magic-router"
)

# ── Legacy hostname / node ID / IP ──────────────────────────
LEGACY_HOSTS=(
  "100.98.144.70"
  "100.93.112.70"
  "contabo"
  "aigon-dev"
  "aigon-prod"
)

# ── Legacy endpointy ────────────────────────────────────────
LEGACY_ENDPOINTS=(
  "/v1/chat"
  "/api/v1"
  "/mcp"
  "/health"
  "/report"
)

# ── Legacy ENV ──────────────────────────────────────────────
LEGACY_ENV=(
  "AIGON_RUNTIME_SHARED_SECRET"
  "AIGON_API_KEY"
  "DEEPSEEK_API_KEY"
  "CLOUDFLARE_TUNNEL_TOKEN"
)

# ── Legacy sieci Docker / usługi compose ────────────────────
LEGACY_NETWORKS=(
  "aigon-nats"
  "aigon-mesh"
  "aigon-core"
)

# ── Legacy crate'y / feature flagi ──────────────────────────
LEGACY_CRATES=(
  "aigon-magic-router"
  "aigon-kernel"
  "aigon-code-mcp"
)

# ── Legacy configi / schemas / migracje ─────────────────────
LEGACY_CONFIGS=(
  "agent-models.yaml"
  "packages.yaml"
  "gateway.yaml"
  "stack.yaml"
)

# ── Legacy docs / skille / instrukcje agentów ───────────────
LEGACY_DOCS=(
  "QWEN.md"
  "AGENTS.md"
  "KANON.md"
  "MAP.md"
)

# ── Legacy API / SoT ────────────────────────────────────────
# UWAGA: SOURCE-OF-TRUTH.md, OWNERSHIP.md, VERSION to KANONICZNE pliki
# platformy (źródła prawdy), NIE legacy. Nie mogą być flagowane jako dług.
# DEBT-012 szuka więc tylko legacy API (stare ścieżki API), nie kanonicznych SoT.
LEGACY_SOT=(
  "legacy-api"
  "legacy-endpoint"
  "old-api"
)

# ── Pomocnicza: czy ścieżka jest w dozwolonym katalogu ──────
in_dir() {
  local path="$1" dir
  for dir in "$@"; do
    case "$path" in
      "$dir"*) return 0 ;;
    esac
  done
  return 1
}

# ── Pomocnicza: skanuj pliki pod kątem wzorca ───────────────
# Użycie: scan_pattern <LABEL> <CHECK_ID> <SEVERITY> <PATTERN> <DESC>
# Zwraca listę trafień (ścieżka:linia) lub puste.
scan_pattern() {
  local label="$1" check_id="$2" severity="$3" pattern="$4" desc="$5"
  local hits
  hits=$(grep -rniE "$pattern" \
    --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.json' --include='*.env' --include='*.txt' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -10)
  if [ -n "$hits" ]; then
    # Klasyfikacja: w archive/ → ARCHIVED, w quarantine/ → QUARANTINED
    local status="DRIFT"
    if in_dir "$hits" $ALLOWED_DIRS; then
      status="ARCHIVED"
    fi
    if in_dir "$hits" $QUARANTINE_DIRS; then
      status="QUARANTINED"
    fi
    recon_status "$status" "$check_id $label" "$desc: $hits"
  else
    pass "$check_id $label" "$severity" "Brak $desc."
  fi
}

# ── DEBT-001 Legacy porty (L4) ──────────────────────────────
say ""
say "--- L4 HISTORY: Legacy porty ---"
PORT_HITS=""
for entry in "${LEGACY_PORTS[@]}"; do
  port="${entry%%:*}"
  desc="${entry#*:}"
  hits=$(grep -rniE "[:/]$port([^0-9]|$)" \
    --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.json' --include='*.env' --include='*.txt' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    PORT_HITS="$PORT_HITS [$port:$desc] $hits"
  fi
done
if [ -n "$PORT_HITS" ]; then
  recon_status "DRIFT" "DEBT-001 Legacy porty" "Znaleziono legacy porty: $PORT_HITS"
  recon_record_debt "history" "Legacy porty: $PORT_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-001 Legacy porty" BLOCKING "Brak legacy portów."
fi

# ── DEBT-002 Legacy nazwy usług (L4) ────────────────────────
say ""
say "--- L4 HISTORY: Legacy nazwy usług ---"
NAME_HITS=""
for name in "${LEGACY_NAMES[@]}"; do
  hits=$(grep -rniE "\b${name}\b" \
    --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.json' --include='*.env' --include='*.txt' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    NAME_HITS="$NAME_HITS [$name] $hits"
  fi
done
if [ -n "$NAME_HITS" ]; then
  recon_status "DRIFT" "DEBT-002 Legacy nazwy usług" "Znaleziono legacy nazwy: $NAME_HITS"
  recon_record_debt "history" "Legacy nazwy usług: $NAME_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-002 Legacy nazwy usług" BLOCKING "Brak legacy nazw usług."
fi

# ── DEBT-003 Legacy nazwy kontenerów (L4) ───────────────────
say ""
say "--- L4 HISTORY: Legacy nazwy kontenerów ---"
CONTAINER_HITS=""
for name in "${LEGACY_NAMES[@]}"; do
  hits=$(grep -rniE "container_name|image:|services:|container:" \
    --include='*.yml' --include='*.yaml' --include='*.toml' --include='*.json' \
    . 2>/dev/null \
    | grep -iE "$name" \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    CONTAINER_HITS="$CONTAINER_HITS [$name] $hits"
  fi
done
if [ -n "$CONTAINER_HITS" ]; then
  recon_status "DRIFT" "DEBT-003 Legacy nazwy kontenerów" "Znaleziono legacy kontenery: $CONTAINER_HITS"
  recon_record_debt "history" "Legacy nazwy kontenerów: $CONTAINER_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-003 Legacy nazwy kontenerów" BLOCKING "Brak legacy nazw kontenerów."
fi

# ── DEBT-004 Legacy tagi obrazów (L4) ───────────────────────
say ""
say "--- L4 HISTORY: Legacy tagi obrazów ---"
IMAGE_HITS=""
for name in "${LEGACY_NAMES[@]}"; do
  hits=$(grep -rniE "image:|tag:|:fix[0-9]|:fullproxy|:latest" \
    --include='*.yml' --include='*.yaml' --include='*.toml' --include='*.json' \
    . 2>/dev/null \
    | grep -iE "$name" \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    IMAGE_HITS="$IMAGE_HITS [$name] $hits"
  fi
done
if [ -n "$IMAGE_HITS" ]; then
  recon_status "DRIFT" "DEBT-004 Legacy tagi obrazów" "Znaleziono legacy obrazy: $IMAGE_HITS"
  recon_record_debt "history" "Legacy tagi obrazów: $IMAGE_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-004 Legacy tagi obrazów" BLOCKING "Brak legacy tagów obrazów."
fi

# ── DEBT-005 Legacy hostname / node ID (L4) ─────────────────
say ""
say "--- L4 HISTORY: Legacy hostname / node ID ---"
HOST_HITS=""
for host in "${LEGACY_HOSTS[@]}"; do
  hits=$(grep -rniE "\b${host}\b" \
    --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.json' --include='*.env' --include='*.txt' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    HOST_HITS="$HOST_HITS [$host] $hits"
  fi
done
if [ -n "$HOST_HITS" ]; then
  recon_status "DRIFT" "DEBT-005 Legacy hostname / node ID" "Znaleziono legacy hosty: $HOST_HITS"
  recon_record_debt "history" "Legacy hostname / node ID: $HOST_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-005 Legacy hostname / node ID" BLOCKING "Brak legacy hostname / node ID."
fi

# ── DEBT-006 Legacy endpointy (L4) ──────────────────────────
say ""
say "--- L4 HISTORY: Legacy endpointy ---"
ENDPOINT_HITS=""
for ep in "${LEGACY_ENDPOINTS[@]}"; do
  # Endpointy wykrywamy TYLKO w kontekście URL/portu (np. http://host:8080/health,
  # localhost:8080/health), NIE jako ścieżki katalogów (np. system/health).
  # Wzorzec wymaga poprzedzenia przez :port lub host, żeby uniknąć false positives.
  hits=$(grep -rniE "(https?://[^/\"' ]*|:[0-9]{2,5})${ep}" \
    --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.json' --include='*.env' --include='*.txt' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    ENDPOINT_HITS="$ENDPOINT_HITS [$ep] $hits"
  fi
done
if [ -n "$ENDPOINT_HITS" ]; then
  recon_status "DRIFT" "DEBT-006 Legacy endpointy" "Znaleziono legacy endpointy: $ENDPOINT_HITS"
  recon_record_debt "history" "Legacy endpointy: $ENDPOINT_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-006 Legacy endpointy" BLOCKING "Brak legacy endpointów."
fi

# ── DEBT-007 Legacy ENV (L1) ────────────────────────────────
say ""
say "--- L1 REPOSITORY: Legacy ENV ---"
ENV_HITS=""
for env in "${LEGACY_ENV[@]}"; do
  hits=$(grep -rniE "\b${env}\b" \
    --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.json' --include='*.env' --include='*.txt' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    ENV_HITS="$ENV_HITS [$env] $hits"
  fi
done
if [ -n "$ENV_HITS" ]; then
  recon_status "DRIFT" "DEBT-007 Legacy ENV" "Znaleziono legacy ENV: $ENV_HITS"
  recon_record_debt "history" "Legacy ENV: $ENV_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-007 Legacy ENV" BLOCKING "Brak legacy ENV."
fi

# ── DEBT-008 Legacy sieci Docker / usługi compose (L1) ──────
say ""
say "--- L1 REPOSITORY: Legacy sieci Docker / usługi compose ---"
NETWORK_HITS=""
for net in "${LEGACY_NETWORKS[@]}"; do
  hits=$(grep -rniE "\b${net}\b" \
    --include='*.yml' --include='*.yaml' --include='*.toml' --include='*.json' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    NETWORK_HITS="$NETWORK_HITS [$net] $hits"
  fi
done
if [ -n "$NETWORK_HITS" ]; then
  recon_status "DRIFT" "DEBT-008 Legacy sieci Docker / usługi compose" "Znaleziono legacy sieci: $NETWORK_HITS"
  recon_record_debt "history" "Legacy sieci Docker / usługi compose: $NETWORK_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-008 Legacy sieci Docker / usługi compose" BLOCKING "Brak legacy sieci Docker / usług compose."
fi

# ── DEBT-009 Legacy crate'y / feature flagi (L1) ────────────
say ""
say "--- L1 REPOSITORY: Legacy crate'y / feature flagi ---"
CRATE_HITS=""
for crate in "${LEGACY_CRATES[@]}"; do
  hits=$(grep -rniE "\b${crate}\b" \
    --include='*.toml' --include='*.rs' --include='*.md' --include='*.yml' --include='*.yaml' \
    . 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | head -5)
  if [ -n "$hits" ]; then
    CRATE_HITS="$CRATE_HITS [$crate] $hits"
  fi
done
if [ -n "$CRATE_HITS" ]; then
  recon_status "DRIFT" "DEBT-009 Legacy crate'y / feature flagi" "Znaleziono legacy crate'y: $CRATE_HITS"
  recon_record_debt "history" "Legacy crate'y / feature flagi: $CRATE_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-009 Legacy crate'y / feature flagi" BLOCKING "Brak legacy crate'ów / feature flag."
fi

# ── DEBT-010 Legacy configi / schemas / migracje (L1) ───────
say ""
say "--- L1 REPOSITORY: Legacy configi / schemas / migracje ---"
CONFIG_HITS=""
for cfg in "${LEGACY_CONFIGS[@]}"; do
  hits=$(repo_files --name "/$cfg$" | grep -vE '^(tools/verify/|archive/)' | head -5)
  if [ -n "$hits" ]; then
    CONFIG_HITS="$CONFIG_HITS [$cfg] $hits"
  fi
done
if [ -n "$CONFIG_HITS" ]; then
  recon_status "DRIFT" "DEBT-010 Legacy configi / schemas / migracje" "Znaleziono legacy configi: $CONFIG_HITS"
  recon_record_debt "history" "Legacy configi / schemas / migracje: $CONFIG_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-010 Legacy configi / schemas / migracje" BLOCKING "Brak legacy configów / schematów / migracji."
fi

# ── DEBT-011 Legacy docs / skille / instrukcje agentów (L1) ─
say ""
say "--- L1 REPOSITORY: Legacy docs / skille / instrukcje agentów ---"
DOC_HITS=""
for doc in "${LEGACY_DOCS[@]}"; do
  hits=$(repo_files --name "/$doc$" | grep -vE '^(tools/verify/|archive/)' | head -5)
  if [ -n "$hits" ]; then
    DOC_HITS="$DOC_HITS [$doc] $hits"
  fi
done
if [ -n "$DOC_HITS" ]; then
  recon_status "DRIFT" "DEBT-011 Legacy docs / skille / instrukcje agentów" "Znaleziono legacy docs: $DOC_HITS"
  recon_record_debt "history" "Legacy docs / skille / instrukcje agentów: $DOC_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-011 Legacy docs / skille / instrukcje agentów" BLOCKING "Brak legacy docs / skilli / instrukcji agentów."
fi

# ── DEBT-012 Legacy API / SoT (L1) ──────────────────────────
say ""
say "--- L1 REPOSITORY: Legacy API / SoT ---"
SOT_HITS=""
for sot in "${LEGACY_SOT[@]}"; do
  # docs/00-foundation/ to kanoniczna lokalizacja dokumentów SoT (SOURCE-OF-TRUTH.md,
  # OWNERSHIP.md, VERSION) — to NIE jest legacy, to jest zamierzona struktura.
  hits=$(repo_files --name "/$sot" | grep -vE '^(tools/verify/|archive/|docs/00-foundation/)' | head -5)
  if [ -n "$hits" ]; then
    SOT_HITS="$SOT_HITS [$sot] $hits"
  fi
done
if [ -n "$SOT_HITS" ]; then
  recon_status "DRIFT" "DEBT-012 Legacy API / SoT" "Znaleziono legacy API / SoT: $SOT_HITS"
  recon_record_debt "history" "Legacy API / SoT: $SOT_HITS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-012 Legacy API / SoT" BLOCKING "Brak legacy API / SoT."
fi

# ── DEBT-013 Backupi / symlinki / generated (L0) ────────────
say ""
say "--- L0 FILESYSTEM: Backupi / symlinki / generated ---"
# Symlinki
SYMLINKS=$(find . -type l -not -path './.git/*' -not -path './.qwen/*' 2>/dev/null | head -10)
if [ -n "$SYMLINKS" ]; then
  recon_status "UNKNOWN" "DEBT-013a Symlinki" "Znaleziono symlinki (wymagają klasyfikacji): $SYMLINKS"
  recon_record_debt "history" "Symlinki (wymagają klasyfikacji): $SYMLINKS" "HIDDEN" "UNKNOWN" "" "" "debt/scanner.sh"
else
  pass "DEBT-013a Symlinki" BLOCKING "Brak symlinków."
fi

# Backupi (pliki .bak/.old/.orig/.tmp)
BACKUPS=$(find . -type f \( -name '*.bak' -o -name '*.old' -o -name '*.orig' -o -name '*.tmp' -o -name '*~' \) -not -path './.git/*' -not -path './.qwen/*' 2>/dev/null | head -10)
if [ -n "$BACKUPS" ]; then
  recon_status "DRIFT" "DEBT-013b Backupi" "Znaleziono pliki backup: $BACKUPS"
  recon_record_debt "history" "Pliki backup: $BACKUPS" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-013b Backupi" BLOCKING "Brak plików backup."
fi

# Generated (target/, node_modules/, dist/, build/, .cache/)
GENERATED=$(find . -type d \( -name 'target' -o -name 'node_modules' -o -name 'dist' -o -name 'build' -o -name '.cache' \) -not -path './.git/*' -not -path './.qwen/*' 2>/dev/null | head -10)
if [ -n "$GENERATED" ]; then
  recon_status "DRIFT" "DEBT-013c Generated" "Znaleziono katalogi generated: $GENERATED"
  recon_record_debt "history" "Katalogi generated: $GENERATED" "HIDDEN" "DRIFT" "" "" "debt/scanner.sh"
else
  pass "DEBT-013c Generated" BLOCKING "Brak katalogów generated."
fi

# ── DEBT-014 Status UNKNOWN (czerwony) ──────────────────────
# Elementy, które nie mają klasyfikacji — wymagają świadomej decyzji.
say ""
say "--- L4 HISTORY: Status UNKNOWN ---"
# Skanujemy TYLKO git-tracked pliki (repo_files), nie nieśledzone artefakty
# robocze (.qwen/). Wykluczamy katalogi, które mają własne moduły weryfikacji:
#   .git-hooks/            → git/integrity.sh (GIT-014 Hooks integrity)
#   system/control-plane/  → state/ (StateStore — schema.sql, migracje, .db)
#   tools/verify/          → sam engine
#   archive/               → świadomie archiwizowane
#   docs/00-foundation/    → kanoniczne dokumenty foundation
UNKNOWN_FILES=$(repo_files \
  | grep -vE '^(\.git-hooks/|system/control-plane/|tools/verify/|archive/|docs/00-foundation/)' \
  | grep -vE '\.(md|sh|yml|yaml|toml|json|txt|sql)$' \
  | grep -vE '(^|/)(README\.md|\.gitkeep|\.gitignore|\.gitattributes|\.gitmessage|CODEOWNERS|LICENSE|VERSION|CHANGELOG\.md)$' \
  | head -10)
if [ -n "$UNKNOWN_FILES" ]; then
  recon_status "UNKNOWN" "DEBT-014 Status UNKNOWN" "Pliki bez klasyfikacji: $UNKNOWN_FILES"
  recon_record_debt "history" "Pliki bez klasyfikacji: $UNKNOWN_FILES" "HIDDEN" "UNKNOWN" "" "" "debt/scanner.sh"
else
  pass "DEBT-014 Status UNKNOWN" BLOCKING "Wszystkie pliki mają klasyfikację."
fi

# ── Evidence: moduł zakończony ──────────────────────────────
# Meta-gate VERIFY-EVIDENCE-COMPLETE wymaga, żeby każdy moduł
# zapisał evidence do StateStore. Bez tego gate = 0 punktów.
evidence_record "verify:debt:scanner:complete" "module" "debt/scanner.sh"

verify_module_exit
