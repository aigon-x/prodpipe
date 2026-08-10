#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib/git.sh — GIT STATE
# Stan git: HEAD, branch, status, drift, uncommitted changes.
# Dostarcza funkcje pomocnicze dla modelu i generatorów.
# ─────────────────────────────────────────────────────────────
set -u

# ── HEAD commit ─────────────────────────────────────────────
git_head() {
  git rev-parse HEAD 2>/dev/null || echo "UNKNOWN"
}

# ── Branch ──────────────────────────────────────────────────
git_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "UNKNOWN"
}

# ── Liczba nieśledzonych/zmodyfikowanych plików (dirty) ─────
git_dirty_count() {
  git status --porcelain 2>/dev/null | wc -l
}

# ── Liczba niecommitowanych zmian ───────────────────────────
git_uncommitted_count() {
  git status --porcelain 2>/dev/null | grep -c '^ M\|^??' || :
}

# ── Czy repo jest czyste? ───────────────────────────────────
git_is_clean() {
  [ "$(git_dirty_count)" -eq 0 ]
}

# ── Drift: czy HEAD różni się od origin (jeśli istnieje) ────
git_drift() {
  local ahead=0 behind=0
  if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
    ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
  fi
  echo "ahead=$ahead behind=$behind"
}

# ── Ostatni commit (skrót + temat) ──────────────────────────
git_last_commit() {
  git log -1 --format='%h %s' 2>/dev/null || echo "UNKNOWN"
}
