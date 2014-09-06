COMPILE = vcom
sim: program
	vlib work
	find . -name "*.vhd" -not -iname "TB*" -not -iname "syn_dlx.vhd" | sort | xargs $(COMPILE)
	find ./test_bench/ -name "*.vhd" | sort | xargs $(COMPILE)
.PHONY: program
synsim: program
	vlib work_syn
	$(COMPILE) SYN_DLX.v
program:
	../assembler.bin/dlxasm.pl -o software/test.bin -list software/test.list software/test.asm
	cat software/test.bin | hexdump -v -e '/1 "%02X" /1 "%02X" /1 "%02X" /1 "%02X\n"' > software/test\_dump.txt
	cp software/test\_dump.txt software/test.asm.mem


