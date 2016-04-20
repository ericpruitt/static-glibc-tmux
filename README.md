static-tmux
===========

This repository contains a Makefile and patches to produce a fully statically
linked tmux binary. When using the vanilla tmux and libevent sources to build a
statically linked tmux executable, the generated binary still has hard
dependencies on the glibc version of the system that built the binary; a few
warnings like this one will be emitted during the build process:

    cmd-string.c:331: warning: … requires … the glibc version used for linking

By making a couple of relatively minor changes to the tmux and libevent
codebases, the glibc version dependency can be completely eliminated. In tmux,
references to `getpwnam(3)` and `getpwuid(3)` are eliminated at the cost of
tmux not being able to determine a user's home directory and shell if the
`HOME` and `SHELL` environment variables are unset. I am unaware of any
negative effects the changes to libevent may have since libevent re-implements
and / or circumvents the disabled features.

The Makefile will not retrieve any dependencies other than libevent, so all
other build dependencies must be manually installed before attempting to build
the tmux binary. On Debian-based systems, the other dependencies can be
installed by running `sudo apt-get build-dep tmux`.

Licensing
---------

The Makefile is licensed under the [2-clause BSD license][1], and the patches
for tmux and libevent are licensed under each project's respective license.

Instructions
------------

To build the tmux binary, simply run `make` (which is implicitly `make all`)
inside the root of the repository. Some of the other targets provided by the
Makefile include:

- **install**: Install tmux and its manual. Refer to the description of
  `INSTALLDIR` and `BINDIR` below. The tmux binary will be built as necessary
  when this target is used.
- **uninstall**: Remove the tmux binary and manual from `INSTALLDIR` and the
  tmux symlink from `BINDIR`.
- **dist**: Create a distributable, compressed archive. To install tmux, simply
  extract the archive on the target system, `cd` into the `tmux` directory and
  run `make install`. By default, symlinks to the executable will be placed in
  `~/bin/`. To install the symlinks in another directory, override the Makefile
  variable `BINDIR`: `make BINDIR=/usr/local/bin install`. By default, this
  produces a tar.bz2 archive. Override the `DISTEXTENSION` to change this,
  e.g., `make dist DISTEXTENSION=tar.xz`.
- **update**: Update the local copy of the tmux source code if it is out of
  sync with the official repository, and implicitly execute the **clean**
  target. If the local copy of tmux is already up-to-date, this will fail with
  a non-zero exit status, and no files will be modified. This may be useful for
  scheduling automatic updates (`make update && make install`).
- **clean**: Restore the tmux repository to a pristine state and delete the
  tmux binary if it exists. The `clean-tmux` target is a synonym for this
  target.
- **cleaner**: Same as `clean` but also execute `make distclean` inside the
  libevent folder.
- **cleanest**: Delete all targets generated by the Makefile in the root of
  this repository.

The symlink created in `BINDIR` points to a wrapper script that will show the
tmux manual when called with "help" or "man" as its first argument, e.g. `tmux
help`. When passed no additional arguments or anything other than the
aforementioned keywords, the tmux binary is launched with whatever arguments
were passed to the script.

Matthew Gyurgyik's post "[building tmux 1.9a statically][2]", which was used as
a reference in creating this repository, may prove useful if any issues arise
during the build process.

  [1]: http://opensource.org/licenses/BSD-2-Clause
  [2]: http://pyther.net/2014/03/building-tmux-1-9a-statically/
