GHDL = ghdl

VPATH=..
HDMI_MODULES = \
    video_pll.o \
    vga_generator.o \
    vpg.o \
    i2c_controller.o \
    i2c_hdmi_config.o \
	hdmi_tx.o \
    pll.o \
    deca_clocks.o \
    jtag_uart.o \
	hdmi_tb.o

DDR_MODULES = \
	ddr_tb.o

GHDLFLAGS=--std=08 -Paltera --ieee=synopsys -Wno-binding
GHDL_RUNFLAGS=--ieee-asserts=disable-at-0

.PHONY: all
all:    hdmi

hdmi: $(HDMI_MODULES) hdmi_tb
ddr: $(DDR_MODULES) ddr_tb

run_hdmi: $(HDMI_MODULES)
	$(GHDL) -r $(GHDLFLAGS) hdmi_tb --disp-tree $(GHDL_RUNFLAGS) --wave=hdmi.ghw

run_ddr: $(DDR_MODULES)
	$(GHDL) -r $(GHDLFLAGS) ddr_tb --disp-tree $(GHDL_RUNFLAGS) --wave=ddr_tb.ghw

%: %.o
	$(GHDL) -e $(GHDLFLAGS) $@

%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

.PHONY: view
view_hdmi:
	gtkwave hdmi.ghw hdmi_tb.gtkw

view_ddr:
	gtkwave ddr_tb.ghw ddr_tb.gtkw

.PHONY: clean
clean:
	rm -f *.o blitter work*.cf e*.lst *.ghw