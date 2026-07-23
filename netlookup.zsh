# ============================================================================
#  netlookup — a whois wrapper for network engineers (ASN/IP/prefix/RPKI/IRR/
#  PeeringDB/as-set). Overrides `whois` with subcommands; falls back to the
#  system whois for RIR/RPSL and domain queries.
#
#  Language: auto (English default, Turkish if locale is tr, or set _WH_LANG).
#  Docs/examples use RFC 5398 (AS64496) and RFC 5737 (192.0.2.0/24) ranges.
# ============================================================================

typeset -gA _WH
_WH=(
  red $'\033[0;31m' grn $'\033[0;32m' ylw $'\033[0;33m'
  cyn $'\033[0;36m' wht $'\033[1;37m' bld $'\033[1m'
  dim $'\033[2m'    rst $'\033[0m'
)

# ── language ────────────────────────────────────────────────────────────────
if [[ -z "${_WH_LANG:-}" ]]; then
  case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
    (tr*|TR*) _WH_LANG=tr ;;
    (*)       _WH_LANG=en ;;
  esac
fi
[[ "$_WH_LANG" == tr* ]] && _WH_LANG=tr || _WH_LANG=en

# ── message table (colors baked in; %s = runtime arg) ────────────────────────
typeset -gA _WHM
_WHM=(
  en:dep_missing     "missing dependency: ${_WH[ylw]}%s${_WH[rst]}  →  brew install %s"
  tr:dep_missing     "eksik bağımlılık: ${_WH[ylw]}%s${_WH[rst]}  →  brew install %s"
  en:no_response     "${_WH[dim]}%s: no response${_WH[rst]}"
  tr:no_response     "${_WH[dim]}%s: yanıt yok${_WH[rst]}"
  en:not_asn         "${_WH[red]}✗ '%s' is not an ASN.${_WH[rst]}"
  tr:not_asn         "${_WH[red]}✗ '%s' bir ASN değil.${_WH[rst]}"
  en:not_prefix      "${_WH[red]}✗ '%s' is not a prefix.${_WH[rst]}"
  tr:not_prefix      "${_WH[red]}✗ '%s' bir prefix değil.${_WH[rst]}"
  en:not_set         "${_WH[red]}✗ '%s' is not an as-set or ASN.${_WH[rst]}"
  tr:not_set         "${_WH[red]}✗ '%s' bir as-set ya da ASN değil.${_WH[rst]}"
  en:use_asn         "  ${_WH[dim]}usage:${_WH[rst]} ${_WH[cyn]}whois %s <asn>${_WH[rst]}   ${_WH[dim]}e.g.${_WH[rst]} ${_WH[cyn]}whois %s 64496${_WH[rst]} ${_WH[dim]}/${_WH[rst]} ${_WH[cyn]}whois %s AS64496${_WH[rst]}"
  tr:use_asn         "  ${_WH[dim]}kullanım:${_WH[rst]} ${_WH[cyn]}whois %s <asn>${_WH[rst]}   ${_WH[dim]}örn:${_WH[rst]} ${_WH[cyn]}whois %s 64496${_WH[rst]} ${_WH[dim]}/${_WH[rst]} ${_WH[cyn]}whois %s AS64496${_WH[rst]}"
  en:use_prefix      "  ${_WH[dim]}usage:${_WH[rst]} ${_WH[cyn]}whois %s <prefix> [asn]${_WH[rst]}   ${_WH[dim]}e.g.${_WH[rst]} ${_WH[cyn]}whois %s 192.0.2.0/24${_WH[rst]}"
  tr:use_prefix      "  ${_WH[dim]}kullanım:${_WH[rst]} ${_WH[cyn]}whois %s <prefix> [asn]${_WH[rst]}   ${_WH[dim]}örn:${_WH[rst]} ${_WH[cyn]}whois %s 192.0.2.0/24${_WH[rst]}"
  en:use_set         "  ${_WH[dim]}usage:${_WH[rst]} ${_WH[cyn]}whois %s <as-set|asn>${_WH[rst]}   ${_WH[dim]}e.g.${_WH[rst]} ${_WH[cyn]}whois %s AS-EXAMPLE${_WH[rst]} ${_WH[dim]}/${_WH[rst]} ${_WH[cyn]}whois %s 64496${_WH[rst]}"
  tr:use_set         "  ${_WH[dim]}kullanım:${_WH[rst]} ${_WH[cyn]}whois %s <as-set|asn>${_WH[rst]}   ${_WH[dim]}örn:${_WH[rst]} ${_WH[cyn]}whois %s AS-EXAMPLE${_WH[rst]} ${_WH[dim]}/${_WH[rst]} ${_WH[cyn]}whois %s 64496${_WH[rst]}"
  en:rpki_bad_asn    "${_WH[red]}✗ '%s' is not an ASN.${_WH[rst]}  ${_WH[dim]}e.g.${_WH[rst]} ${_WH[cyn]}whois -r 192.0.2.0/24 64496${_WH[rst]}"
  tr:rpki_bad_asn    "${_WH[red]}✗ '%s' bir ASN değil.${_WH[rst]}  ${_WH[dim]}örn:${_WH[rst]} ${_WH[cyn]}whois -r 192.0.2.0/24 64496${_WH[rst]}"
  en:origin_nf       "origin AS not found; pass it explicitly: ${_WH[cyn]}whois -r %s <asn>${_WH[rst]}"
  tr:origin_nf       "origin AS bulunamadı; elle ver: ${_WH[cyn]}whois -r %s <asn>${_WH[rst]}"
  en:ripestat_fail   "RIPEstat unreachable (timeout/error)."
  tr:ripestat_fail   "RIPEstat'a ulaşılamadı (timeout/hata)."
  en:pdb_fail        "PeeringDB unreachable (timeout/error)."
  tr:pdb_fail        "PeeringDB'ye ulaşılamadı (timeout/hata)."
  en:pdb_none        "no PeeringDB record (AS%s)."
  tr:pdb_none        "PeeringDB'de kayıt yok (AS%s)."
  en:pfx_hdr         "${_WH[wht]}IRR/RADB registered prefixes · AS%s${_WH[rst]}"
  tr:pfx_hdr         "${_WH[wht]}IRR/RADB kayıtlı prefix'ler · AS%s${_WH[rst]}"
  en:no_records      "no records."
  tr:no_records      "kayıt yok."
  en:total_pfx       "${_WH[dim]}total: %s prefixes${_WH[rst]}"
  tr:total_pfx       "${_WH[dim]}toplam: %s prefix${_WH[rst]}"
  en:neigh_none      "no neighbours found (AS%s)."
  tr:neigh_none      "komşu bulunamadı (AS%s)."
  en:neigh_hdr       "${_WH[wht]}neighbours · AS%s${_WH[rst]}"
  tr:neigh_hdr       "${_WH[wht]}komşular · AS%s${_WH[rst]}"
  en:up              "↑ Upstream"
  tr:up              "↑ Upstream"
  en:down            "↓ Downstream"
  tr:down            "↓ Downstream"
  en:unc             "• Uncertain"
  tr:unc             "• Belirsiz"
  en:pdb_l1          "  ${_WH[dim]}type:${_WH[rst]} %s   ${_WH[dim]}scope:${_WH[rst]} %s   ${_WH[dim]}policy:${_WH[rst]} %s   ${_WH[dim]}ratio:${_WH[rst]} %s"
  tr:pdb_l1          "  ${_WH[dim]}tip:${_WH[rst]} %s   ${_WH[dim]}kapsam:${_WH[rst]} %s   ${_WH[dim]}policy:${_WH[rst]} %s   ${_WH[dim]}ratio:${_WH[rst]} %s"
  en:pdb_maxpfx      "  ${_WH[dim]}suggested max-prefix v4/v6:${_WH[rst]} %s / %s"
  tr:pdb_maxpfx      "  ${_WH[dim]}önerilen max-prefix v4/v6:${_WH[rst]} %s / %s"
  en:pdb_ix          "${_WH[bld]}IX connections (%s):${_WH[rst]}"
  tr:pdb_ix          "${_WH[bld]}IX bağlantıları (%s):${_WH[rst]}"
  en:mem_none        "no members found (%s) — check the as-set name."
  tr:mem_none        "üye bulunamadı (%s) — as-set adını kontrol et."
  en:mem_hdr         "${_WH[wht]}as-set members · %s${_WH[rst]}  ${_WH[dim]}(direct)${_WH[rst]}"
  tr:mem_hdr         "${_WH[wht]}as-set üyeleri · %s${_WH[rst]}  ${_WH[dim]}(doğrudan üyeler)${_WH[rst]}"
  en:mem_asn         "${_WH[bld]}member ASNs (%s)${_WH[rst]}"
  tr:mem_asn         "${_WH[bld]}üye ASN'ler (%s)${_WH[rst]}"
  en:mem_set         "${_WH[bld]}nested as-sets (%s)${_WH[rst]}"
  tr:mem_set         "${_WH[bld]}alt AS-SET'ler (%s)${_WH[rst]}"
  en:mem_empty       "empty set."
  tr:mem_empty       "boş set."
  en:exp_hdr         "${_WH[wht]}prefix list · %s${_WH[rst]}  ${_WH[dim]}(bgpq4)${_WH[rst]}"
  tr:exp_hdr         "${_WH[wht]}prefix listesi · %s${_WH[rst]}  ${_WH[dim]}(bgpq4)${_WH[rst]}"
  en:exp_none        "no result (check the object name)."
  tr:exp_none        "sonuç yok (nesne adını kontrol et)."
  en:cache_cleared   "name cache cleared."
  tr:cache_cleared   "isim cache temizlendi."
)

_wh_t() {  # _wh_t <key> [printf-args...]
  local key="$1"; shift
  local fmt="${_WHM[${_WH_LANG}:$key]:-${_WHM[en:$key]:-$key}}"
  printf -- "$fmt" "$@"
}

# ── config ───────────────────────────────────────────────────────────────────
typeset -g _WH_CACHE="${HOME}/.cache/netlookup/asn-names.tsv"
typeset -g _WH_TIMEOUT=8
typeset -g _WH_CACHE_TTL=$(( 24 * 3600 ))   # ASN name cache lifetime (s); 1 day

# ── helpers ──────────────────────────────────────────────────────────────────
_wh_need() {
  local m ok=1
  for m in "$@"; do
    command -v "$m" >/dev/null 2>&1 || { print -- "$(_wh_t dep_missing "$m" "$m")"; ok=0; }
  done
  (( ok ))
}

_wh_get() {  # curl wrapper: timeout + HTTP 200 check; empty on failure
  command -v curl >/dev/null 2>&1 || return 1
  local body code
  body=$(curl -s -m "$_WH_TIMEOUT" -A "netlookup/1.0" -w $'\n%{http_code}' "$1" 2>/dev/null) || return 1
  code="${body##*$'\n'}"; body="${body%$'\n'*}"
  [[ "$code" == 200 && -n "$body" ]] || return 1
  print -r -- "$body"
}

_wh_classify() {
  local q="$1"
  if   [[ "$q" =~ '^([Aa][Ss])?[0-9]+$' ]];                     then print asn
  elif [[ "$q" =~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$' ]]; then print prefix
  elif [[ "$q" =~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' ]];           then print ip
  elif [[ "$q" == *:*[0-9a-fA-F]* ]];                           then print ipv6
  else print other
  fi
}

# ── validators ───────────────────────────────────────────────────────────────
_wh_is_asn()    { [[ "$1" =~ '^([Aa][Ss])?[0-9]+$' ]] }
_wh_is_prefix() {
  [[ "$1" =~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$' ]] && return 0
  [[ "$1" == */* && "$1" == *:*[0-9a-fA-F]* ]] && return 0
  return 1
}
_wh_is_set()    { _wh_is_asn "$1" || [[ "$1" == *[Aa][Ss]-* || "$1" == *:* ]] }

_wh_expect() {  # <type> <flag> <value>  → prints usage on mismatch, returns 1
  local type="$1" flag="$2" val="$3" shown="${3:-∅}"
  case "$type" in
    asn)    _wh_is_asn "$val"    && return 0; print -- "$(_wh_t not_asn "$shown")";    print -- "$(_wh_t use_asn "$flag" "$flag" "$flag")"; return 1 ;;
    prefix) _wh_is_prefix "$val" && return 0; print -- "$(_wh_t not_prefix "$shown")"; print -- "$(_wh_t use_prefix "$flag" "$flag")";        return 1 ;;
    set)    _wh_is_set "$val"    && return 0; print -- "$(_wh_t not_set "$shown")";    print -- "$(_wh_t use_set "$flag" "$flag" "$flag")"; return 1 ;;
  esac
}

# ── ASN → name, TTL-cached (only unknown/stale ASNs are queried) ─────────────
_wh_names() {
  [[ $# -eq 0 ]] && return
  local -a in; in=("${@#[Aa][Ss]}")
  mkdir -p "${_WH_CACHE:h}"
  local now; now=$(date +%s)

  typeset -A nm ts
  local k v t
  if [[ -f "$_WH_CACHE" ]]; then
    while IFS=$'\t' read -r k v t; do
      [[ -n "$k" ]] || continue
      if [[ -z "${ts[$k]:-}" || "${t:-0}" -gt "${ts[$k]:-0}" ]]; then nm[$k]="$v"; ts[$k]="${t:-0}"; fi
    done < "$_WH_CACHE"
  fi

  local -a miss; local a
  for a in "${in[@]}"; do
    if [[ -z "${nm[$a]:-}" ]] || (( now - ${ts[$a]:-0} >= _WH_CACHE_TTL )); then miss+=("$a"); fi
  done

  if (( ${#miss[@]} )); then
    local newres
    newres=$(print -l -- "${miss[@]}" \
      | xargs -P 6 -I '{}' whois -h whois.cymru.com ' -v AS{}' 2>/dev/null \
      | awk -F'|' '{for(i=1;i<=NF;i++)gsub(/^ +| +$/,"",$i)} $1 ~ /^[0-9]+$/ {print $1"\t"$NF}')
    if [[ -n "$newres" ]]; then
      while IFS=$'\t' read -r k v; do [[ -n "$k" ]] && { nm[$k]="$v"; ts[$k]="$now"; }; done <<< "$newres"
    fi
    { for k in "${(k)nm}"; do printf '%s\t%s\t%s\n' "$k" "${nm[$k]}" "${ts[$k]}"; done } > "${_WH_CACHE}.tmp" 2>/dev/null \
      && mv "${_WH_CACHE}.tmp" "$_WH_CACHE"
  fi

  for a in "${in[@]}"; do printf '%s\t%s\n' "$a" "${nm[$a]:-}"; done
}

_wh_rpki_status() {  # <prefix> <asn> → status string, or non-zero
  local prefix="$1" n="${2#[Aa][Ss]}"
  command -v jq >/dev/null 2>&1 || return 1
  local json st
  json=$(_wh_get "https://stat.ripe.net/data/rpki-validation/data.json?resource=AS${n}&prefix=${prefix}") || return 1
  st=$(jq -r '.data.status // empty' <<<"$json" 2>/dev/null)
  [[ -n "$st" ]] || return 1
  print -r -- "$st"
}

# ── summaries ────────────────────────────────────────────────────────────────
_wh_asn_summary() {
  local out
  out=$(command whois -h whois.cymru.com " -v AS${1#[Aa][Ss]}" 2>/dev/null)
  [[ -z "$out" ]] && { print -- "$(_wh_t no_response "AS${1#[Aa][Ss]}")"; return; }
  print -r -- "$out" | awk -v h="${_WH[wht]}" -v r="${_WH[rst]}" 'NR==1{print h $0 r;next}{print}'
}

_wh_ip_summary() {
  local q="$1" out line origin prefix
  out=$(command whois -h whois.cymru.com " -v $q" 2>/dev/null)
  [[ -z "$out" ]] && { print -- "$(_wh_t no_response "$q")"; return; }
  print -r -- "$out" | awk -v h="${_WH[wht]}" -v r="${_WH[rst]}" 'NR==1{print h $0 r;next}{print}'
  line=$(print -r -- "$out" | awk 'NR==2')
  origin=$(awk -F'|' '{gsub(/ /,"",$1);print $1}' <<<"$line")
  prefix=$(awk -F'|' '{gsub(/ /,"",$3);print $3}' <<<"$line")
  [[ -z "$origin" || -z "$prefix" || "$prefix" == NA ]] && return
  local st; st=$(_wh_rpki_status "$prefix" "$origin") || return
  local col label
  case "$st" in
    valid*)   col="${_WH[grn]}"; label="VALID" ;;
    invalid*) col="${_WH[red]}"; label="INVALID (${st#invalid_})" ;;
    *)        col="${_WH[ylw]}"; label="UNKNOWN" ;;
  esac
  print -- "${_WH[wht]}RPKI:${_WH[rst]} ${col}${label}${_WH[rst]}  ${_WH[cyn]}(${prefix} @ AS${origin#[Aa][Ss]})${_WH[rst]}"
}

# ── subcommands ──────────────────────────────────────────────────────────────
_wh_rpki() {
  _wh_expect prefix "-r" "$1" || return 1
  local prefix="$1" asn="$2" n
  if [[ -n "$asn" ]] && ! _wh_is_asn "$asn"; then print -- "$(_wh_t rpki_bad_asn "$asn")"; return 1; fi
  _wh_need jq || return 1
  if [[ -z "$asn" ]]; then
    asn=$(command whois -h whois.cymru.com " -v ${prefix%%/*}" 2>/dev/null | awk -F'|' 'NR==2{gsub(/ /,"",$1);print $1}')
    [[ -z "$asn" ]] && { print -- "$(_wh_t origin_nf "$prefix")"; return 1; }
  fi
  n="${asn#[Aa][Ss]}"
  local json
  json=$(_wh_get "https://stat.ripe.net/data/rpki-validation/data.json?resource=AS${n}&prefix=${prefix}") \
    || { print -- "$(_wh_t ripestat_fail)"; return 1; }
  local st; st=$(jq -r '.data.status // "unknown"' <<<"$json")
  local col label
  case "$st" in
    valid*)   col="${_WH[grn]}"; label="VALID" ;;
    invalid*) col="${_WH[red]}"; label="INVALID (${st#invalid_})" ;;
    *)        col="${_WH[ylw]}"; label="UNKNOWN" ;;
  esac
  print -- "${_WH[wht]}RPKI${_WH[rst]}  ${prefix}  origin AS${n}  →  ${col}${label}${_WH[rst]}"
  jq -r '.data.validating_roas[]? | "      ROA \(.prefix)  origin AS\(.origin)  maxlen \(.max_length)  [\(.validity)]"' <<<"$json"
}

_wh_prefixes() {
  _wh_expect asn "-p" "$1" || return 1
  local n="${1#[Aa][Ss]}"
  print -- "$(_wh_t pfx_hdr "$n")"
  local out
  out=$(command whois -h whois.radb.net -- "-i origin AS${n}" 2>/dev/null | awk '/^route6?:/{print $2}' | sort -u)
  [[ -z "$out" ]] && { print -- "$(_wh_t no_records)"; return; }
  print -- "$out"
  print -- "$(_wh_t total_pfx "$(print -- "$out" | grep -c .)")"
}

_wh_neighbours() {
  _wh_expect asn "-n" "$1" || return 1
  local n="${1#[Aa][Ss]}"
  _wh_need jq || return 1
  local json
  json=$(_wh_get "https://stat.ripe.net/data/asn-neighbours/data.json?resource=AS${n}") \
    || { print -- "$(_wh_t ripestat_fail)"; return 1; }
  local -a asns
  asns=(${(f)"$(jq -r '.data.neighbours[]?.asn' <<<"$json" 2>/dev/null)"})
  (( ${#asns[@]} == 0 )) && { print -- "$(_wh_t neigh_none "$n")"; return 0; }

  local tmp; tmp=$(mktemp)
  _wh_names $asns > "$tmp" 2>/dev/null
  local w=2 a
  for a in "${asns[@]}"; do (( ${#a} > w )) && w=${#a}; done

  _wh_neigh_group() {
    local t="$1" title="$2" col="$3" rows
    rows=$(jq -r --arg t "$t" '.data.neighbours[]? | select(.type==$t) | .asn' <<<"$json" \
      | awk -v f="$tmp" -v c="$col" -v r="${_WH[rst]}" -v w="$w" '
          BEGIN{ while((getline l < f)>0){ split(l,a,"\t"); nm[a[1]]=a[2] } }
          { printf "    %sAS%-*s%s  %s\n", c, w, $1, r, nm[$1] }' | sort -t S -k2 -n)
    [[ -z "$rows" ]] && return
    print -- "${_WH[bld]}${title}${_WH[rst]} ($(print -- "$rows" | grep -c .))"
    print -- "$rows"
  }

  print -- "$(_wh_t neigh_hdr "$n")"
  _wh_neigh_group left      "$(_wh_t up)"   "${_WH[grn]}"
  _wh_neigh_group right     "$(_wh_t down)" "${_WH[cyn]}"
  _wh_neigh_group uncertain "$(_wh_t unc)"  "${_WH[ylw]}"
  unfunction _wh_neigh_group
  rm -f "$tmp"
}

_wh_peeringdb() {
  _wh_expect asn "-i" "$1" || return 1
  local n="${1#[Aa][Ss]}"
  _wh_need jq || return 1
  local net
  net=$(_wh_get "https://www.peeringdb.com/api/net?asn=${n}") || { print -- "$(_wh_t pdb_fail)"; return 1; }
  local exists; exists=$(jq -r '.data[0].asn // empty' <<<"$net" 2>/dev/null)
  [[ -z "$exists" ]] && { print -- "$(_wh_t pdb_none "$n")"; return; }

  local name policy scope typ pfx4 pfx6 ratio
  name=$(jq -r  '.data[0].name          // "-"' <<<"$net")
  policy=$(jq -r '.data[0].policy_general// "-"' <<<"$net")
  scope=$(jq -r '.data[0].info_scope     // "-"' <<<"$net")
  typ=$(jq -r   '.data[0].info_type      // "-"' <<<"$net")
  ratio=$(jq -r '.data[0].info_ratio     // "-"' <<<"$net")
  pfx4=$(jq -r  '.data[0].info_prefixes4 // "-"' <<<"$net")
  pfx6=$(jq -r  '.data[0].info_prefixes6 // "-"' <<<"$net")

  print -- "${_WH[wht]}PeeringDB · AS${n}  ${name}${_WH[rst]}"
  print -- "$(_wh_t pdb_l1 "$typ" "$scope" "$policy" "$ratio")"
  print -- "$(_wh_t pdb_maxpfx "$pfx4" "$pfx6")"

  local ix ixlist
  ix=$(_wh_get "https://www.peeringdb.com/api/netixlan?asn=${n}")
  if [[ -n "$ix" ]]; then
    ixlist=$(jq -r '.data[]? | "    \(.name)\t\((.speed/1000)|floor)G"' <<<"$ix" 2>/dev/null \
             | awk -F'\t' -v c="${_WH[cyn]}" -v r="${_WH[rst]}" '{printf "    %s%-28s%s %s\n", c, $1, r, $2}' | sort -u)
    [[ -n "$ixlist" ]] && { print -- "  $(_wh_t pdb_ix "$(print -r -- "$ixlist" | grep -c .)")"; print -r -- "$ixlist"; }
  fi
}

_wh_members() {
  _wh_expect set "-s" "$1" || return 1
  local obj="$1"
  [[ "$obj" =~ '^[0-9]+$' ]] && obj="AS$obj"
  local raw
  raw=$(command whois -h whois.radb.net "!i${obj}" 2>/dev/null | awk 'NR==2')
  [[ -z "$raw" ]] && { print -- "$(_wh_t mem_none "$obj")"; return; }

  local -a members; members=(${=raw})
  local -a asns sets m
  for m in "${members[@]}"; do
    if   [[ "$m" =~ '^[Aa][Ss][0-9]+$' ]]; then asns+=("${m#[Aa][Ss]}")
    elif [[ "$m" == *[Aa][Ss]-* || "$m" == *:* ]]; then sets+=("$m")
    fi
  done

  print -- "$(_wh_t mem_hdr "$obj")"

  if (( ${#asns[@]} )); then
    local w=2 a
    for a in "${asns[@]}"; do (( ${#a} > w )) && w=${#a}; done
    local tmp; tmp=$(mktemp)
    _wh_names $asns > "$tmp" 2>/dev/null
    print -- "$(_wh_t mem_asn "${#asns[@]}")"
    print -l -- "${asns[@]}" \
      | awk -v f="$tmp" -v c="${_WH[grn]}" -v r="${_WH[rst]}" -v w="$w" '
          BEGIN{ while((getline l < f)>0){ split(l,a,"\t"); nm[a[1]]=a[2] } }
          { printf "    %sAS%-*s%s  %s\n", c, w, $1, r, nm[$1] }' | sort -t S -k2 -n
    rm -f "$tmp"
  fi

  if (( ${#sets[@]} )); then
    print -- "$(_wh_t mem_set "${#sets[@]}")"
    print -l -- "${sets[@]}" | sort -u | awk -v c="${_WH[cyn]}" -v r="${_WH[rst]}" '{printf "    %s%s%s\n", c, $0, r}'
  fi

  (( ${#asns[@]} + ${#sets[@]} == 0 )) && print -- "$(_wh_t mem_empty)"
}

_wh_expand() {
  _wh_expect set "-x" "$1" || return 1
  local obj="$1"
  _wh_need bgpq4 || return 1
  [[ "$obj" =~ '^[0-9]+$' ]] && obj="AS$obj"
  print -- "$(_wh_t exp_hdr "$obj")"
  local out
  out=$(bgpq4 -F '%n/%l\n' "$obj" 2>/dev/null | sort -u)
  [[ -z "$out" ]] && { print -- "$(_wh_t exp_none)"; return; }
  print -- "$out"
  print -- "$(_wh_t total_pfx "$(print -- "$out" | grep -c .)")"
}

_wh_help_en() {
  local b="${_WH[wht]}" d="${_WH[dim]}" c="${_WH[cyn]}" y="${_WH[ylw]}" r="${_WH[rst]}"
  print -r -- "${b}whois${r} ${d}— network lookup${r}

${d}targets (single, or multiple with comma/space):${r}
  ${c}whois 64496${r}                       ${d}ASN summary${r}
  ${c}whois 192.0.2.0/24${r}                ${d}prefix → origin AS + RPKI${r}
  ${c}whois 192.0.2.1${r}                   ${d}IP → origin AS + RPKI${r}
  ${c}whois 64496 64497 192.0.2.0/24${r}    ${d}multiple / mixed${r}

${d}lookups (each accepts multiple targets too):${r}
  ${c}whois -r 192.0.2.0/24${r}             ${d}RPKI validation (origin auto)${r}
  ${c}whois -r 192.0.2.0/24 64496${r}       ${d}RPKI with explicit origin${r}
  ${c}whois -p 64496${r}                    ${d}IRR/RADB prefixes${r}
  ${c}whois -n 64496${r}                    ${d}upstream/downstream neighbours${r}
  ${c}whois -i 64496${r}                    ${d}PeeringDB profile + IX${r}
  ${c}whois -s AS-EXAMPLE${r}               ${d}as-set members${r}
  ${c}whois -x AS-EXAMPLE${r}               ${d}as-set → prefix list${r}
  ${c}whois -n 64496 64497${r}              ${d}bulk (comma/space)${r}

${d}passthrough & misc:${r}
  ${c}whois example.com${r}                 ${d}domain (system whois)${r}
  ${c}whois -h whois.ripe.net AS64496${r}   ${d}raw RIR/RPSL query${r}
  ${c}whois --clear-cache${r}               ${d}reset name cache (TTL 1d)${r}
  ${c}_WH_LANG=en${r}|${c}tr${r}                    ${d}language${r}

${d}requires:${r} ${y}jq, bgpq4${r}  →  brew install jq bgpq4
${d}powered by baran-aslan1 · github.com/baran-aslan1/netlookup${r}"
}

_wh_help_tr() {
  local b="${_WH[wht]}" d="${_WH[dim]}" c="${_WH[cyn]}" y="${_WH[ylw]}" r="${_WH[rst]}"
  print -r -- "${b}whois${r} ${d}— network lookup${r}

${d}hedefler (tek, ya da virgül/boşlukla çoklu):${r}
  ${c}whois 64496${r}                       ${d}ASN özeti${r}
  ${c}whois 192.0.2.0/24${r}                ${d}prefix → origin AS + RPKI${r}
  ${c}whois 192.0.2.1${r}                   ${d}IP → origin AS + RPKI${r}
  ${c}whois 64496 64497 192.0.2.0/24${r}    ${d}çoklu / karışık${r}

${d}sorgular (hepsi çoklu hedef de alır):${r}
  ${c}whois -r 192.0.2.0/24${r}             ${d}RPKI doğrulama (origin otomatik)${r}
  ${c}whois -r 192.0.2.0/24 64496${r}       ${d}RPKI, origin elle${r}
  ${c}whois -p 64496${r}                    ${d}IRR/RADB prefix'leri${r}
  ${c}whois -n 64496${r}                    ${d}upstream/downstream komşular${r}
  ${c}whois -i 64496${r}                    ${d}PeeringDB profili + IX${r}
  ${c}whois -s AS-EXAMPLE${r}               ${d}as-set üyeleri${r}
  ${c}whois -x AS-EXAMPLE${r}               ${d}as-set → prefix listesi${r}
  ${c}whois -n 64496 64497${r}              ${d}toplu (virgül/boşluk)${r}

${d}passthrough & diğer:${r}
  ${c}whois example.com${r}                 ${d}domain (yerleşik whois)${r}
  ${c}whois -h whois.ripe.net AS64496${r}   ${d}ham RIR/RPSL sorgusu${r}
  ${c}whois --clear-cache${r}               ${d}isim cache'ini sıfırla (TTL 1g)${r}
  ${c}_WH_LANG=tr${r}|${c}en${r}                    ${d}dil${r}

${d}gerekli:${r} ${y}jq, bgpq4${r}  →  brew install jq bgpq4
${d}powered by baran-aslan1 · github.com/baran-aslan1/netlookup${r}"
}

_wh_help() { [[ "$_WH_LANG" == tr ]] && _wh_help_tr || _wh_help_en; }

# ── batch: virgül/boşlukla ayrılmış hedefler için tek-argüman komutları döngüler
_wh_batch() {
  local fn="$1"; shift
  local input="${*//,/ }"
  local -a items; items=(${=input})
  local multi=0; (( ${#items[@]} > 1 )) && multi=1
  local it
  for it in "${items[@]}"; do
    [[ -z "$it" ]] && continue
    (( multi )) && print -- "${_WH[wht]}── $it ──${_WH[rst]}"
    "$fn" "$it"
    (( multi )) && print
  done
}

# ── dispatcher ───────────────────────────────────────────────────────────────
whois() {
  emulate -L zsh
  setopt local_options no_nomatch
  case "$1" in
    --help|-H)     _wh_help; return ;;
    --clear-cache) rm -f "$_WH_CACHE" && print -- "$(_wh_t cache_cleared)"; return ;;
    -h)            command whois "$@"; return ;;
    -r)            shift; _wh_rpki "$@"; return ;;
    -p)            shift; _wh_batch _wh_prefixes "$@"; return ;;
    -n)            shift; _wh_batch _wh_neighbours "$@"; return ;;
    -i)            shift; _wh_batch _wh_peeringdb "$@"; return ;;
    -s)            shift; _wh_batch _wh_members "$@"; return ;;
    -x)            shift; _wh_batch _wh_expand "$@"; return ;;
  esac
  [[ $# -eq 0 ]] && { command whois; return; }

  local input="${*//,/ }"
  local -a queries; queries=(${=input})
  local multi=0; (( ${#queries[@]} > 1 )) && multi=1
  local q kind
  for q in "${queries[@]}"; do
    [[ -z "$q" ]] && continue
    kind=$(_wh_classify "$q")
    (( multi )) && print -- "${_WH[wht]}── $q ──${_WH[rst]}"
    case "$kind" in
      asn)            _wh_asn_summary "$q" ;;
      ip|prefix|ipv6) _wh_ip_summary "$q" ;;
      other)          command whois "$q" ;;
    esac
    (( multi )) && print
  done
}
