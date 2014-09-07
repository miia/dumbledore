COMPILE = vcom
MAP = vmap
sim: program
	vlib work
	find . -name "*.vhd" -not -iname "TB*" -not -iname "syn_dlx.vhd" | sort | xargs $(COMPILE)
	find ./test_bench/ -name "*.vhd" | sort | xargs $(COMPILE)
.PHONY: program
synsim: program nangate
	$(COMPILE) ../syn/results/SYN_DLX.vhdl
program:
	../assembler.bin/dlxasm.pl -o software/test.bin -list software/test.list software/test.asm
	cat software/test.bin | hexdump -v -e '/1 "%02X" /1 "%02X" /1 "%02X" /1 "%02X\n"' > software/test\_dump.txt
	cp software/test\_dump.txt software/test.asm.mem
nangate:
	$(MAP) work work/
	$(MAP) nangate work/
	$(COMPILE) ../syn/results/nangate_Vcomponents.vhdl ../syn/results/nangate_Vtables.vhdl ../syn/results/nangate_VITAL.vhdl
