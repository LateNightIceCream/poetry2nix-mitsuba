{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, flake-utils, nixpkgs-unstable, ...}:

    flake-utils.lib.eachDefaultSystem (system: 
      let

        pkgs = import nixpkgs {
          inherit system;
        };

        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
        };

        poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { 
          inherit pkgs;
        };

        my-python = pkgs.python310;

      in
      {
        devShells.default = pkgs.mkShell {

          packages = [

            pkgs-unstable.poetry

            (poetry2nix.mkPoetryEnv { 

              projectDir = ./src;
              python = my-python;
              preferWheels = true;

              overrides = poetry2nix.overrides.withDefaults (final: prev: {

                mitsuba = prev.mitsuba.overridePythonAttrs (old: {

                  nativeBuildInputs = (old.buildInputs or [ ]) ++ [ final.drjit ];
                  buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libllvm ];

                  # this is just a temporary fix to suppress a warning
                  postFixup = pkgs.lib.strings.concatStrings [
                    (old.postFixup or "")
                    "\n"
                    "ln -s ${final.drjit}/lib/python3.10/site-packages/drjit $out/lib/python3.10/site-packages/drjit"
                  ];

                });
              });
            })
          ];

          shellHook = ''
            echo "hello :)"
          '';

        };
      }
    );
}
