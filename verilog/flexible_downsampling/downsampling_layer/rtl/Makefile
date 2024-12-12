# Verilog files
VERILOG_FILES = \
	./v/bilinear_interpolation.sv \
	./v/downsample.sv \
	./v/flexible_downsampling.sv \
	./v/tb_flexible_downsampling.sv

# Testbench module
TESTBENCH_MODULE = tb_flexible_downsampling

# Wave file
WAVE_FILE = ./wave/wave.do

# vsim path
VSIMPATH = /usr/local/mentor/modelsim-2019.1/modeltech/bin

# Default target
all: sim view

# Compile Verilog files
sim:
	$(VSIMPATH)/vlog $(VERILOG_FILES)

# Elaborate design and run simulation
view:
	$(VSIMPATH)/vsim -vopt work.$(TESTBENCH_MODULE) -voptargs=+acc -do "do $(WAVE_FILE); run 50000000"

# Clean intermediate files
clean:
	rm -f transcript 
	rm -f *.wlf
	rm -f *.log
	rm -f *.vcd

clean-compiled:
	rm -r ./work

clean-all: clean clean-compiled

.PHONY: all sim view clean clean-all
