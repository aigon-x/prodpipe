#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# report.sh — AIGON Production Platform — Repository Certification Engine
# Raportowanie wyników: nagłówek, tabela, certyfikacja, blokada.
# ─────────────────────────────────────────────────────────────
set -u

# ── Nagłówek certyfikacji ────────────────────────────────────
verify_header() {
  local profile="$1"
  say ""
  say "╔══════════════════════════════════════════════════════════╗"
  say "║        PROD-READY LOCAL CERTIFICATION — $profile        ║"
  say "╚══════════════════════════════════════════════════════════╝"
  say ""
}

# ── Tabela wyników per moduł ─────────────────────────────────
# Użycie: verify_module_report <module> <fail> <warn> <info> <pass>
verify_module_report() {
  local module="$1" fail="$2" warn="$3" info="$4" pass="$5"
  local status="PASS"
  [ "$fail" -gt 0 ] && status="FAIL"
  [ "$warn" -gt 0 ] && [ "$status" = "PASS" ] && status="WARN"
  printf '%-24s %-6s  FAIL=%s WARN=%s INFO=%s PASS=%s\n' \
    "$module" "$status" "$fail" "$warn" "$info" "$pass"
}

# ── Blokada commita/push ─────────────────────────────────────
verify_block_message() {
  say ""
  sayc "❌ BLOCKED" "$C_RED"
  say ""
  say "Commit/push nie może zostać utworzony."
  say "Popraw powyższe problemy przed ponowną próbą."
  say ""
  say "0 commits created."
  say "0 pushes allowed."
  say ""
}

# ── Komunikat sukcesu ────────────────────────────────────────
verify_success_message() {
  say ""
  sayc "✅ CERTIFIED" "$C_GREEN"
  say ""
  say "Commit/push dozwolony."
  say ""
}
