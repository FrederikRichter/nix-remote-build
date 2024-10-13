#!/usr/bin/env bash
host_arg=${@: -3:1}
dir_arg=${@: -2:1}
opt_arg=${@: -1}
echo $host_arg $dir_arg $opt_arg

HOST=$host_arg

run_hm() {
local build_dir=$1
ssh "$HOST" <<EOF
cd "$build_dir"
home-manager build --impure --flake .
EOF
RESULT=$(ssh $HOST readlink $TMPDIR/result)
nix copy --from ssh://$HOST $RESULT
$RESULT/activate
}

# run_nixos() {
# local build_dir=$1
# ssh "$HOST" <<EOF
# cd "$build_dir"
# home-manager build --impure --flake .
# EOF
# }




TMPDIR=$(ssh $HOST mktemp -d)
echo $TMPDIR
scp -r $dir_arg $HOST:$TMPDIR

case "$opt_arg" in
    hm)
        run_hm $TMPDIR
        ;;
    # nixos)
        #     ;;
    # shell)
        #     ;;
    # *)
        # # Default case if no patterns match
        # ;;
esac
