if exist ..\inst_mem.mif (
    copy /Y ..\inst_mem.mif .
)
if exist ..\inst_mem_bb.v (
    del ..\inst_mem_bb.v
)
if exist work rmdir /S /Q work

vlib work
vlog -nolock ../tb/*.v
if exist ../*.v (
	vlog -nolock ../*.v
)
if exist ../*.sv (
	vlog -nolock ../*.sv
)
if exist ../*.vhd (
    vcom -nolock ../*.vhd
)
