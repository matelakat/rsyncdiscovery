#!/bin/bash

function backup {
    local src
    local tgt
    local prev

    src="$1"
    tgt="$2"
    prev="${3:-}"

    local link_param

    if [ -z "$prev" ]; then
        rsync -r -h -H -l -g -o -t -D -p --del "$src" "$tgt"
    else
        rsync -r -h -H -l -g -o -t -D -p --del --link-dest="$prev" "$src" "$tgt"
    fi
}

function test_backup_is_recursive {
    touch src/f1
    backup src tgt
    [ -e tgt/src/f1 ]
}

function test_extra_files_removed {
    mkdir tgt/src
    touch tgt/src/f1
    backup src tgt
    [ ! -e tgt/src/f1 ]
}

function test_hardlinks_preserved {
    echo "k" >  src/f1
    link src/f1 src/f2
    backup src tgt
    [ -e tgt/src/f2 ]
    diff <( cd src; du ) <( cd tgt/src; du )
}

function test_symlinks_preserved {
    touch src/symlinktarget
    ln -s src/symlinktarget src/symlink
    [ -L src/symlink ] # Sanity check
    backup src tgt
    [ -L tgt/src/symlink ]
}

function test_symlinks_not_rewritten {
    touch src/symlinktarget
    ln -s src/symlinktarget src/symlink
    backup src tgt

    diff <( readlink src/symlink ) <( readlink tgt/src/symlink )
}

function test_group_preserved {
    touch src/f1
    chown 1001:1003 src/f1
    backup src tgt

    backup src tgt
    diff <(stat -c "%g" src/f1) <(stat -c "%g" tgt/src/f1)
}

function test_owner_preserved {
    touch src/f1
    chown 1001:1003 src/f1
    backup src tgt

    backup src tgt
    diff <(stat -c "%u" src/f1) <(stat -c "%u" tgt/src/f1)
}

function test_modification_time_preserved {
    touch src/f1
    sleep 1
    backup src tgt

    backup src tgt
    diff <(stat -c "%Y" src/f1) <(stat -c "%Y" tgt/src/f1)
}

function test_special_files_preserved {
    mkfifo src/f1
    backup src tgt

    [ -p tgt/src/f1 ]
}

function test_permissions {
    touch src/f1
    chmod 0777 src/f1
    backup src tgt

    diff <(stat -c "%a" src/f1) <(stat -c "%a" tgt/src/f1)
}

function test_incremental_backup_inodes_kept {
    dd if=/dev/zero of=src/f1 bs=1024 count=10
    backup src tgt
    backup src tgt2 "$PWD/tgt"

    ls -i tgt/src/f1
    ls -i tgt2/src/f1
    [ "$(ls -i tgt/src/f1 | cut -d" " -f1)" == "$(ls -i tgt2/src/f1 | cut -d" " -f1)" ]
}

function test_incremental_backup_changed_permissions {
    dd if=/dev/zero of=src/f1 bs=1024 count=10
    chmod 0500 src/f1
    backup src tgt
    chmod 0777 src/f1
    backup src tgt2 tgt

    ls -i tgt/src/f1
    ls -i tgt2/src/f1
    [ "$(ls -i tgt/src/f1 | cut -d" " -f1)" != "$(ls -i tgt2/src/f1 | cut -d" " -f1)" ]
}

function run_test {
    TMPFILE=$(mktemp)
    TMPDIR=$(mktemp -d)
    echo -n "$1"
    [ ! -z "$TMPDIR" ] || return 1
    (
        set -exu
        cd $TMPDIR
        mkdir src
        mkdir tgt
        mkdir tgt2
        $1
    ) > $TMPFILE 2>&1
    RESULT="$?"

    if [ "0" != "$RESULT" ]
    then
        echo " FAILED"
        cat $TMPFILE
        find "$TMPDIR"
    else
        echo " PASS"
    fi

    rm -rf $TMPDIR
    rm -f $TMPFILE
    return $RESULT
}

if [ "$1" = "list_tests" ]
then
    grep -e "^function *test_" $0 | while read line
    do 
        echo "$line" | cut -d" " -f2
    done
    exit 0
else
    $0 list_tests | while read testcase
    do
        run_test $testcase
    done
fi
