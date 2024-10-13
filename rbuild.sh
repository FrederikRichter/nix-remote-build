#!/usr/bin/env bash

HOST=""
SOURCE=""
BUILD_SYSTEM=""
FLAKE=""
SKIP_TESTS=0

TEST_FAILED=0

RESULT=""

usage() {
    echo "Usage: $0 --host=<hostname> --source=<source> --build-system=<system> --flake=<flake> --skip-tests=<Optional(0|1)>"
    exit 1
}

parse_args() {
    # Parse command line arguments
    for arg in "$@"; do
        case $arg in
            --host=*)
                HOST="${arg#*=}"
                ;;
            --source=*)
                SOURCE=$(realpath "${arg#*=}")
                ;;
            --build-system=*)
                BUILD_SYSTEM="${arg#*=}"
                ;;
            --flake=*)
                FLAKE="${arg#*=}"
                ;;
            --skip-tests=*)
                SKIP_TESTS="${arg#*=}"
                ;;
            *)
                usage
                ;;
        esac
    done

    # Check if all options are provided
    if [[ -z "$HOST" || -z "$SOURCE" || -z "$BUILD_SYSTEM" || -z "$FLAKE"  || -z "$SKIP_TESTS" ]]; then
        usage
    fi
    echo $SOURCE
}


check_connection() {
    echo "> Checking SSH connection to $HOST..."

    # Check SSH connection
    ssh $HOST "exit 0"
    if [ $? -ne 0 ]; then
        echo " [!] Unable to SSH on: $HOST"
        TEST_FAILED=1
    fi

    echo "SSH Connection: OK"

    # Check for write permission by attempting to create a temporary file
    ssh "$HOST" 'touch /tmp/test_write_permission && rm /tmp/test_write_permission'
    if [ $? -ne 0 ]; then
        echo " [!] Write permission denied on: $HOST"
        TEST_FAILED=1
    fi

    echo "Write permission: OK"

    # Check for required commands
    for cmd in nixos-rebuild home-manager nix; do
        ssh $HOST "command -v $cmd >/dev/null 2>&1"
        if [ $? -ne 0 ]; then
            echo " [!] Command $cmd not found on: $HOST"
            TEST_FAILED=1
        fi
    done

    echo "Commands: OK"


    ssh "$HOST" 'grep -q "experimental-features = nix-command flakes" /etc/nix/nix.conf && echo "Flakes are enabled."'
    if [ $? -ne 0 ]; then
        echo " [!] Flakes option not found in /etc/nix/nix.conf: $HOST"
        TEST_FAILED=1
    fi

    echo "Flake support: OK"


    if [[ $TEST_FAILED -eq 1 ]]; then
        echo "[!] At least one test failed, quitting ..."
        exit
    fi
    echo "All commands are available on: $HOST"
}

setup_tmp() {
    TMPDIR=$(ssh $HOST mktemp -d)
    echo $TMPDIR
}


run_hm() {
local build_dir=$1
ssh "$HOST" <<EOF
cd "$TMPDIR"
home-manager build --impure --flake $FLAKE 2>&1
EOF
RESULT=$(ssh $HOST readlink $TMPDIR/result)
nix copy --from ssh://$HOST $RESULT
}

remote_build() {
    file_list=$(git --git-dir=$SOURCE/.git --work-tree=$SOURCE ls-files)
    rsync -v --mkpath --files-from=<(printf "%s\n" "${file_list[@]}") "$SOURCE" "$HOST:$TMPDIR/$file"

    case "$BUILD_SYSTEM" in
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
}

link_result() {
    ln -sfn $RESULT $SOURCE/result
}

parse_args "$@"

if [[ $SKIP_TESTS -eq 0 ]]; then
    check_connection
fi

setup_tmp && remote_build && link_result
