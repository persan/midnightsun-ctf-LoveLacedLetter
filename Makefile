-include Makefile.conf

PROJECT=coder
export  GNAT_STACK_LIMIT=64000
all:compile test

compile:
	gprbuild -p -j0 -P ${PROJECT}.gpr

test:
	@make encode
	@make decode

encode:
	@echo data/Gripen_Agressor_21082017__ISV1318.bmp >input
	@echo "56124" >>input
	@echo "midnight{556717188}" >>input
	@echo Gripen_Agressor_21082017__ISV1318-2.bmp>>input
	
decode:
	ulimit -s unlimited ; echo Gripen_Agressor_21082017__ISV1318.bmp  |bin/decode

Makefile.conf:Makefile  # IGNORE
	echo "export PATH=${PATH}" >$@
