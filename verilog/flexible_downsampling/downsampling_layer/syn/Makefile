# Verilog files (relative to sim directory)
VERILOG_FILES = \
    ../v/flexible_downsampling.sv \
    ../v/downsample.sv \
    ../v/bilinear_interpolation.sv \
	../v/tb_flexible_downsampling.sv \
	./standard_cells/asap7sc7p5t_24_AO_RVT_TT.v \
	./standard_cells/asap7sc7p5t_24_INVBUF_RVT_TT.v \
	./standard_cells/asap7sc7p5t_24_OA_RVT_TT.v \
	./standard_cells/asap7sc7p5t_24_SEQ_RVT_TT.v \
	./standard_cells/asap7sc7p5t_24_SIMPLE_RVT_TT.v

# Testbench module
TESTBENCH_MODULE = tb_flexible_downsampling

# Wave file
WAVE_FILE = ./wave/wave.do

# vsim path
VSIMPATH = /usr/local/mentor/modelsim-2019.1/modeltech/bin

# Default target
all: syn sim view

# Synthesize design
syn:
	cd ./synthesis && \
	dc_shell -f ../dc.tcl -output_log_file ../syn.log && \
	cd ..

sim:
	cd ./sim && \
	$(VSIMPATH)/vlog $(VERILOG_FILES) && \
	cd ..

# Elaborate design and run simulation
view:
	cd ./sim && \
	$(VSIMPATH)/vsim -vopt work.$(TESTBENCH_MODULE) -voptargs=+acc -do "do $(WAVE_FILE); run -all" && \
	cd ..

# Clean intermediate files
clean:
	-rm -f *.pvl
	-rm -f *.syn
	-rm -f *.mr
	-rm -f *.log
	-rm -f default.svf
	-rm -f syn.log
	-rm -f transcript 
	-rm -f *.wlf
	-rm -f *.log
	-rm -f *.vcd
	-rm -r alib-52

clean-output:
	-rm -r ./output/*
	-rm -r ./rpt/*
	-rm -r ./synthesis/*
	-rm -r ./work

clean-all: clean clean-output

.PHONY: all compile sim view clean clean-all
