GHDL = ghdl

VPATH=.. ../cpu ../tg68 ../m68030
HDMI_MODULES = \
    video_pll.o \
    vga_generator.o \
    vpg.o \
    debounce.o \
    i2c_slave.o \
    i2c_master.o \
    i2c_hdmi_config.o \
    hdmi_audio.o \
	hdmi_tx.o \
    pll.o \
    deca_clocks.o \
    jtag_uart.o \
	hdmi_tb.o

# CPU_MODULES = \
    # TG68K_Pack.o \
	# TG68K_ALU.o \
    # TG68KdotC_Kernel.o \
    # simple.o \
    # simple_memory.o \
    # simple_m68k.o \
    # jtag_uart.o \
    # cpu_tb.o

CPU_MODULES= \
	wf68k30l_pkg.o \
	wf68k30l_address_registers.o \
	wf68k30l_alu.o \
	wf68k30l_bus_interface.o \
	wf68k30l_control.o \
	wf68k30l_data_registers.o \
	wf68k30l_exception_handler.o \
	wf68k30l_opcode_decoder.o \
	wf68k30l_top.o \
    simple.o \
    simple_memory.o \
    simple_m68k.o \
    jtag_uart.o \
    cpu_tb.o

DDR_MODULES = \
	ddr_tb.o

GHDLFLAGS=--std=08 -Paltera --ieee=synopsys -Wno-binding
GHDL_RUNFLAGS=--ieee-asserts=disable-at-0

.PHONY: all
all:    hdmi

hdmi: $(HDMI_MODULES) hdmi_tb
cpu: $(CPU_MODULES) cpu_tb
ddr: $(DDR_MODULES) ddr_tb

run_hdmi: $(HDMI_MODULES)
	$(GHDL) -r $(GHDLFLAGS) hdmi_tb --disp-tree $(GHDL_RUNFLAGS) --wave=hdmi.ghw

run_cpu: $(CPU_MODULES)
	$(GHDL) -r $(GHDLFLAGS) cpu_tb --disp-tree $(GHDL_RUNFLAGS) --wave=cpu.ghw

run_ddr: $(DDR_MODULES)
	$(GHDL) -r $(GHDLFLAGS) ddr_tb --disp-tree $(GHDL_RUNFLAGS) --wave=ddr_tb.ghw

%: %.o
	$(GHDL) -e $(GHDLFLAGS) $@

%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

.PHONY: view
view_hdmi:
	gtkwave hdmi.ghw hdmi_tb.gtkw

view_cpu:
	gtkwave cpu.ghw cpu_tb.gtkw

view_ddr:
	gtkwave ddr_tb.ghw ddr_tb.gtkw

.PHONY: clean
clean:
	rm -f *.o blitter work*.cf e*.lst *.ghw
