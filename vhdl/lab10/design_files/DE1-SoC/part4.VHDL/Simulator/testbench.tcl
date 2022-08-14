# stop any simulation that is currently running
quit -sim

# if simulating with a MIF file, copy it to the working folder. Assumes inst_mem.mif
if {[file exists ../inst_mem.mif]} {
	file delete inst_mem.mif
	file copy ../inst_mem.mif .
}
# in case Quartus generated an "empty black box" file for the memory, delete it
if {[file exists ../inst_mem_bb.vhd]} {
	file delete ../inst_mem_bb.vhd
}

if {[file exists work]} {
    file delete -force work
}

# create the default work folder
vlib work

# compile the VHDL source code in the parent folder
vcom -nolock ../*.vhd
# compile the VHDL code of the testbench
vcom -nolock *.vht
# start the Simulator, including some libraries that may be needed
vsim work.testbench -Lf 220model -Lf altera_mf
# show waveforms specified in wave.do
do wave.do

# suppress annoying VHDL warnings
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

# advance the simulation the desired amount of time
run 5500 ns
