# stop any simulation that is currently running
quit -sim

# if simulating with a MIF file, copy it to the working folder. Assumes inst_mem.mif
if {[file exists ../inst_mem.mif]} {
	file delete inst_mem.mif
	file copy ../inst_mem.mif .
}
# in case Quartus generated an "empty black box" file for the memory, delete it
if {[file exists ../inst_mem_bb.v]} {
	file delete ../inst_mem_bb.v
}

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog ../*.v
# compile the Verilog code of the testbench
vlog *.v
# start the Simulator
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 400 ns
