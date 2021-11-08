onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label Resetn /testbench/Resetn
add wave -noupdate -label Clock /testbench/CLOCK_50
add wave -noupdate -label KEY /testbench/KEY
add wave -noupdate -label SW /testbench/SW
add wave -noupdate -label LEDR /testbench/LEDR
add wave -noupdate -divider proc
add wave -noupdate -label Resetn /testbench/U1/U3/Resetn
add wave -noupdate -label Clock /testbench/U1/U3/Clock
add wave -noupdate -label Run /testbench/U1/U3/Run
add wave -noupdate -label IR -radix hexadecimal /testbench/U1/U3/IR
add wave -noupdate -label FSM -radix hexadecimal /testbench/U1/U3/Tstep_Q
add wave -noupdate -label Done /testbench/U1/U3/Done
add wave -noupdate -label W /testbench/U1/U3/W
add wave -noupdate -label PC -radix hexadecimal /testbench/U1/U3/PC
add wave -noupdate -label DIN -radix hexadecimal /testbench/U1/U3/DIN
add wave -noupdate -label ADDR -radix hexadecimal /testbench/U1/U3/ADDR
add wave -noupdate -label inst_mem -radix hexadecimal /testbench/U1/inst_mem_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {500000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 91
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {588269 ps}
