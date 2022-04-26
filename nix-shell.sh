#!/usr/bin/env bash

ATF_RK3328=$(nix-build '<nixpkgs>' -A pkgsCross.aarch64-multiplatform.armTrustedFirmwareRK3328 --no-out-link)

export DTC=dtc CROSS_COMPILE=aarch64-unknown-linux-gnu- BL31=$ATF_RK3328
export BINMAN_DEBUG=1 BINMAN_VERBOSE=5

echo Now you can run:
echo "  patchPhase"
echo "  make rock64-rk3328_defconfig"
echo "  make"

nix-shell '<nixpkgs>' -A pkgsCross.aarch64-multiplatform.ubootRock64
