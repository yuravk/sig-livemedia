#!/bin/bash

# AlmaLinux Live Media Builder Script
# Usage: ./build-livemedia.sh <version_major> <desktop_environment>
# Example: ./build-livemedia.sh 9 GNOME

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_DIR="$(pwd)/results"
LOG_FILE="${RESULT_DIR}/livemedia-build.log"

# Ensure results directory exists for logging
mkdir -p "${RESULT_DIR}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE}"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}"
}

# Help function
show_help() {
    cat << EOF
AlmaLinux Live Media Builder

Usage: $0 <version_major> <desktop_environment>

Arguments:
  version_major         AlmaLinux major version (8, 9, 10, 10-kitten)
  desktop_environment   Desktop environment (GNOME, GNOME-Mini, KDE, XFCE, MATE)

Examples:
  $0 9 GNOME              # Build AlmaLinux 9.7 GNOME Live Media
  $0 10 KDE               # Build AlmaLinux 10.1 KDE Live Media
  $0 10-kitten GNOME-Mini # Build AlmaLinux Kitten GNOME-Mini Live Media
  $0 8 MATE               # Build AlmaLinux 8.10 MATE Live Media

Supported desktop environments:
  - GNOME       Full-featured desktop environment
  - GNOME-Mini  Minimal GNOME variant
  - KDE         Modern Plasma desktop
  - XFCE        Lightweight desktop environment
  - MATE        Traditional desktop experience

Architecture support:
  - AlmaLinux 8: x86_64
  - AlmaLinux 9: x86_64, aarch64
  - AlmaLinux 10/10-kitten: x86_64, aarch64, x86_64_v2

Requirements:
  - AlmaLinux system (8, 9, or 10)
  - Root or sudo access
  - Minimum 15GB free disk space
  - Internet connection for package downloads
EOF
}

# Validate arguments
if [[ $# -ne 2 ]]; then
    show_help
    exit 1
fi

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

VERSION_MAJOR="$1"
DESKTOP_ENV="$2"

# Validate version
case "${VERSION_MAJOR}" in
    8|9|10|10-kitten)
        ;;
    *)
        error "Invalid version major: ${VERSION_MAJOR}. Supported: 8, 9, 10, 10-kitten"
        ;;
esac

# Validate desktop environment and convert to uppercase
DESKTOP_ENV=$(echo "${DESKTOP_ENV}" | tr '[:lower:]' '[:upper:]')
case "${DESKTOP_ENV}" in
    GNOME|GNOME-MINI|KDE|XFCE|MATE)
        ;;
    *)
        error "Invalid desktop environment: ${DESKTOP_ENV}. Supported: GNOME, GNOME-Mini, KDE, XFCE, MATE"
        ;;
esac

# Set version-specific variables
case "${VERSION_MAJOR}" in
    8)
        VERSION_MINOR=".10"
        RELEASEVER="${VERSION_MAJOR}${VERSION_MINOR}"
        DNF_REPO="powertools"
        NEED_PKGS="lorax lorax-templates-almalinux anaconda unzip zstd"
        LIVEMEDIA_OPTS='--anaconda-arg="--product AlmaLinux"'
        CODE_NAME=""
        ;;
    9)
        VERSION_MINOR=".7"
        RELEASEVER="${VERSION_MAJOR}${VERSION_MINOR}"
        DNF_REPO="crb"
        NEED_PKGS="lorax lorax-templates-almalinux anaconda unzip zstd libblockdev-nvme"
        LIVEMEDIA_OPTS=""
        CODE_NAME=""
        ;;
    10)
        VERSION_MINOR=".1"
        RELEASEVER="${VERSION_MAJOR}${VERSION_MINOR}"
        DNF_REPO="crb"
        NEED_PKGS="lorax lorax-templates-almalinux anaconda unzip zstd libblockdev-nvme"
        LIVEMEDIA_OPTS=""
        CODE_NAME=""
        ;;
    10-kitten)
        VERSION_MINOR=""
        RELEASEVER="10"
        DNF_REPO="crb"
        NEED_PKGS="lorax lorax-templates-almalinux anaconda unzip zstd libblockdev-nvme"
        LIVEMEDIA_OPTS=""
        CODE_NAME=" Kitten"
        DATE_STAMP=$(date -u '+%Y%m%d')
        ;;
esac

# Determine architecture
ARCH=$(uname -m)

# Validate architecture support per version
case "${VERSION_MAJOR}" in
    8)
        if [[ "${ARCH}" != "x86_64" ]]; then
            error "AlmaLinux 8 only supports x86_64 architecture. Current: ${ARCH}"
        fi
        ;;
    9)
        case "${ARCH}" in
            x86_64|aarch64)
                ;;
            *)
                error "AlmaLinux 9 supports x86_64 and aarch64 architectures. Current: ${ARCH}"
                ;;
        esac
        ;;
    10|10-kitten)
        case "${ARCH}" in
            x86_64|aarch64)
                ;;
            *)
                error "AlmaLinux ${VERSION_MAJOR} supports x86_64 and aarch64 architectures. Current: ${ARCH}"
                ;;
        esac

        # For media with x86_64_v2 packages
        if [[ "${ARCH}" == "x86_64" ]] && [[ "${USE_X86_64_V2:-}" == "1" ]]; then
            ARCH="x86_64_v2"
            log "Using x86_64_v2 optimization (set USE_X86_64_V2=1)"
        fi
        ;;
esac

# Validate desktop environment and architecture combinations
if [[ "${ARCH}" == "x86_64_v2" ]]; then
    case "${DESKTOP_ENV}" in
        GNOME|GNOME-MINI|KDE)
            ;;
        *)
            error "x86_64_v2 architecture only supports GNOME, GNOME-Mini, and KDE desktop environments. Requested: ${DESKTOP_ENV}"
            ;;
    esac
fi

# Set file names and paths
KICKSTART_FILE="almalinux-live-$(echo "${DESKTOP_ENV}" | tr '[:upper:]' '[:lower:]').ks"
KICKSTART_PATH="./kickstarts/${VERSION_MAJOR}/${ARCH}/${KICKSTART_FILE}"

# Check if we're building Kitten with date stamp
if [[ "${VERSION_MAJOR}" == "10-kitten" ]]; then
    ISO_NAME="AlmaLinux-Kitten-10-${DATE_STAMP}.0-${ARCH}-Live-${DESKTOP_ENV}.iso"
    VOLID="AlmaLinux-10-${ARCH}"
else
    ISO_NAME="AlmaLinux-${RELEASEVER}-${ARCH}-Live-${DESKTOP_ENV}.iso"
    VOLID="AlmaLinux-${RELEASEVER//./_}-${ARCH}-Live"
fi

# Handle volume ID length (ISO9660 32-char limit)
# Apply Mini suffix for GNOME-Mini, then handle length
if [[ "${DESKTOP_ENV}" == "GNOME-MINI" ]]; then
    VOLID="${VOLID}-Mini"
else
    VOLID="${VOLID}-${DESKTOP_ENV}"
fi

# Truncate if over 32 characters
if [[ ${#VOLID} -gt 32 ]]; then
    case "${DESKTOP_ENV}" in
        GNOME-MINI)
            VOLID="${VOLID:0:27}-Mini"
            ;;
        GNOME)
            VOLID="${VOLID:0:27}-GNOME"
            ;;
        *)
            VOLID="${VOLID:0:28}-${DESKTOP_ENV}"
            ;;
    esac
fi

# Create results directory structure
# Note: Don't create iso_${DESKTOP_ENV} - livemedia-creator expects to create it
mkdir -p "${RESULT_DIR}"
mkdir -p "${RESULT_DIR}/logs"

# Initialize log
echo "# AlmaLinux Live Media Build Log" > "${LOG_FILE}"
echo "# Started: $(date)" >> "${LOG_FILE}"
echo "# Version: ${RELEASEVER}${CODE_NAME}" >> "${LOG_FILE}"
echo "# Desktop: ${DESKTOP_ENV}" >> "${LOG_FILE}"
echo "# Architecture: ${ARCH}" >> "${LOG_FILE}"
echo "" >> "${LOG_FILE}"

log "Starting AlmaLinux ${RELEASEVER}${CODE_NAME} ${DESKTOP_ENV} Live Media build"
log "Architecture: ${ARCH}"
log "ISO Name: ${ISO_NAME}"
log "Volume ID: ${VOLID}"

# Check if kickstart file exists
if [[ ! -f "${KICKSTART_PATH}" ]]; then
    error "Kickstart file not found: ${KICKSTART_PATH}"
fi

log "Using kickstart: ${KICKSTART_PATH}"

# Check if result directory from previous build exists (livemedia-creator will fail if it does)
ISO_RESULT_DIR="${RESULT_DIR}/iso_${DESKTOP_ENV}"
if [[ -d "${ISO_RESULT_DIR}" ]]; then
    warning "Result directory from previous build exists: ${ISO_RESULT_DIR}"
    warning "livemedia-creator will fail if this directory exists."
    warning "Please remove it manually: rm -rf \"${ISO_RESULT_DIR}\""
    error "Cannot proceed with existing result directory"
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root or with sudo"
fi

# Prepare build environment
log "Preparing build environment..."

# Update system
log "Updating system packages..."
dnf update -y 2>&1 | tee -a "${LOG_FILE}"

# Install required packages
log "Installing required packages: ${NEED_PKGS}"
dnf install -y --enablerepo="${DNF_REPO}" ${NEED_PKGS} 2>&1 | tee -a "${LOG_FILE}"

# Set SELinux to permissive for AlmaLinux 10
if [[ "${VERSION_MAJOR}" =~ ^10 ]]; then
    log "Setting SELinux to permissive mode for AlmaLinux 10..."
    setenforce 0
    warning "SELinux has been set to permissive mode"
fi

# Create livemedia-creator command
LIVEMEDIA_CMD="livemedia-creator \
--ks=${KICKSTART_PATH} \
--no-virt \
--resultdir ${RESULT_DIR}/iso_${DESKTOP_ENV} \
--project \"Live AlmaLinux${CODE_NAME}\" \
--make-iso \
--iso-only \
--iso-name \"${ISO_NAME}\" \
--releasever \"${RELEASEVER}\" \
--volid \"${VOLID}\" \
--nomacboot \
--logfile ${RESULT_DIR}/logs/livemedia.log"

# Add optional arguments
if [[ -n "${LIVEMEDIA_OPTS}" ]]; then
    LIVEMEDIA_CMD="${LIVEMEDIA_CMD} ${LIVEMEDIA_OPTS}"
fi

log "Build command: ${LIVEMEDIA_CMD}"

# Start the build
log "Starting live media creation..."
log "This process may take 20-50 minutes depending on system performance..."

# Execute the build
if eval "${LIVEMEDIA_CMD}"; then
    success "Live media build completed successfully!"

    # Generate checksum
    log "Generating SHA256 checksum..."
    (
        cd "${RESULT_DIR}/iso_${DESKTOP_ENV}"
        sha256sum "${ISO_NAME}" > "${ISO_NAME}.CHECKSUM"
    )

    # Display results
    ISO_SIZE=$(du -h "${RESULT_DIR}/iso_${DESKTOP_ENV}/${ISO_NAME}" | cut -f1)
    success "ISO created: ${RESULT_DIR}/iso_${DESKTOP_ENV}/${ISO_NAME} (${ISO_SIZE})"
    success "Checksum: ${RESULT_DIR}/iso_${DESKTOP_ENV}/${ISO_NAME}.CHECKSUM"
    success "Logs: ${RESULT_DIR}/logs/"

    log "Build completed at: $(date)"

else
    error "Live media build failed! Check logs in ${RESULT_DIR}/logs/ for details"
fi
