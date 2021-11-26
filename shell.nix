# For binman tests:
# nix-shell -p gnumake gcc binutils dtc lz4 cbfstool python3 python3Packages.pyelftools python3Packages.pycryptodomex

let
  ubootDevOverlay = final: prev:
    {
      ubootRockPro64 = prev.ubootRockPro64.overrideAttrs
        (oldAttrs: {
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ prev.python3Packages.python prev.python3Packages.pyelftools ];

          shellHook = ''
            export DTC=dtc BL31=${final.armTrustedFirmwareRK3399}/bl31.elf
            export CROSS_COMPILE=aarch64-unknown-linux-gnu-
            export BINMAN_DEBUG=1 BINMAN_VERBOSE=5

            echo Run if first time:
            echo patchPhase
            configurePhase
          '';
        });
    };
in
{ pkgs ? (import <nixpkgs> {
    overlays = [ ubootDevOverlay ];
  })
}:

pkgs.pkgsCross.aarch64-multiplatform.ubootRockPro64
