{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (
          system: f nixpkgs.legacyPackages.${system}
        );
      testDeps = ps: [
        ps.wcwidth
        ps.numpy
        ps.pandas
      ];
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          py = pkgs.python3.pkgs;
        in
        {
          default = py.buildPythonPackage {
            pname = "tabulate";
            version = "0.10.0";
            src = self;
            pyproject = true;
            build-system = [
              py.flit-core
              py.flit-scm
            ];
            # flit-scm needs git tags, which aren't available in the sandbox
            env.SETUPTOOLS_SCM_PRETEND_VERSION = "0.10.0";
            nativeCheckInputs = [ py.pytestCheckHook ] ++ testDeps py;
            pythonImportsCheck = [ "tabulate" ];
            meta.mainProgram = "tabulate";
          };
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (pkgs.python3.withPackages (ps: testDeps ps ++ [ ps.pytest ]))
            pkgs.ruff
          ];
        };
      });
    };
}
