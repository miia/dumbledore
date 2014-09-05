COMPILE = vcom
sim: 
	vlib work
	find . -name "*.vhd" -not -name "TB*" | sort | xargs $(COMPILE)
	find ./test_bench/ -name "*.vhd" | sort | xargs $(COMPILE)
	../assembler.bin/dlxasm.pl -o software/test.bin -list software/test.list software/test.asm
	cat software/test.bin | hexdump -v -e '/1 "%02X" /1 "%02X" /1 "%02X" /1 "%02X\n"' > software/test\_dump.txt
	cp software/test\_dump.txt software/test.asm.mem
