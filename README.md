# ABOUT

I wanted a way to built, eval and use the store of my home server to ease my notebook a bit.
Nix store and remote builder options worked kindoff but eval on rmeote is still messy.

This sends a flake directory (git tracked ofcourse) to a tempdir on a Nixos host,
builds and evals everything there and copies back the result with nix copy.

# Usage
```bash
nix run github:FrederikRichter/nix-remote-build -- --host="{HOST}" --source="." --build-system="{BUILD_SYSTEM}" --flake="{FLAKE}"
```

## Explanation of arguments
- host: ssh host, can be alias. Examples: build-server, localhost, 192.168.1.12, root@192.168.1.2
- source: source directory of what to build, defaults to current directory ".". ~ Not supported, expand path
- build-system: 
  - (hm) Has some pre defined build commands for home-manager
  - (nixos) nixos-rebuild
  - (shell) shell.nix thats used for building
  - (generic) default, will just nix build the source dir
- flake: the normal flake option, defaults to "." Is relative to source dir

# Waring!
I hacked this together in 2 Hours, no warranty. Should be safe to use since it doesnt delete anything.
Temp dirs need to be cleaned up manually. Should check source dir for flake beforhand and copies only what is tracked by git.
