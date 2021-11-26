#!/usr/bin/env bash

ATF_RK3399=$(nix-build '<nixpkgs>' -A pkgsCross.aarch64-multiplatform.armTrustedFirmwareRK3399 --no-out-link)

export DTC=dtc CROSS_COMPILE=aarch64-unknown-linux-gnu- BL31=$ATF_RK3399
export BINMAN_DEBUG=1 BINMAN_VERBOSE=5

echo Now you can run:
echo "  patchPhase"
echo "  make rockpro64-rk3399_defconfig"
echo "  make"

nix-shell '<nixpkgs>' -A pkgsCross.aarch64-multiplatform.ubootRockPro64
