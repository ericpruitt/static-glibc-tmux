# Author: Eric Pruitt (http://www.codevat.com)
# License: 2-Clause BSD (http://opensource.org/licenses/BSD-2-Clause)
# Description: This Makefile is designed to create a statically linked tmux
#       binary without any dependencies on the host system's version of glibc.

# Directory in which to install tmux.
INSTALLDIR=$(HOME)/tmux
# Folder in $PATH where symlinks to the executables are placed.
BINDIR=$(HOME)/bin
# Extension to use when creating a compressed, distributable archive.
DISTEXTENSION=tar.bz2

# URL of the libevent tarball
LIBEVENT_TARBALL_URL=https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
# Git repository URL for tmux
TMUX_GIT_REPOSITORY_URL=https://github.com/tmux/tmux.git
# Basename of the compressed archive
DISTTARGET=tmux.$(DISTEXTENSION)
# Determines whether or not `make` is automatically executed inside $INSTALLDIR
# to create symlinks to the executables. Can be "false" or "true" but should
# generally not be modified by the end-user and only exists to simplify
# creation of distributable archives.
DISTMAKE=true

all: tmux-src/tmux

libevent.tar.gz:
	wget $(LIBEVENT_TARBALL_URL) -O $@

libevent: libevent.tar.gz
	tar xf $^
	mv libevent*/ $@

libevent/configure: libevent

libevent/Makefile: libevent/configure
	cd libevent && ./configure --prefix="$$PWD/build" --disable-shared

libevent/build: libevent/Makefile
	if ! stat libevent/*.orig > /dev/null 2>&1; then \
		cd libevent || exit 1; \
		patch -b -p1 < ../libevent-static-build.patch; \
	fi
	cd libevent && $(MAKE) install

tmux-src:
	git clone $(TMUX_GIT_REPOSITORY_URL) $@; \
	cd $@; \
	git fetch origin --tags; \
	git checkout 1.9a; \

update: tmux-src
	@set -e; \
	cd tmux-src; \
	echo 'Checking for updates...'; \
	git fetch origin; \
	if git diff origin/master HEAD --quiet; then \
		echo 'No updates for master branch found.'; \
		exit 1; \
	else \
		(cd .. && $(MAKE) clean-tmux); \
		git merge origin/master; \
	fi

tmux-src/autogen.sh: tmux-src

tmux-src/configure: tmux-src/autogen.sh
	cd tmux-src && ./autogen.sh

tmux-src/Makefile: tmux-src/configure libevent/build
	cd tmux-src && \
	./configure \
		--enable-static \
		CFLAGS="-I$$PWD/../libevent/build/include" \
		LDFLAGS="-L$$PWD/../libevent/build/lib \
		         -L$$PWD/../libevent/build/include" \
		LIBEVENT_CFLAGS="-I$$PWD/../libevent/build/include" \
		LIBEVENT_LIBS="-L$$PWD/../libevent/build/lib -levent"

tmux-src/tmux: tmux-src/Makefile
	@if ! stat tmux-src/*.orig > /dev/null 2>&1; then \
		cd tmux-src || exit 1; \
		patch -b -p1 < ../tmux-static-build.patch; \
	fi
	cd tmux-src && $(MAKE)

tmux.vim: generate-vim-syntax.sh $(wildcard tmux-src/*.c) | tmux-src
	./generate-vim-syntax.sh

clean-tmux:
	@if [ -e tmux-src ]; then \
		set -e; \
		cd tmux-src; \
		git reset --hard; \
		git clean -x -f -d -q; \
	fi

$(INSTALLDIR): tmux-src/tmux
	@echo 'Installing:'
	@mkdir $(INSTALLDIR) $(INSTALLDIR)/man1
	@cp tmux.sh tmux-src/tmux $(INSTALLDIR)
	@cp Makefile.dist $(INSTALLDIR)/Makefile
	@cp tmux-src/tmux.1 $(INSTALLDIR)/man1
	@echo "- $(INSTALLDIR)"
	@if $(DISTMAKE); then \
		cd $(INSTALLDIR) || exit 1; \
		$(MAKE) -s BINDIR=$(BINDIR) install; \
	fi

install: $(INSTALLDIR)

uninstall:
	@if [ -e $(INSTALLDIR)/Makefile ]; then \
		set -e; \
		cd $(INSTALLDIR); \
		$(MAKE) -s uninstall; \
		echo '- $(INSTALLDIR)'; \
		rm -rf $(INSTALLDIR); \
	else \
		echo 'Nothing to uninstall.'; \
		exit 1; \
	fi

$(DISTTARGET): tmux-src/tmux
	@$(MAKE) -s INSTALLDIR=$(PWD)/tmux DISTMAKE=false install > /dev/null
	@tar acf $@ tmux/
	@rm -rf tmux/
	@echo 'Created distributable, compressed archive: $@'

dist: $(DISTTARGET)

clean: clean-tmux

clean-libevent:
	@if [ -e libevent ]; then \
		set -e; \
		cd libevent; \
		rm -rf build; \
		$(MAKE) distclean; \
	fi

cleaner: clean-tmux clean-libevent

cleanest:
	rm -rf libevent tmux-src $(DISTTARGET) libevent.tar.gz

.PHONY: all clean-tmux clean clean-libevent cleaner cleanest dist install \
	uninstall update
