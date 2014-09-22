all:
	dot Instruction_set.dot -Teps > Instruction_set.eps
	dot BPU_fsm.dot -Teps > BPU_fsm.eps
	epstopdf BPU_fsm.eps
	epstopdf Instruction_set.eps
	for file in ./*.md ; do \
		pandoc -f markdown -t latex $$file -o $${file%???}.tex -M author="Simone Baratta" -M author="Michele Iacobone" --chapters -V "geometry:margin=1.5in" ; \
	done
	lyx --export pdf2 report.lyx
	xdg-open report.pdf
