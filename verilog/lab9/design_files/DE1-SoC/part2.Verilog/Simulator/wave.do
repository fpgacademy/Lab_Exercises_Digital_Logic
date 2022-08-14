onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label KEY /testbench/KEY
add wave -noupdate -label SW /testbench/SW
add wave -noupdate -label counter -radix hexadecimal /testbench/U1/U3/Q
add wave -noupdate -label MClock /testbench/U1/U3/Clock
add wave -noupdate -divider proc
add wave -noupdate -label PClock /testbench/U1/U1/Clock
add wave -noupdate -label Resetn /testbench/U1/U1/Resetn
add wave -noupdate -label Run /testbench/U1/U1/Run
add wave -noupdate -label IR -radix hexadecimal /testbench/U1/U1/IR
add wave -noupdate -label Done /testbench/U1/U1/Done
add wave -noupdate -label inst_mem -radix hexadecimal /testbench/U1/U2/q
add wave -noupdate -label FSM /testbench/U1/U1/Tstep_Q
add wave -noupdate -label r0 -radix hexadecimal /testbench/U1/U1/r0
add wave -noupdate -label r1 -radix hexadecimal /testbench/U1/U1/r1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {70000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 92
configure wave -valuecolwidth 66
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
WaveRestoreZoom {25326 ps} {325326 ps}
