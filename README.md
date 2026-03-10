# AlmaLinux Live Media

This git repository contains Kickstarts and other scripts needed to produce the AlmaLinux Live DVDs. You can build live media using the automated `build-livemedia.sh` script (recommended) or manually with `livemedia-creator` commands on an AlmaLinux system.

## Using Live media

Live media ISO files are available for download from the official AlmaLinux repositories:

**AlmaLinux 8:**
- x86_64: https://repo.almalinux.org/almalinux/8/live/x86_64/

**AlmaLinux 9:**
- x86_64: https://repo.almalinux.org/almalinux/9/live/x86_64/
- aarch64: https://repo.almalinux.org/almalinux/9/live/aarch64/

**AlmaLinux 10:**
- x86_64: https://repo.almalinux.org/almalinux/10/live/x86_64/
- x86_64_v2: https://repo.almalinux.org/almalinux/10/live/x86_64_v2/
- aarch64: https://repo.almalinux.org/almalinux/10/live/aarch64/

**AlmaLinux Kitten (Development):**
- x86_64: https://kitten.repo.almalinux.org/10-kitten/live/x86_64/
- x86_64_v2: https://kitten.repo.almalinux.org/10-kitten/live/x86_64_v2/
- aarch64: https://kitten.repo.almalinux.org/10-kitten/live/aarch64/

For faster downloads, use mirrors at https://mirrors.almalinux.org to find a location closer to you. Refer to the project wiki https://wiki.almalinux.org/LiveMedia.html#about-live-media for detailed installation and usage instructions.

## Build Live Media

Building AlmaLinux Live media requires an AlmaLinux system (physical or virtual). The build process takes `20-50 minutes` depending on CPU cores and internet speed. You need minimum `15GB` workspace for temporary files. Resulting ISO size ranges from `1.4GB` to `2.4GB` depending on desktop environment.


### Build Environments

This project contains number of `KickStart` files to build live media for AlmaLinux. It uses `anaconda` and `lorax` packages for the ISO file build process. The recommended approach is to use `livemedia-creator` with the `lorax` backend.

#### Prerequisites

- AlmaLinux system (physical or virtual) with minimum 15GB workspace
- Build process takes 20-50 minutes depending on CPU cores and internet speed
- Root or sudo access required

#### Install Required Packages

**For AlmaLinux 8:**
```sh
sudo dnf update -y
sudo dnf install -y --enablerepo=powertools lorax lorax-templates-almalinux anaconda unzip zstd
```

**For AlmaLinux 9:**
```sh
sudo dnf update -y
sudo dnf install -y --enablerepo=crb lorax lorax-templates-almalinux anaconda unzip zstd libblockdev-nvme
```

**For AlmaLinux 10:**
```sh
sudo dnf update -y
sudo dnf install -y --enablerepo=crb lorax lorax-templates-almalinux anaconda unzip zstd libblockdev-nvme
```

**Note:** For AlmaLinux 10, you may need to temporarily set SELinux to permissive mode:
```sh
sudo setenforce 0
```

### Quick Start with Build Script

For a simplified build process, use the included `build-livemedia.sh` script that automates environment setup and media creation:

```sh
# Make the script executable
chmod +x build-livemedia.sh

# Build AlmaLinux 9.7 GNOME Live Media
sudo ./build-livemedia.sh 9 GNOME

# Build AlmaLinux 10.1 KDE Live Media
sudo ./build-livemedia.sh 10 KDE

# Build AlmaLinux Kitten GNOME-Mini Live Media
sudo ./build-livemedia.sh 10-kitten GNOME-Mini

# To build media with x86_64_v2 packages for AlmaLinux 10+ (optional)
USE_X86_64_V2=1 sudo ./build-livemedia.sh 10 KDE

# Show all available options
./build-livemedia.sh --help
```

**Features:**
- **Automated setup**: Installs required packages and prepares build environment
- **Smart versioning**: Automatically maps major versions to current releases (8→8.10, 9→9.7, 10→10.1)
- **Architecture detection**: Supports x86_64, aarch64, and x86_64_v2 automatically
- **Comprehensive logging**: Creates detailed logs in `./results/` directory
- **Error handling**: Validates inputs and provides helpful error messages
- **Checksum generation**: Automatically creates SHA256 checksums for built ISOs

**Supported combinations:**
- **Versions**: 8, 9, 10, 10-kitten
- **Desktop Environments**: GNOME, GNOME-Mini, KDE, XFCE, MATE
- **Architecture**: Version-specific support (see table below)

The script handles all the complexity shown in the manual examples below and follows the same build process used in the CI workflows.

### Manual Build using `livemedia-creator`

For advanced users or custom builds, you can use `livemedia-creator` directly. The following examples show manual commands for building AlmaLinux Live media. The kickstart files are organized by version and architecture in the `kickstarts/` directory.

**Note:** The build script above handles all these steps automatically. Use these manual commands only if you need custom configuration.

#### AlmaLinux 8.10 Examples

**GNOME Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/8/x86_64/almalinux-live-gnome.ks \
    --no-virt \
    --resultdir ./iso_GNOME \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-8.10-x86_64-Live-GNOME.iso" \
    --releasever "8.10" \
    --volid "AlmaLinux-8_10-x86_64-Live-GNOME" \
    --nomacboot \
    --logfile ./livemedia.log \
    --anaconda-arg="--product AlmaLinux"
```

**GNOME-Mini Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/8/x86_64/almalinux-live-gnome-mini.ks \
    --no-virt \
    --resultdir ./iso_GNOME-MINI \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-8.10-x86_64-Live-GNOME-Mini.iso" \
    --releasever "8.10" \
    --volid "AlmaLinux-8_10-x86_64-Live-Mini" \
    --nomacboot \
    --logfile ./livemedia.log \
    --anaconda-arg="--product AlmaLinux"
```

**KDE Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/8/x86_64/almalinux-live-kde.ks \
    --no-virt \
    --resultdir ./iso_KDE \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-8.10-x86_64-Live-KDE.iso" \
    --releasever "8.10" \
    --volid "AlmaLinux-8_10-x86_64-Live-KDE" \
    --nomacboot \
    --logfile ./livemedia.log \
    --anaconda-arg="--product AlmaLinux"
```

#### AlmaLinux 9.7 Examples

**GNOME Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/9/x86_64/almalinux-live-gnome.ks \
    --no-virt \
    --resultdir ./iso_GNOME \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-9.7-x86_64-Live-GNOME.iso" \
    --releasever "9.7" \
    --volid "AlmaLinux-9_7-x86_64-Live-GNOME" \
    --nomacboot \
    --logfile ./livemedia.log
```

**MATE Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/9/x86_64/almalinux-live-mate.ks \
    --no-virt \
    --resultdir ./iso_MATE \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-9.7-x86_64-Live-MATE.iso" \
    --releasever "9.7" \
    --volid "AlmaLinux-9_7-x86_64-Live-MATE" \
    --nomacboot \
    --logfile ./livemedia.log
```

#### AlmaLinux 10.1 Examples

**GNOME Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/10/x86_64/almalinux-live-gnome.ks \
    --no-virt \
    --resultdir ./iso_GNOME \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-10.1-x86_64-Live-GNOME.iso" \
    --releasever "10.1" \
    --volid "AlmaLinux-10_1-x86_64" \
    --nomacboot \
    --logfile ./livemedia.log
```

**KDE Live Media:**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/10/x86_64/almalinux-live-kde.ks \
    --no-virt \
    --resultdir ./iso_KDE \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-10.1-x86_64-Live-KDE.iso" \
    --releasever "10.1" \
    --volid "AlmaLinux-10_1-x86_64" \
    --nomacboot \
    --logfile ./livemedia.log
```

#### Architecture Support

For different architectures, adjust the kickstart path and output names accordingly:

**For aarch64 (ARM64):**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/9/aarch64/almalinux-live-gnome.ks \
    --no-virt \
    --resultdir ./iso_GNOME \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-9.7-aarch64-Live-GNOME.iso" \
    --releasever "9.7" \
    --volid "AlmaLinux-9_7-aarch64-Live-GNOME" \
    --nomacboot \
    --logfile ./livemedia.log
```

**For x86_64_v2 (Optimized x86_64):**
```sh
sudo livemedia-creator \
    --ks=./kickstarts/10/x86_64_v2/almalinux-live-kde.ks \
    --no-virt \
    --resultdir ./iso_KDE \
    --project "Live AlmaLinux" \
    --make-iso \
    --iso-only \
    --iso-name "AlmaLinux-10.1-x86_64_v2-Live-KDE.iso" \
    --releasever "10.1" \
    --volid "AlmaLinux-10_1-x86_64_v2-KDE" \
    --nomacboot \
    --logfile ./livemedia.log
```

### Additional Notes

#### Build Tips
* **Recommended approach:** Use the `build-livemedia.sh` script for automated, error-free builds
* **Performance:** The build process benefits from multiple CPU cores and faster storage (SSD recommended)
* **Network:** Builds require downloading packages; a stable internet connection is essential
* **Storage:** Ensure at least 15GB free space for temporary files and output ISOs
* **Logs:** The build script automatically creates comprehensive logs; manual builds should use `--logfile` parameter

#### Available Desktop Environments
The following desktop environments are supported:
- **GNOME** - Full-featured desktop environment
- **GNOME-Mini** - Minimal GNOME variant
- **KDE** - Modern Plasma desktop
- **XFCE** - Lightweight desktop environment
- **MATE** - Traditional desktop experience

#### Architecture and Desktop Environment Support Matrix

| Version | Architecture | GNOME | GNOME-Mini | KDE | XFCE | MATE |
|---------|-------------|-------|------------|-----|------|------|
| 8       | x86_64      | ✅    | ✅         | ✅  | ✅   | ✅   |
| 9       | x86_64      | ✅    | ✅         | ✅  | ✅   | ✅   |
| 9       | aarch64     | ✅    | ✅         | ✅  | ✅   | ✅   |
| 10      | x86_64      | ✅    | ✅         | ✅  | ✅   | ✅   |
| 10      | aarch64     | ✅    | ✅         | ✅  | ✅   | ✅   |
| 10      | x86_64_v2   | ✅    | ✅         | ✅  | ❌   | ❌   |
| 10-kitten | x86_64    | ✅    | ✅         | ✅  | ✅   | ✅   |
| 10-kitten | aarch64   | ✅    | ✅         | ✅  | ✅   | ✅   |
| 10-kitten | x86_64_v2 | ✅    | ✅         | ✅  | ❌   | ❌   |

#### Troubleshooting
* For AlmaLinux 10, SELinux may need to be set to permissive: `sudo setenforce 0`
* Volume IDs are limited to 32 characters due to ISO9660 specification
* Repository mirrors: Use https://mirrors.almalinux.org to find optimal mirrors

#### CI/CD Integration
This repository includes GitHub Actions workflows that automatically build live media images. The workflows support:
- Multiple AlmaLinux versions (8, 9, 10, 10-kitten)
- Multiple architectures and desktop environments
- GitHub Actions artifact publishing
- S3 upload and Mattermost notifications
