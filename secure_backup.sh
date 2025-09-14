#!/usr/bin/env bash
set -euo pipefail

# secure_backup.sh
# Create an encrypted backup of a source directory as DMG, 7z, or both,
# excluding directories recursively (e.g., .git/.cache/.jenkins anywhere).
#
# Usage:
#   ./secure_backup.sh --dmg  EXCLUDES_FILE OUTPUT_BASE [--source DIR]
#   ./secure_backup.sh --7z   EXCLUDES_FILE OUTPUT_BASE [--source DIR]
#   ./secure_backup.sh --both EXCLUDES_FILE OUTPUT_BASE [--source DIR]
#
# Examples:
#   ./secure_backup.sh --dmg  excludes.txt ~/Desktop/home-backup --source "$HOME"
#   ./secure_backup.sh --both excludes.txt ~/Desktop/home-backup --source "$HOME"
#
# Outputs (date-stamped):
#   ~/Desktop/home-backup-YYYYMMDD.dmg
#   ~/Desktop/home-backup-YYYYMMDD.7z
#
# Requirements:
#   - macOS (hdiutil included)
#   - 7z (p7zip):   brew install p7zip
#   - expect:       brew install expect

usage() {
  cat <<'USAGE'
Usage:
  secure_backup.sh (--dmg|--7z|--both) EXCLUDES_FILE OUTPUT_BASE [--source DIR]

Args:
  --dmg|--7z|--both   Choose which artifact(s) to produce
  EXCLUDES_FILE       Text file; one directory pattern per line (e.g., .git, .cache)
  OUTPUT_BASE         Output path WITHOUT extension (script appends -YYYYMMDD and .dmg/.7z)
  --source DIR        Source directory (default: $HOME)

Notes:
  - Exclusions apply recursively (e.g., ".git" excludes any ".git" at any depth).
  - DMG uses AES-256 with -stdinpass (no password in argv).
  - 7z uses AES-256 with header encryption (-mhe=on), password fed via 'expect'.
USAGE
  exit 1
}

[[ $# -lt 3 ]] && usage

MODE="$1"          # --dmg | --7z | --both
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

# Read passphrase once (won't be echoed)
read -s -p "Enter passphrase (min 12 chars recommended): " PASSPHRASE; echo
read -s -p "Re-enter passphrase: " PASSPHRASE2; echo
[[ "$PASSPHRASE" == "$PASSPHRASE2" ]] || { echo "ERROR: Passphrases do not match." >&2; exit 1; }
unset PASSPHRASE2

# Build rsync exclude flags (for DMG staging)
build_rsync_excludes() {
  local -n _arr=$1
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    _arr+=( "--exclude=**/${pattern}/" )
  done < "$EXCLUDES_FILE"
}

# Build 7z exclude flags
build_7z_excludes() {
  local -n _arr=$1
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    _arr+=( "-xr!**/${pattern}" )
  done < "$EXCLUDES_FILE"
}

create_dmg() {
  echo ">> [DMG] Staging filtered copy with rsync…"
  local STAGE_DIR
  STAGE_DIR="$(mktemp -d "${OUTDIR}/secure-stage.XXXX")"

  local RSYNC_EXCLUDES=()
  build_rsync_excludes RSYNC_EXCLUDES

  # Progress: change --progress to --info=progress2 for cleaner, single-line updates
  rsync -aE --progress "${RSYNC_EXCLUDES[@]}" "${SOURCE}/" "${STAGE_DIR}/"

  echo ">> [DMG] Creating encrypted DMG: ${DMG_PATH}"
  (echo "${PASSPHRASE}") | hdiutil create \
    -encryption AES-256 \
    -stdinpass \
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
  command -v 7z >/dev/null 2>&1 || { echo "ERROR: 7z not installed. Install with: brew install p7zip" >&2; exit 1; }
  command -v expect >/dev/null 2>&1 || { echo "ERROR: 'expect' not installed. Install with: brew install expect" >&2; exit 1; }

  echo ">> [7z] Creating encrypted 7z (AES-256, header-encrypted): ${SEVENZ_PATH}"
  pushd "${SOURCE}" >/dev/null

  local EXCLUDE_FLAGS=()
  build_7z_excludes EXCLUDE_FLAGS
  EXCL="${EXCLUDE_FLAGS[*]}"

  export PASSPHRASE EXCL SEVENZ_PATH
  expect <<'EOF'
set timeout -1
set pass $env(PASSPHRASE)
set excl $env(EXCL)
set out  $env(SEVENZ_PATH)
# Add -bb1 for basic progress; drop it if you want quieter output
spawn sh -c "7z a -t7z -mhe=on -bb1 -p \"$out\" . $excl"
expect "Enter password" { send -- "$pass\r" }
expect "Enter password again" { send -- "$pass\r" }
expect eof
EOF

  popd >/dev/null
}

print_checksums() {
  echo ">> SHA-256 checksums (save these to verify after upload/download):"
  [[ -f "${SEVENZ_PATH}" ]] && shasum -a 256 "${SEVENZ_PATH}"
  [[ -f "${DMG_PATH}"    ]] && shasum -a 256 "${DMG_PATH}"
}

case "$MODE" in
  --dmg)  create_dmg ;;
  --7z)   create_7z ;;
  --both) create_7z; create_dmg ;;
  *) usage ;;
esac

print_checksums
echo ">> Done."
[[ -f "${SEVENZ_PATH}" ]] && echo "7z archive: ${SEVENZ_PATH}"
[[ -f "${DMG_PATH}"    ]] && echo "DMG image : ${DMG_PATH}"
echo "Mount point for DMG will be: /Volumes/${VOLNAME}"
echo "Drag-and-drop your chosen file(s) into Google Drive."