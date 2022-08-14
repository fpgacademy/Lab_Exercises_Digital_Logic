if exist ..\inst_mem.mif (
    copy /Y ..\inst_mem.mif .
)
if exist ..\inst_mem_bb.v (
    del ..\inst_mem_bb.v
)

rem Some editors make .vhd~ backup files. These files match *.vhd in 
rem .bat scripts, so rem temporarily move them before compiling
if exist ..\*.vhd~ (
    mkdir tmp_vhd~
    copy ..\*.vhd~ tmp_vhd~
    del ..\*.vhd~
)

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

rem If .vhd~ backup files were removed, restore them
if exist tmp_vhd~ (
    copy tmp_vhd~\*.vhd~ ..\
    del /q tmp_vhd~
    rmdir tmp_vhd~
)

