#!/usr/bin/env bash
set -euo pipefail

# secure_backup.sh
# Create an encrypted backup of a source directory as DMG, 7z, or both,
# excluding directories via one excludes file (rsync semantics).
#
# Usage:
#   ./secure_backup.sh (--dmg|--7z|--both|--dry-run) EXCLUDES_FILE OUTPUT_BASE [--source DIR]
#
# Outputs (date-stamped):
#   OUTPUT_BASE-YYYYMMDD.dmg  (AES-256, volname "basename-YYYYMMDD")
#   OUTPUT_BASE-YYYYMMDD.7z   (AES-256, header-encrypted with -mhe=on)
#
# Requirements:
#   - macOS (hdiutil included)
#   - 7z (p7zip):     brew install p7zip
#   - expect:         brew install expect
#   - rsync (modern): brew install rsync
#
# NOTE: macOS ships with /usr/bin/rsync 2.6.9 (2006), which lacks modern exclude
#       behavior and has weak progress reporting. Use Homebrew rsync (3.x) so
#       excludes are honored correctly and progress displays reliably.

usage() {
  cat <<'USAGE'
Usage:
  secure_backup.sh (--dmg|--7z|--both|--dry-run) EXCLUDES_FILE OUTPUT_BASE [--source DIR]

Args:
  --dmg|--7z|--both   Choose which artifact(s) to produce
  --dry-run           Preview only: run rsync dry-run (-n -vv) with your excludes and
                      display the translated 7z exclude flags. No archives created.
  EXCLUDES_FILE       Text file (rsync-style): one pattern per line
                      - '/Name/'  => exclude top-level "Name" only (anchored)
                      - 'Name/'   => exclude any "Name" at any depth
  OUTPUT_BASE         Output path WITHOUT extension (script appends -YYYYMMDD and .dmg/.7z)
  --source DIR        Source directory (default: $HOME)
USAGE
  exit 1
}

[[ $# -lt 3 ]] && usage

MODE="$1"          # --dmg | --7z | --both | --dry-run
EXCLUDES_FILE="$2"
OUTPUT_BASE="$3"
SOURCE="${HOME}"

shift 3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

[[ -f "$EXCLUDES_FILE" ]] || { echo "ERROR: Exclusion file not found: $EXCLUDES_FILE" >&2; exit 1; }
[[ -d "$SOURCE" ]] || { echo "ERROR: Source directory not found: $SOURCE" >&2; exit 1; }

OUTDIR="$(dirname "$OUTPUT_BASE")"
BASENAME="$(basename "$OUTPUT_BASE")"
mkdir -p "$OUTDIR"

DATESTAMP="$(date +%Y%m%d)"
DMG_PATH="${OUTPUT_BASE}-${DATESTAMP}.dmg"
SEVENZ_PATH="${OUTPUT_BASE}-${DATESTAMP}.7z"
VOLNAME="${BASENAME}-${DATESTAMP}"

# ---------- helpers ----------
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }

# Build 7z exclude flags from rsync-like excludes:
# - '/Name/'  -> -xr!Name                 (top-level only, relative to SOURCE)
# - 'Name/'   -> -xr!**/Name              (any depth)
build_7z_excludes_from_file() {
  local file="$1"; local -n out_arr="$2"
  while IFS= read -r raw; do
    local line; line="$(trim "$raw")"
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    local anchored=0
    if [[ "${line:0:1}" == "/" ]]; then anchored=1; line="${line#/}"; fi
    [[ "${line: -1}" == "/" ]] && line="${line%/}"
    if (( anchored )); then out_arr+=( "-xr!${line}" ); else out_arr+=( "-xr!**/${line}" ); fi
  done < "$file"
}

create_dmg() {
  echo ">> [DMG] Staging filtered copy with rsync…"
  local STAGE_DIR; STAGE_DIR="$(mktemp -d "${OUTDIR}/secure-stage.XXXX")"
  rsync -aE --info=progress2 --human-readable \
    --exclude-from="$EXCLUDES_FILE" \
    "${SOURCE}/" "${STAGE_DIR}/"

  echo ">> [DMG] Creating encrypted DMG: ${DMG_PATH}"
  (echo "${PASSPHRASE}") | hdiutil create \
    -encryption AES-256 -stdinpass \
    -volname "${VOLNAME}" \
    -format UDZO \
    -srcfolder "${STAGE_DIR}" \
    "${DMG_PATH}" >/dev/null

  rm -rf "${STAGE_DIR}"

  echo ">> [DMG] Verifying encryption metadata:"
  hdiutil imageinfo "${DMG_PATH}" | egrep -i 'Encryption|Format' || true
  echo ">> [DMG] Volume name on mount will be: /Volumes/${VOLNAME}"
}

create_7z() {
  command -v 7z >/dev/null 2>&1 || { echo "ERROR: 7z not installed. Run: brew install p7zip" >&2; exit 1; }
  command -v expect >/dev/null 2>&1 || { echo "ERROR: 'expect' not installed. Run: brew install expect" >&2; exit 1; }

  echo ">> [7z] Creating encrypted 7z (AES-256, header-encrypted): ${SEVENZ_PATH}"
  pushd "${SOURCE}" >/dev/null

  EXCLUDE_FLAGS=(); build_7z_excludes_from_file "$EXCLUDES_FILE" EXCLUDE_FLAGS
  EXCL="${EXCLUDE_FLAGS[*]}"

  export PASSPHRASE EXCL SEVENZ_PATH
  expect <<'EOF'
set timeout -1
set pass $env(PASSPHRASE)
set excl $env(EXCL)
set out  $env(SEVENZ_PATH)
# -bb1 shows basic progress; remove for quieter output
spawn sh -c "7z a -t7z -mhe=on -bb1 -p \"$out\" . $excl"
expect "Enter password" { send -- "$pass\r" }
expect "Enter password again" { send -- "$pass\r" }
expect eof
EOF

  popd >/dev/null
}

dry_run() {
  echo ">> [Dry-Run] rsync dry-run (no files copied, full verbose listing)"
  echo "-----------------------------------------------------------------"
  # Using a temp stage path to satisfy rsync's dest parameter; it won't write due to -n
  local DRY_STAGE="/tmp/secure-backup-dryrun-stage.$$"
  rsync -aE -n -vv --exclude-from="$EXCLUDES_FILE" "${SOURCE}/" "$DRY_STAGE" || true
  rm -rf "$DRY_STAGE" 2>/dev/null || true

  echo
  echo ">> [Dry-Run] Translated 7z exclude flags (equivalent semantics):"
  EXCLUDE_FLAGS=(); build_7z_excludes_from_file "$EXCLUDES_FILE" EXCLUDE_FLAGS
  printf '  %s\n' "${EXCLUDE_FLAGS[@]}"
}

# ---------- main ----------
case "$MODE" in
  --dmg|--7z|--both)
    read -s -p "Enter passphrase (min 12 chars recommended): " PASSPHRASE; echo
    read -s -p "Re-enter passphrase: " PASSPHRASE2; echo
    [[ "$PASSPHRASE" == "$PASSPHRASE2" ]] || { echo "ERROR: Passphrases do not match." >&2; exit 1; }
    unset PASSPHRASE2
    ;;
esac

case "$MODE" in
  --dmg)     create_dmg ;;
  --7z)      create_7z ;;
  --both)    create_7z; create_dmg ;;
  --dry-run) dry_run ;;
  *) usage ;;
esac

if [[ "$MODE" != "--dry-run" ]]; then
  echo ">> SHA-256 checksums:"
  [[ -f "${SEVENZ_PATH}" ]] && shasum -a 256 "${SEVENZ_PATH}"
  [[ -f "${DMG_PATH}"    ]] && shasum -a 256 "${DMG_PATH}"
  echo ">> Done."
  [[ -f "${SEVENZ_PATH}" ]] && echo "7z archive: ${SEVENZ_PATH}"
  [[ -f "${DMG_PATH}"    ]] && echo "DMG image : ${DMG_PATH}"
  echo "Mount point for DMG will be: /Volumes/${VOLNAME}"
  echo "Drag-and-drop your chosen file(s) into Google Drive."
fi

##done