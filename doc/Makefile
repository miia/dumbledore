all:
	dot Instruction_set.dot -Teps > Instruction_set.eps
	dot BPU_fsm.dot -Teps > BPU_fsm.eps
	epstopdf BPU_fsm.eps
	epstopdf Instruction_set.eps
	convert -density 300 -units PixelsPerInch -resize 1200x1200 clock_tree_synthesis/clock_tree_show_distribution.gif clock_tree_synthesis/clock_tree_show_distribution.png
	convert -density 300 -units PixelsPerInch -resize 1200x1200 clock_tree_synthesis/clock_tree_phase_delay.gif clock_tree_synthesis/clock_tree_phase_delay.png
	convert -density 300 -units PixelsPerInch -resize 1200x1200 encounter_pictures/screenshot_complete.gif encounter_pictures/screenshot_complete.png
	convert -rotate 90 -resize 1000x1000 -density 300 -units PixelsPerInch pareto.ps pareto.pdf
	for file in `find . -name "*.md" | sort` ; do \
		pandoc -f markdown -t latex $$file -o $${file%???}.tex -M author="Simone Baratta" -M author="Michele Iacobone" -V "geometry:margin=1.5in" ; \
	done
	lyx --export pdf2 report.lyx
	xdg-open report.pdf
