# rsyncdiscovery
A test script to find out rsync parameters for backup.

## Conclusion
To copy `src` to `tgt`:

    rsync -r -H -l -g -o -t -D -p --del src tgt

And you will end up with

    tgt/src

being a mirror of the original `src` directory.

## Test usage
To discover the tests:

    ./test_rsync.sh list_tests

To run the tests:

    sudo ./test_rsync.sh

## Background
I would like to create a file-level backup of some files. My goal is to use
rsync to do the job. As rsync has a lot of command line switches, first, I
would need to know, which ones to use. For this, I have some expectations:

  1. Backup is recursive
  2. Extra files removed
  3. Links are preserved
  4. Symlinks are preserved
  5. Symlinks are not rewritten
  6. Preserve permissions
  7. Modification times are preserved
  8. Special files reserved

And of course, a test-driven approach will be used. Bash does not prevent you
from writing tests, so go ahead.

Ending slash: The ending slash is important on the source side, if you wish to
say to copy the contents of that directory, not the directory itself.

The archive mode includes:

 - `r` - recursive
 - `l` - copy symlinks as symlinks
 - `p` - preserve permissions
 - `t` - preserve modification times
 - `g` - preserve group
 - `o` - preserve owner
 - `D` - preserve device and special files

And the manual also states, that it does not include:
 - `H` - preserve hard links
 - `A` - preserve ACLs
 - `X` - preserve extended attributes

For me the hardlinks seem to be important.
