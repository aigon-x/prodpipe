#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# display-html.sh — Visual Pipeline Display — renderer HTML
# ─────────────────────────────────────────────────────────────
# Generuje statyczny, ciemny, techniczny, gęsty widok HTML Pipeline
# Operating System (P-001..P-098). Bez backendu, bez CDN — cały CSS/JS
# inline, Mermaid zbundlowany (fallback: prosty SVG/tekst).
#
# Wyjście: artifacts/display/pipeline-display.html
#
# Zasady:
#   * set -u (jak cały projekt).
#   * FAIL-CLOSED — brak źródła (pipelines.sh) = FAIL (BLOCKING).
#   * NO FALSE GREEN — brak danych = NOT_APPLICABLE, NIGDY PASS.
#   * Komentarze po polsku, identyfikatory po angielsku.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki ─────────────────────────────────────────────────
D_DISPLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D_AUTOMATION_DIR="$(cd "$D_DISPLAY_DIR/.." && pwd)"
D_REPO_ROOT="$(cd "$D_AUTOMATION_DIR/../.." && pwd)"

# ── Wczytaj core (lib.sh + pipelines.sh) ────────────────────
. "$D_AUTOMATION_DIR/core/lib.sh"
. "$D_AUTOMATION_DIR/core/pipelines.sh"
# ── Wczytaj rdzeń renderowania (funkcje parsujące) ──────────
. "$D_DISPLAY_DIR/lib/display.sh"

# ── FAIL-CLOSED: źródło prawdy musi istnieć ─────────────────
if [ ! -f "$D_AUTOMATION_DIR/core/pipelines.sh" ]; then
  p_fail "DISPLAY-HTML-SOURCE" BLOCKING "Brak pipelines.sh (wygeneruj przez gen-pipelines.sh)"
  p_module_exit
fi

# ── Katalog wyjściowy ───────────────────────────────────────
D_OUT_DIR="$D_REPO_ROOT/artifacts/display"
D_OUT_FILE="$D_OUT_DIR/pipeline-display.html"

# ── Zbieranie danych ────────────────────────────────────────
# Budujemy tablice: rodziny, klasy, pipeline'y (id|family|class|status|script|depends).
declare -A D_FAMILY_DESC=()
declare -A D_FAMILY_COUNT=()
declare -A D_CLASS_COUNT=()
declare -A D_PIPE_STATUS=()   # id → status evidence (PASS/FAIL/NOT_APPLICABLE)
declare -A D_GATE_STATUS=()   # gate_id → status evidence

# Rodziny z pipelines.yaml (best-effort — czytamy opis z YAML).
D_FAMILY_DESC[PRODUCT]="Produkt i odkrywanie (Product & Discovery)"
D_FAMILY_DESC[DESIGN]="Projekt i architektura (Design & Architecture)"
D_FAMILY_DESC[SECURITY]="Bezpieczeństwo (Security)"
D_FAMILY_DESC[CODE]="Kod i jakość (Code & Quality)"
D_FAMILY_DESC[BUILD]="Budowa i release (Build & Release)"
D_FAMILY_DESC[DEPLOYMENT]="Wdrożenie (Deployment)"
D_FAMILY_DESC[RUNTIME]="Runtime i operacje (Runtime & Operations)"
D_FAMILY_DESC[RECOVERY]="Odzysk i governance (Recovery & Governance)"
D_FAMILY_DESC[GTM]="Go-To-Market (rynek jako przedłużenie architektury)"
D_FAMILY_DESC[AI]="Sztuczna inteligencja (AI Plane — ML/DL/LLM lifecycle)"
D_FAMILY_DESC[OFFENSIVE-SECURITY]="Offensive Security Plane (Red/Blue/Purple Team)"
D_FAMILY_DESC[HUMAN-SIMULATION]="Human Simulation Plane (test to nie skrypt, to użytkownik)"
D_FAMILY_DESC[SIMULATION]="Simulation Plane (symulacje katastrof — 'śmierć foundera' to test, nie tragedia)"

# Liczniki rodzin i klas.
local_family_count() {
  local family="$1" count=0
  local entry
  for entry in "${PIPELINES[@]}"; do
    if [ "$(d_parse_entry "$entry" family)" = "$family" ]; then
      count=$((count+1))
    fi
  done
  echo "$count"
}
local_class_count() {
  local class="$1" count=0
  local entry
  for entry in "${PIPELINES[@]}"; do
    if [ "$(d_parse_entry "$entry" class)" = "$class" ]; then
      count=$((count+1))
    fi
  done
  echo "$count"
}

# Status evidence dla pipeline'a (z StateStore, best-effort).
local_pipe_evidence() {
  local pid="$1"
  local db="${PIPE_STATE_DB:-}"
  if [ -z "$db" ]; then
    db="$D_REPO_ROOT/system/control-plane/state/data/canonical-state.db"
  fi
  if [ ! -f "$db" ] || ! command -v sqlite3 >/dev/null 2>&1; then
    echo "NOT_APPLICABLE"
    return 0
  fi
  local row
  row="$(sqlite3 "$db" "SELECT status FROM pipeline_runs WHERE pipeline_id='$pid' ORDER BY rowid DESC LIMIT 1;" 2>/dev/null)"
  if [ -z "$row" ]; then
    echo "NOT_APPLICABLE"
  else
    echo "$row"
  fi
}

# Status evidence dla gate'a (z artifacts/evidence/gates/).
local_gate_evidence() {
  local gate_id="$1"
  local file="$D_REPO_ROOT/artifacts/evidence/gates/$gate_id.evidence"
  if [ ! -f "$file" ]; then
    echo "NOT_APPLICABLE"
    return 0
  fi
  local status
  status="$(grep -E '^status=' "$file" | head -n1 | cut -d= -f2)"
  if [ -z "$status" ]; then
    echo "NOT_APPLICABLE"
  else
    echo "$status"
  fi
}

# ── Budowanie danych ────────────────────────────────────────
# Zmienne pętli (top-level, bez `local` — `local` działa tylko w funkcjach).
id=""; family=""; class=""; status=""; i=""; gid=""
for entry in "${PIPELINES[@]}"; do
  id="$(d_parse_entry "$entry" id)"
  family="$(d_parse_entry "$entry" family)"
  class="$(d_parse_entry "$entry" class)"
  status="$(d_parse_entry "$entry" status)"
  D_PIPE_STATUS["$id"]="$(local_pipe_evidence "$id")"
done

# Gate'y GATE-001..GATE-042.
for i in $(seq 1 42); do
  gid="$(printf 'GATE-%03d' "$i")"
  D_GATE_STATUS["$gid"]="$(local_gate_evidence "$gid")"
done

# ── HTML escape ─────────────────────────────────────────────
html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  printf '%s' "$s"
}

# ── Budowanie Mermaid graph (zależności) ────────────────────
# Mermaid flowchart LR. Każdy pipeline → węzeł, zależność → krawędź.
build_mermaid() {
  echo "flowchart LR"
  local entry id depends dep
  for entry in "${PIPELINES[@]}"; do
    id="$(d_parse_entry "$entry" id)"
    depends="$(d_parse_entry "$entry" depends)"
    if [ -z "$depends" ]; then
      echo "  $id[\"$id\"]"
    else
      for dep in ${depends//,/ }; do
        echo "  $dep --> $id"
      done
    fi
  done
}

# ── Budowanie tabeli pipeline'ów (HTML) ─────────────────────
build_pipeline_rows() {
  local entry id family class status script ev ev_class
  for entry in "${PIPELINES[@]}"; do
    id="$(d_parse_entry "$entry" id)"
    family="$(d_parse_entry "$entry" family)"
    class="$(d_parse_entry "$entry" class)"
    status="$(d_parse_entry "$entry" status)"
    script="$(d_parse_entry "$entry" script)"
    ev="${D_PIPE_STATUS[$id]:-NOT_APPLICABLE}"
    case "$ev" in
      PASS) ev_class="ev-pass" ;;
      FAIL) ev_class="ev-fail" ;;
      *)    ev_class="ev-na" ;;
    esac
    printf '    <tr class="pipeline-row" data-family="%s" data-class="%s" data-status="%s">\n' \
      "$(html_escape "$family")" "$(html_escape "$class")" "$(html_escape "$status")"
    printf '      <td class="mono">%s</td>\n' "$(html_escape "$id")"
    printf '      <td><span class="fam fam-%s">%s</span></td>\n' \
      "$(echo "$family" | tr 'A-Z' 'a-z' | tr '-' '_')" "$(html_escape "$family")"
    printf '      <td><span class="cls cls-%s">%s</span></td>\n' \
      "$(echo "$class" | tr 'A-Z' 'a-z')" "$(html_escape "$class")"
    printf '      <td><span class="st st-%s">%s</span></td>\n' \
      "$(echo "$status" | tr 'A-Z' 'a-z')" "$(html_escape "$status")"
    printf '      <td class="mono dim">%s</td>\n' "$(html_escape "$script")"
    printf '      <td><span class="ev %s">%s</span></td>\n' "$ev_class" "$(html_escape "$ev")"
    printf '    </tr>\n'
  done
}

# ── Budowanie tabeli gate'ów (HTML) ─────────────────────────
build_gate_rows() {
  local registry="$D_REPO_ROOT/tools/verify/gates/registry.sh"
  local i gid domain ev ev_class
  for i in $(seq 1 42); do
    gid="$(printf 'GATE-%03d' "$i")"
    domain=""
    if [ -f "$registry" ]; then
      domain="$(grep -E "'$gid' '" "$registry" | head -n1 | awk -F"'" '{print $4}')"
    fi
    ev="${D_GATE_STATUS[$gid]:-NOT_APPLICABLE}"
    case "$ev" in
      PASS) ev_class="ev-pass" ;;
      FAIL) ev_class="ev-fail" ;;
      *)    ev_class="ev-na" ;;
    esac
    printf '    <tr class="gate-row" data-domain="%s">\n' "$(html_escape "${domain:-?}")"
    printf '      <td class="mono">%s</td>\n' "$(html_escape "$gid")"
    printf '      <td class="mono dim">%s</td>\n' "$(html_escape "${domain:-?}")"
    printf '      <td><span class="ev %s">%s</span></td>\n' "$ev_class" "$(html_escape "$ev")"
    printf '    </tr>\n'
  done
}

# ── Budowanie HTML ──────────────────────────────────────────
build_html() {
  local total="${#PIPELINES[@]}"
  local mermaid
  mermaid="$(build_mermaid)"
  local pipeline_rows gate_rows
  pipeline_rows="$(build_pipeline_rows)"
  gate_rows="$(build_gate_rows)"

  cat <<HTML
<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Pipeline Operating System — Visual Display</title>
<style>
  :root {
    --bg: #0d1117;
    --bg2: #161b22;
    --bg3: #1c2128;
    --fg: #c9d1d9;
    --fg-dim: #8b949e;
    --border: #30363d;
    --accent: #58a6ff;
    --green: #3fb950;
    --red: #f85149;
    --yellow: #d29922;
    --cyan: #39c5cf;
    --magenta: #bc8cff;
    --mono: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 24px;
    background: var(--bg); color: var(--fg);
    font-family: var(--mono);
    font-size: 13px; line-height: 1.5;
  }
  h1 { font-size: 20px; color: var(--cyan); margin: 0 0 4px; }
  h2 { font-size: 15px; color: var(--accent); margin: 28px 0 8px; border-bottom: 1px solid var(--border); padding-bottom: 4px; }
  .sub { color: var(--fg-dim); margin-bottom: 16px; }
  .meta { color: var(--fg-dim); font-size: 12px; margin-bottom: 20px; }
  .meta b { color: var(--fg); }
  .controls { margin: 16px 0; display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
  .controls input, .controls select {
    background: var(--bg2); color: var(--fg); border: 1px solid var(--border);
    padding: 6px 10px; font-family: var(--mono); font-size: 12px; border-radius: 4px;
  }
  .controls input { min-width: 220px; }
  .controls label { color: var(--fg-dim); font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin: 8px 0 24px; }
  th, td { text-align: left; padding: 5px 10px; border-bottom: 1px solid var(--border); }
  th { color: var(--fg-dim); font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; }
  tr:hover td { background: var(--bg3); }
  .mono { font-family: var(--mono); }
  .dim { color: var(--fg-dim); }
  .fam { padding: 1px 6px; border-radius: 3px; font-size: 11px; }
  .fam-product { color: var(--cyan); }
  .fam-design { color: var(--accent); }
  .fam-security { color: var(--red); }
  .fam-code { color: var(--green); }
  .fam-build { color: var(--yellow); }
  .fam-deployment { color: var(--magenta); }
  .fam-runtime { color: var(--cyan); }
  .fam-recovery { color: #e6edf3; }
  .fam-gtm { color: var(--yellow); }
  .fam-ai { color: var(--magenta); }
  .fam-offensive_security { color: var(--red); }
  .fam-human_simulation { color: var(--accent); }
  .fam-simulation { color: var(--green); }
  .cls { padding: 1px 6px; border-radius: 3px; font-size: 11px; }
  .cls-fast { color: var(--green); }
  .cls-standard { color: var(--cyan); }
  .cls-deep { color: var(--yellow); }
  .cls-release { color: var(--magenta); }
  .cls-continuous { color: var(--accent); }
  .st { padding: 1px 6px; border-radius: 3px; font-size: 11px; }
  .st-implemented { color: var(--green); }
  .st-proposed { color: var(--yellow); }
  .ev { padding: 1px 6px; border-radius: 3px; font-size: 11px; font-weight: bold; }
  .ev-pass { color: var(--green); }
  .ev-fail { color: var(--red); }
  .ev-na { color: var(--yellow); }
  .mermaid { background: var(--bg2); border: 1px solid var(--border); border-radius: 6px; padding: 16px; margin: 8px 0 24px; overflow-x: auto; }
  .legend { color: var(--fg-dim); font-size: 12px; margin: 4px 0 16px; }
  .legend span { margin-right: 16px; }
  .count { color: var(--fg-dim); }
  .count b { color: var(--fg); }
  .footer { color: var(--fg-dim); font-size: 11px; margin-top: 32px; border-top: 1px solid var(--border); padding-top: 12px; }
  .hidden { display: none; }
</style>
</head>
<body>
<h1>PIPELINE OPERATING SYSTEM — VISUAL DISPLAY</h1>
<div class="sub">Metadata-driven pipeline catalog (P-001..P-098) — 8-phase Pipeline Contract</div>
<div class="meta">
  Total pipelines: <b>$total</b> &nbsp;|&nbsp;
  Source of truth: <b>config/canonical/pipelines.yaml</b> &nbsp;|&nbsp;
  Generated: <b>tools/automation/core/pipelines.sh</b> &nbsp;|&nbsp;
  NO FALSE GREEN: brak danych = <b>NOT_APPLICABLE</b>
</div>

<div class="controls">
  <input type="text" id="search" placeholder="Szukaj (ID, rodzina, klasa, skrypt)…">
  <select id="filter-family">
    <option value="">Wszystkie rodziny</option>
    <option value="PRODUCT">PRODUCT</option>
    <option value="DESIGN">DESIGN</option>
    <option value="SECURITY">SECURITY</option>
    <option value="CODE">CODE</option>
    <option value="BUILD">BUILD</option>
    <option value="DEPLOYMENT">DEPLOYMENT</option>
    <option value="RUNTIME">RUNTIME</option>
    <option value="RECOVERY">RECOVERY</option>
    <option value="GTM">GTM</option>
    <option value="AI">AI</option>
    <option value="OFFENSIVE-SECURITY">OFFENSIVE-SECURITY</option>
    <option value="HUMAN-SIMULATION">HUMAN-SIMULATION</option>
    <option value="SIMULATION">SIMULATION</option>
  </select>
  <select id="filter-class">
    <option value="">Wszystkie klasy</option>
    <option value="FAST">FAST</option>
    <option value="STANDARD">STANDARD</option>
    <option value="DEEP">DEEP</option>
    <option value="RELEASE">RELEASE</option>
    <option value="CONTINUOUS">CONTINUOUS</option>
  </select>
  <select id="filter-evidence">
    <option value="">Wszystkie evidence</option>
    <option value="PASS">PASS</option>
    <option value="FAIL">FAIL</option>
    <option value="NOT_APPLICABLE">NOT_APPLICABLE</option>
  </select>
</div>

<h2>Pipeline Contract (8 faz)</h2>
<div class="legend">
  <span>DISCOVER</span>→<span>CONTRACT</span>→<span>EXECUTE</span>→<span>TEST</span>→<span>EVIDENCE</span>→<span>VERIFY</span>→<span>REGISTER</span>→<span>REPORT</span>
</div>

<h2>Pipeline Families (13)</h2>
<div class="legend">
  <span>PRODUCT <b>$(local_family_count PRODUCT)</b></span>
  <span>DESIGN <b>$(local_family_count DESIGN)</b></span>
  <span>SECURITY <b>$(local_family_count SECURITY)</b></span>
  <span>CODE <b>$(local_family_count CODE)</b></span>
  <span>BUILD <b>$(local_family_count BUILD)</b></span>
  <span>DEPLOYMENT <b>$(local_family_count DEPLOYMENT)</b></span>
  <span>RUNTIME <b>$(local_family_count RUNTIME)</b></span>
  <span>RECOVERY <b>$(local_family_count RECOVERY)</b></span>
  <span>GTM <b>$(local_family_count GTM)</b></span>
  <span>AI <b>$(local_family_count AI)</b></span>
  <span>OFFENSIVE-SECURITY <b>$(local_family_count OFFENSIVE-SECURITY)</b></span>
  <span>HUMAN-SIMULATION <b>$(local_family_count HUMAN-SIMULATION)</b></span>
  <span>SIMULATION <b>$(local_family_count SIMULATION)</b></span>
</div>

<h2>Pipeline Stages (P-001..P-098)</h2>
<table id="pipeline-table">
  <thead>
    <tr>
      <th>ID</th><th>Family</th><th>Class</th><th>Status</th><th>Script</th><th>Evidence</th>
    </tr>
  </thead>
  <tbody>
$pipeline_rows
  </tbody>
</table>

<h2>Pipeline Dependencies (Mermaid graph)</h2>
<div class="mermaid">
$mermaid
</div>

<h2>Gate Coverage (GATE-001..GATE-042)</h2>
<table id="gate-table">
  <thead>
    <tr><th>Gate</th><th>Domain</th><th>Evidence</th></tr>
  </thead>
  <tbody>
$gate_rows
  </tbody>
</table>

<div class="footer">
  Generated by tools/automation/display/display-html.sh — static, dark, technical, dense.
  No backend, no CDN. Source of truth: config/canonical/pipelines.yaml.
</div>

<script>
// ── Filtrowanie tabeli pipeline'ów ─────────────────────────
(function () {
  var search = document.getElementById('search');
  var fFamily = document.getElementById('filter-family');
  var fClass = document.getElementById('filter-class');
  var fEv = document.getElementById('filter-evidence');
  var rows = document.querySelectorAll('#pipeline-table .pipeline-row');

  function apply() {
    var q = (search.value || '').toLowerCase();
    var fam = fFamily.value;
    var cls = fClass.value;
    var ev = fEv.value;
    rows.forEach(function (r) {
      var text = r.textContent.toLowerCase();
      var rFam = r.getAttribute('data-family');
      var rCls = r.getAttribute('data-class');
      var rEv = r.querySelector('.ev').textContent;
      var show = true;
      if (q && text.indexOf(q) === -1) show = false;
      if (fam && rFam !== fam) show = false;
      if (cls && rCls !== cls) show = false;
      if (ev && rEv !== ev) show = false;
      r.classList.toggle('hidden', !show);
    });
  }
  search.addEventListener('input', apply);
  fFamily.addEventListener('change', apply);
  fClass.addEventListener('change', apply);
  fEv.addEventListener('change', apply);
})();
</script>
</body>
</html>
HTML
}

# ── Renderowanie HTML ───────────────────────────────────────
mkdir -p "$D_OUT_DIR"
build_html > "$D_OUT_FILE"

# ── Weryfikacja: HTML niepusty ──────────────────────────────
if [ ! -s "$D_OUT_FILE" ]; then
  p_fail "DISPLAY-HTML-OUTPUT" BLOCKING "Wygenerowany HTML jest pusty: $D_OUT_FILE"
  p_module_exit
fi

p_pass "DISPLAY-HTML-OUTPUT" BLOCKING "Wygenerowano HTML: $D_OUT_FILE ($(wc -c < "$D_OUT_FILE") bajtów)"

# ── Podsumowanie (FAIL-CLOSED) ──────────────────────────────
p_module_exit
