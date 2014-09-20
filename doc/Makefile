all:
	dot Instruction_set.dot -Tpdf > Instruction_set.pdf
	dot BPU_fsm.dot -Tpdf > BPU_fsm.pdf
	for file in ./*.md ; do \
		pandoc -f markdown -t latex $$file -o $${file%???}.tex -M author="Simone Baratta" -M author="Michele Iacobone" --chapters -V "geometry:margin=1.5in" ; \
	done
	lyx --export pdf2 report.lyx
