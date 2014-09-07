#Generates a VHDL file from libnangate_typical "lib" file 
#This can be used for post-simulation synthesis :) 
read_lib ~mariagrazia.graziano/do/libnangate/NangateOpenCellLibrary_typical_ecsm.lib
##VERY IMPORTANT NOTICE:
#The generated files will *not* be nangate.vhdl, but will be three files to compile into library work.
#They are using library "nangate" within each other, so we have to tell modelsim they are the same library:
#vmap nangate $(pwd)/work
#vmap work $(pwd)/work
#vcom nangate_Vcomponents.vhdl nangate_Vtables.vhdl nangate_VITAL.vhdl
#vcom everything else
#enjoy :)
write_lib NangateOpenCellLibrary -format vhdl -output results/nangate.vhdl
