all:
	dot Instruction_set.dot -Teps > Instruction_set.eps
	dot BPU_fsm.dot -Teps > BPU_fsm.eps
	pandoc -f markdown -t latex *.md -o fetch_stage.pdf
