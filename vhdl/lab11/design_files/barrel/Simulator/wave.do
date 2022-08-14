onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label shift_type /testbench/U1/shift_type
add wave -noupdate -label A -radix hexadecimal /testbench/U1/A
add wave -noupdate -label BusWires -radix hexadecimal /testbench/U1/BusWires
add wave -noupdate -label B -radix hexadecimal /testbench/U1/B
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {350000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 99
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
WaveRestoreZoom {19681420 ps} {20016768 ps}
