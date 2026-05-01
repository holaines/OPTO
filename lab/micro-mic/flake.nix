{
  description = "Rust development environment for STM32H755 (Nucleo H755ZI-Q)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "llvm-tools-preview" ];
          targets = [ "thumbv7em-none-eabihf" ];
        };

        target = "thumbv7em-none-eabihf";

        micro-check = pkgs.writeShellApplication {
          name = "micro-check";
          runtimeInputs = [ rustToolchain ];
          text = ''
            cargo check --target ${target} "$@"
          '';
        };

        micro-build = pkgs.writeShellApplication {
          name = "micro-build";
          runtimeInputs = [ rustToolchain ];
          text = ''
            cargo build --target ${target} "$@"
          '';
        };

        micro-build-release = pkgs.writeShellApplication {
          name = "micro-build-release";
          runtimeInputs = [ rustToolchain ];
          text = ''
            cargo build --release --target ${target} "$@"
          '';
        };

        micro-run = pkgs.writeShellApplication {
          name = "micro-run";
          runtimeInputs = [
            rustToolchain
            pkgs.probe-rs-tools
          ];
          text = ''
            cargo run --target ${target} "$@"
          '';
        };

        micro-run-release = pkgs.writeShellApplication {
          name = "micro-run-release";
          runtimeInputs = [
            rustToolchain
            pkgs.probe-rs-tools
          ];
          text = ''
            cargo run --release --target ${target} "$@"
          '';
        };

        micro-size = pkgs.writeShellApplication {
          name = "micro-size";
          runtimeInputs = [
            rustToolchain
            pkgs.cargo-binutils
          ];
          text = ''
            cargo size --target ${target} --bin micro-read -- -A "$@"
          '';
        };

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pyqt6
          (pyqtgraph.overridePythonAttrs (old: { doCheck = false; }))
          numpy
          scipy
        ]);

        micro-net-up = pkgs.writeShellApplication {
          name = "micro-net-up";
          runtimeInputs = [ pkgs.iproute2 ];
          text = ''
            iface="''${MICRO_IFACE:-enp0s20f0u6u3u4}"
            ip link set dev "$iface" up
            ip addr replace 192.168.88.2/24 brd + dev "$iface"
            ip -brief addr show "$iface"
          '';
        };

        micro-net-status = pkgs.writeShellApplication {
          name = "micro-net-status";
          runtimeInputs = [ pkgs.iproute2 ];
          text = ''
            iface="''${MICRO_IFACE:-enp0s20f0u6u3u4}"
            ip -brief addr show "$iface"
            ip -s link show dev "$iface"
            ip -s neigh show dev "$iface"
          '';
        };

        micro-oscilloscope = pkgs.writeShellApplication {
          name = "micro-oscilloscope";
          runtimeInputs = [ pkgs.nodejs pythonEnv ];
          text = ''
            # Run middleware in background, and visualizer in foreground
            node middleware/server.js &
            MIDDLEWARE_PID=$!
            python3 visualizer/main.py "$@"
            kill $MIDDLEWARE_PID
          '';
        };

        nativeBuildInputs = with pkgs; [
          rustToolchain
          nodejs
          pythonEnv
          pkg-config
          probe-rs-tools
          iproute2
          cargo-binutils
          srecord
          usbutils
          libusb1
          libiconv
          micro-check
          micro-build
          micro-build-release
          micro-run
          micro-run-release
          micro-size
          micro-net-up
          micro-net-status
          micro-oscilloscope
        ] ++ lib.optionals stdenv.isDarwin [
          darwin.apple_sdk.frameworks.Security
          darwin.apple_sdk.frameworks.CoreFoundation
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          inherit nativeBuildInputs;

          shellHook = ''
            echo "STM32 Development Shell Loaded"
            echo "Commands:"
            echo "  micro-check          cargo check for ${target}"
            echo "  micro-build          debug build"
            echo "  micro-build-release  release build"
            echo "  micro-run            flash/run debug build with probe-rs"
            echo "  micro-run-release    flash/run release build with probe-rs"
            echo "  micro-size           show section sizes"
            echo "  micro-oscilloscope   run BOTH the middleware and the visualizer"
            echo "  micro-net-up         configure direct link (use sudo if needed)"
            echo "  micro-net-status     show direct link counters and ARP"
          '';
        };
      }
    );
}
