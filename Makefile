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
	@echo "midnight{saab_1s_hunt1ng_s1gn1f1catn_l1ts}" >>input
	@echo Gripen_Agressor_21082017__ISV1318-2.bmp>>input
	-(ulimit -s unlimited ; cat input  | bin/encode)
	
decode:
	-ulimit -s unlimited ; echo Gripen_Agressor_21082017__ISV1318-2.bmp  | bin/decode

Makefile.conf:Makefile  # IGNORE
	echo "export PATH=${PATH}" >$@
