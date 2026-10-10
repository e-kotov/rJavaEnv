#!/usr/bin/env bash
# ==============================================================================
# tools/sdkman-canary.sh
# ------------------------------------------------------------------------------
# Daily canary script to detect SDKMAN upstream API schema changes and contract drift.
#
# NOTE: Identifier shape regex ^[0-9].*-[a-z]{2,}$ corresponds to the parser in
# R/resolve_sdkman.R and R/parse_version_spec.R. If updating the parser pattern,
# update this script accordingly.
# ==============================================================================

set -euo pipefail

UA="rJavaEnv-canary/1.0 (+https://github.com/e-kotov/rJavaEnv)"
PLATFORMS=("linuxx64" "darwinarm64" "windowsx64")

KNOWN_VENDORS="albba amzn bisheng gln graal graalce jbr kona librca mandrel ms nik open oracle sapmchn sem tem trava zulu"

FAILED=0

for p in "${PLATFORMS[@]}"; do
  ALL_URL="https://api.sdkman.io/2/candidates/java/${p}/versions/all"
  LIST_URL="https://api.sdkman.io/2/candidates/java/${p}/versions/list?installed="

  # ----------------------------------------------------------------------------
  # Primary endpoint: /versions/all
  # ----------------------------------------------------------------------------
  ALL_BODY=$(curl -sSL -H "User-Agent: ${UA}" "${ALL_URL}" || true)

  # A1: Non-empty body
  if [ -z "${ALL_BODY}" ]; then
    echo "FAIL A1 [${p}]: /versions/all returned empty body"
    FAILED=1
    continue
  fi

  # Split into entries
  IFS=',' read -r -a ENTRIES <<< "${ALL_BODY}"
  COUNT=${#ENTRIES[@]}

  # A2: Entry count > 20
  if [ "${COUNT}" -le 20 ]; then
    echo "FAIL A2 [${p}]: /versions/all returned only ${COUNT} entries (expected > 20)"
    FAILED=1
  else
    echo "ok   A1/A2 ${p}: ${COUNT} identifiers"
  fi

  # A3: Shape check: ^[0-9].*-[a-z]{2,}$
  INVALID_ENTRIES=0
  HAS_AMZN=0
  UNKNOWN_VENDORS=()

  for entry in "${ENTRIES[@]}"; do
    entry=$(echo "${entry}" | tr -d '[:space:]')
    [ -z "${entry}" ] && continue

    if ! [[ "${entry}" =~ ^[0-9].*-[a-z]{2,}$ ]]; then
      INVALID_ENTRIES=$((INVALID_ENTRIES + 1))
    fi

    if [[ "${entry}" =~ -amzn$ ]]; then
      HAS_AMZN=1
    fi

    # Extract vendor suffix
    vendor_code="${entry##*-}"
    if [[ ! " ${KNOWN_VENDORS} " =~ " ${vendor_code} " ]]; then
      if [[ ! " ${UNKNOWN_VENDORS[*]:-} " =~ " ${vendor_code} " ]]; then
        UNKNOWN_VENDORS+=("${vendor_code}")
      fi
    fi
  done

  if [ "${INVALID_ENTRIES}" -gt 0 ]; then
    echo "FAIL A3 [${p}]: ${INVALID_ENTRIES} entries failed regex ^[0-9].*-[a-z]{2,}$"
    FAILED=1
  else
    echo "ok   A3   ${p}: all match shape"
  fi

  # A4: Amazon Corretto (-amzn) present
  if [ "${HAS_AMZN}" -eq 0 ]; then
    echo "FAIL A4 [${p}]: no -amzn identifier found"
    FAILED=1
  else
    echo "ok   A4   ${p}: amzn present"
  fi

  # ----------------------------------------------------------------------------
  # Fallback endpoint: /versions/list (ASCII table)
  # ----------------------------------------------------------------------------
  LIST_BODY=$(curl -sSL -H "User-Agent: ${UA}" "${LIST_URL}" || true)

  FALLBACK_IDS=$(echo "${LIST_BODY}" | awk -F'|' '
    NF > 1 {
      v = "";
      for (i = 1; i <= NF; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);
        if ($i != "") v = $i;
      }
      if (v != "" && v != "Identifier" && v ~ /^[0-9].*-[a-z]{2,}$/) {
        print v;
      }
    }
  ')

  FALLBACK_COUNT=$(echo "${FALLBACK_IDS}" | grep -c . || true)

  # A5: Fallback table last non-empty pipe field yields > 20 valid identifiers
  if [ "${FALLBACK_COUNT}" -le 20 ]; then
    echo "FAIL A5 [${p}]: /versions/list fallback yielded only ${FALLBACK_COUNT} matching identifiers (expected > 20)"
    FAILED=1
  else
    echo "ok   A5   ${p}: fallback yields ${FALLBACK_COUNT}"
  fi

  # A7: Broker can serve the newest standard 21 build per core vendor, using the
  # same "+build" -> legacy alias mapping as sdkman_legacy_identifier() in
  # R/resolve_sdkman.R. FAIL on linuxx64; WARN elsewhere, where the listings
  # currently contain placeholder ids (e.g. 21.0.0.0-amzn) the broker rejects.
  for vendor in amzn tem zulu; do
    top_id=$(printf '%s\n' "${ENTRIES[@]}" | sed 's/[[:space:]]//g' |
      grep -E "^21[.].*-${vendor}$" | grep -vE 'fx|crac' | sort -V | tail -n 1 || true)
    if [ -z "${top_id}" ]; then
      echo "FAIL A7 [${p}]: no Java 21 identifier for ${vendor}"
      FAILED=1
      continue
    fi
    try_ids="${top_id}"
    if [[ "${top_id}" == *+* && "${top_id}" != *+ea* ]]; then
      try_ids="${try_ids} $(echo "${top_id}" | sed -E 's/^([^+]*)[+][^-]*-([a-z]+)$/\1-\2/; s/^([0-9]+[.][0-9]+[.][0-9]+)[.]0-/\1-/')"
    fi
    served=""
    for try_id in ${try_ids}; do
      for attempt in 1 2 3; do
        sleep "${attempt}" # the API returns 503 on request bursts
        code=$(curl -sS --max-time 30 -o /dev/null -w '%{http_code}' -H "User-Agent: ${UA}" \
          "https://api.sdkman.io/2/broker/download/java/${try_id}/${p}" || true)
        [ "${code}" = "503" ] || [ "${code}" = "429" ] || break
      done
      if [ "${code}" = "302" ] || [ "${code}" = "200" ]; then
        served="${try_id}"
        break
      fi
    done
    if [ -n "${served}" ]; then
      echo "ok   A7   ${p}: broker serves ${served} (listed as ${top_id})"
    elif [ "${p}" = "linuxx64" ]; then
      echo "FAIL A7 [${p}]: broker serves none of: ${try_ids} (last HTTP ${code})"
      FAILED=1
    else
      echo "WARN A7 [${p}]: broker serves none of: ${try_ids} (last HTTP ${code})"
    fi
  done

  # A6: Vendor check (WARN only)
  if [ "${#UNKNOWN_VENDORS[@]}" -gt 0 ]; then
    echo "WARN A6 [${p}]: unknown vendor codes found: ${UNKNOWN_VENDORS[*]} (add to vendor_reverse_map)"
  else
    echo "ok   A6   ${p}: no unknown vendors"
  fi

done

if [ "${FAILED}" -ne 0 ]; then
  echo "SDKMAN API canary failed!"
  exit 1
fi

echo "All SDKMAN canary checks passed successfully."
exit 0
