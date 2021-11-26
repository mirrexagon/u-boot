# For binman tests:
# nix-shell -p gnumake gcc binutils dtc lz4 cbfstool python3 python3Packages.pyelftools python3Packages.pycryptodomex


let
  ubootDevOverlay = final: prev:
    {
      ubootRockPro64 = prev.ubootRockPro64.overrideAttrs
        (oldAttrs: {
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with final;
            [
              # To run `./tools/binman/binman test -T`
              (buildPackages.python3.withPackages (p: [
                p.coverage
                p.pyelftools
                p.cryptodome
              ]))

              lz4
            ]);

          shellHook = ''
            export DTC=dtc BL31=${final.armTrustedFirmwareRK3399}/bl31.elf
            #export CROSS_COMPILE=aarch64-unknown-linux-gnu-
            export BINMAN_DEBUG=1 BINMAN_VERBOSE=5

            patchShebangs tools
            patchShebangs arch/arm/mach-rockchip

            substituteInPlace tools/patman/test_util.py \
              --replace python3-coverage "coverage3"
          '';
        });
    };
in
{ pkgs ? (import <nixpkgs> {
    overlays = [ ubootDevOverlay ];
  })
}:

pkgs.pkgsCross.aarch64-multiplatform.ubootRockPro64
