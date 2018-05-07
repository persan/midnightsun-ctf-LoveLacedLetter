-include Makefile.conf

PROJECT=coder

all:compile test

compile:
	gprbuild -p -j0 -P ${PROJECT}.gpr

test:

Makefile.conf:Makefile  # IGNORE
	echo "export PATH=${PATH}" >$@
