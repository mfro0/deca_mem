--IP Functional Simulation Model
--VERSION_BEGIN 18.1 cbx_mgl 2019:04:11:18:00:57:SJ cbx_simgen 2019:04:11:16:03:28:SJ  VERSION_END


-- Copyright (C) 2019  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details, at
-- https://fpgasoftware.intel.com/eula.

-- You may only use these simulation model output files for simulation
-- purposes and expressly not for synthesis or any other purposes (in which
-- event Intel disclaims all warranties of any kind).


--synopsys translate_off

 LIBRARY altera_mf;
 USE altera_mf.altera_mf_components.all;

--synthesis_resources = altpll 1 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  ddr3_mem_pll0 IS 
	 PORT 
	 ( 
		 afi_clk	:	OUT  STD_LOGIC;
		 afi_half_clk	:	OUT  STD_LOGIC;
		 global_reset_n	:	IN  STD_LOGIC;
		 phasecounterselect	:	IN  STD_LOGIC_VECTOR (2 DOWNTO 0);
		 phasedone	:	OUT  STD_LOGIC;
		 phasestep	:	IN  STD_LOGIC;
		 phaseupdown	:	IN  STD_LOGIC;
		 pll_capture0_clk	:	OUT  STD_LOGIC;
		 pll_capture1_clk	:	OUT  STD_LOGIC;
		 pll_locked	:	OUT  STD_LOGIC;
		 pll_mem_clk	:	OUT  STD_LOGIC;
		 pll_ref_clk	:	IN  STD_LOGIC;
		 pll_write_clk	:	OUT  STD_LOGIC;
		 scanclk	:	IN  STD_LOGIC
	 ); 
 END ddr3_mem_pll0;

 ARCHITECTURE RTL OF ddr3_mem_pll0 IS

	 ATTRIBUTE synthesis_clearbox : natural;
	 ATTRIBUTE synthesis_clearbox OF RTL : ARCHITECTURE IS 1;
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_areset	:	STD_LOGIC;
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk	:	STD_LOGIC_VECTOR (4 DOWNTO 0);
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_clkena	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_gnd	:	STD_LOGIC;
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_extclkena	:	STD_LOGIC_VECTOR (3 DOWNTO 0);
	 SIGNAL  wire_vcc	:	STD_LOGIC;
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_inclk	:	STD_LOGIC_VECTOR (1 DOWNTO 0);
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_locked	:	STD_LOGIC;
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_phasecounterselect	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_ddr3_mem_pll0_altpll_upll_memphy_105_phasedone	:	STD_LOGIC;
	 SIGNAL  wire_w_lg_global_reset_n6w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
 BEGIN

	wire_gnd <= '0';
	wire_vcc <= '1';
	wire_w_lg_global_reset_n6w(0) <= NOT global_reset_n;
	afi_clk <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk(4);
	afi_half_clk <= '0';
	phasedone <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_phasedone;
	pll_capture0_clk <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk(2);
	pll_capture1_clk <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk(3);
	pll_locked <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_locked;
	pll_mem_clk <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk(0);
	pll_write_clk <= wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk(1);
	wire_ddr3_mem_pll0_altpll_upll_memphy_105_areset <= wire_w_lg_global_reset_n6w(0);
	wire_ddr3_mem_pll0_altpll_upll_memphy_105_clkena <= ( "1" & "1" & "1" & "1" & "1" & "1");
	wire_ddr3_mem_pll0_altpll_upll_memphy_105_extclkena <= ( "1" & "1" & "1" & "1");
	wire_ddr3_mem_pll0_altpll_upll_memphy_105_inclk <= ( "0" & pll_ref_clk);
	wire_ddr3_mem_pll0_altpll_upll_memphy_105_phasecounterselect <= ( phasecounterselect(2 DOWNTO 0));
	ddr3_mem_pll0_altpll_upll_memphy_105 :  altpll
	  GENERIC MAP (
		BANDWIDTH => 0,
		BANDWIDTH_TYPE => "AUTO",
		C0_HIGH => 0,
		C0_INITIAL => 0,
		C0_LOW => 0,
		C0_MODE => "BYPASS",
		C0_PH => 0,
		C0_TEST_SOURCE => 5,
		C1_HIGH => 0,
		C1_INITIAL => 0,
		C1_LOW => 0,
		C1_MODE => "BYPASS",
		C1_PH => 0,
		C1_TEST_SOURCE => 5,
		C1_USE_CASC_IN => "OFF",
		C2_HIGH => 0,
		C2_INITIAL => 0,
		C2_LOW => 0,
		C2_MODE => "BYPASS",
		C2_PH => 0,
		C2_TEST_SOURCE => 5,
		C2_USE_CASC_IN => "OFF",
		C3_HIGH => 0,
		C3_INITIAL => 0,
		C3_LOW => 0,
		C3_MODE => "BYPASS",
		C3_PH => 0,
		C3_TEST_SOURCE => 5,
		C3_USE_CASC_IN => "OFF",
		C4_HIGH => 0,
		C4_INITIAL => 0,
		C4_LOW => 0,
		C4_MODE => "BYPASS",
		C4_PH => 0,
		C4_TEST_SOURCE => 5,
		C4_USE_CASC_IN => "OFF",
		C5_HIGH => 0,
		C5_INITIAL => 0,
		C5_LOW => 0,
		C5_MODE => "BYPASS",
		C5_PH => 0,
		C5_TEST_SOURCE => 5,
		C5_USE_CASC_IN => "OFF",
		C6_HIGH => 0,
		C6_INITIAL => 0,
		C6_LOW => 0,
		C6_MODE => "BYPASS",
		C6_PH => 0,
		C6_TEST_SOURCE => 5,
		C6_USE_CASC_IN => "OFF",
		C7_HIGH => 0,
		C7_INITIAL => 0,
		C7_LOW => 0,
		C7_MODE => "BYPASS",
		C7_PH => 0,
		C7_TEST_SOURCE => 5,
		C7_USE_CASC_IN => "OFF",
		C8_HIGH => 0,
		C8_INITIAL => 0,
		C8_LOW => 0,
		C8_MODE => "BYPASS",
		C8_PH => 0,
		C8_TEST_SOURCE => 5,
		C8_USE_CASC_IN => "OFF",
		C9_HIGH => 0,
		C9_INITIAL => 0,
		C9_LOW => 0,
		C9_MODE => "BYPASS",
		C9_PH => 0,
		C9_TEST_SOURCE => 5,
		C9_USE_CASC_IN => "OFF",
		CHARGE_PUMP_CURRENT => 2,
		CHARGE_PUMP_CURRENT_BITS => 9999,
		CLK0_COUNTER => "G0",
		CLK0_DIVIDE_BY => 1,
		CLK0_DUTY_CYCLE => 50,
		CLK0_MULTIPLY_BY => 6,
		CLK0_OUTPUT_FREQUENCY => 0,
		CLK0_PHASE_SHIFT => "0",
		CLK0_TIME_DELAY => "0",
		CLK0_USE_EVEN_COUNTER_MODE => "OFF",
		CLK0_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK1_COUNTER => "G0",
		CLK1_DIVIDE_BY => 1,
		CLK1_DUTY_CYCLE => 50,
		CLK1_MULTIPLY_BY => 6,
		CLK1_OUTPUT_FREQUENCY => 0,
		CLK1_PHASE_SHIFT => "2500",
		CLK1_TIME_DELAY => "0",
		CLK1_USE_EVEN_COUNTER_MODE => "OFF",
		CLK1_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK2_COUNTER => "G0",
		CLK2_DIVIDE_BY => 1,
		CLK2_DUTY_CYCLE => 50,
		CLK2_MULTIPLY_BY => 6,
		CLK2_OUTPUT_FREQUENCY => 0,
		CLK2_PHASE_SHIFT => "0",
		CLK2_TIME_DELAY => "0",
		CLK2_USE_EVEN_COUNTER_MODE => "OFF",
		CLK2_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK3_COUNTER => "G0",
		CLK3_DIVIDE_BY => 1,
		CLK3_DUTY_CYCLE => 50,
		CLK3_MULTIPLY_BY => 6,
		CLK3_PHASE_SHIFT => "2500",
		CLK3_TIME_DELAY => "0",
		CLK3_USE_EVEN_COUNTER_MODE => "OFF",
		CLK3_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK4_COUNTER => "G0",
		CLK4_DIVIDE_BY => 1,
		CLK4_DUTY_CYCLE => 50,
		CLK4_MULTIPLY_BY => 3,
		CLK4_PHASE_SHIFT => "0",
		CLK4_TIME_DELAY => "0",
		CLK4_USE_EVEN_COUNTER_MODE => "OFF",
		CLK4_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK5_COUNTER => "G0",
		CLK5_DIVIDE_BY => 1,
		CLK5_DUTY_CYCLE => 50,
		CLK5_MULTIPLY_BY => 1,
		CLK5_PHASE_SHIFT => "0",
		CLK5_TIME_DELAY => "0",
		CLK5_USE_EVEN_COUNTER_MODE => "OFF",
		CLK5_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK6_COUNTER => "E0",
		CLK6_DIVIDE_BY => 0,
		CLK6_DUTY_CYCLE => 50,
		CLK6_MULTIPLY_BY => 0,
		CLK6_PHASE_SHIFT => "0",
		CLK6_USE_EVEN_COUNTER_MODE => "OFF",
		CLK6_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK7_COUNTER => "E1",
		CLK7_DIVIDE_BY => 0,
		CLK7_DUTY_CYCLE => 50,
		CLK7_MULTIPLY_BY => 0,
		CLK7_PHASE_SHIFT => "0",
		CLK7_USE_EVEN_COUNTER_MODE => "OFF",
		CLK7_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK8_COUNTER => "E2",
		CLK8_DIVIDE_BY => 0,
		CLK8_DUTY_CYCLE => 50,
		CLK8_MULTIPLY_BY => 0,
		CLK8_PHASE_SHIFT => "0",
		CLK8_USE_EVEN_COUNTER_MODE => "OFF",
		CLK8_USE_EVEN_COUNTER_VALUE => "OFF",
		CLK9_COUNTER => "E3",
		CLK9_DIVIDE_BY => 0,
		CLK9_DUTY_CYCLE => 50,
		CLK9_MULTIPLY_BY => 0,
		CLK9_PHASE_SHIFT => "0",
		CLK9_USE_EVEN_COUNTER_MODE => "OFF",
		CLK9_USE_EVEN_COUNTER_VALUE => "OFF",
		COMPENSATE_CLOCK => "CLK1",
		DOWN_SPREAD => "0",
		DPA_DIVIDE_BY => 1,
		DPA_DIVIDER => 0,
		DPA_MULTIPLY_BY => 0,
		E0_HIGH => 1,
		E0_INITIAL => 1,
		E0_LOW => 1,
		E0_MODE => "BYPASS",
		E0_PH => 0,
		E0_TIME_DELAY => 0,
		E1_HIGH => 1,
		E1_INITIAL => 1,
		E1_LOW => 1,
		E1_MODE => "BYPASS",
		E1_PH => 0,
		E1_TIME_DELAY => 0,
		E2_HIGH => 1,
		E2_INITIAL => 1,
		E2_LOW => 1,
		E2_MODE => "BYPASS",
		E2_PH => 0,
		E2_TIME_DELAY => 0,
		E3_HIGH => 1,
		E3_INITIAL => 1,
		E3_LOW => 1,
		E3_MODE => "BYPASS",
		E3_PH => 0,
		E3_TIME_DELAY => 0,
		ENABLE0_COUNTER => "L0",
		ENABLE1_COUNTER => "L0",
		ENABLE_SWITCH_OVER_COUNTER => "OFF",
		EXTCLK0_COUNTER => "E0",
		EXTCLK0_DIVIDE_BY => 1,
		EXTCLK0_DUTY_CYCLE => 50,
		EXTCLK0_MULTIPLY_BY => 1,
		EXTCLK0_PHASE_SHIFT => "0",
		EXTCLK0_TIME_DELAY => "0",
		EXTCLK1_COUNTER => "E1",
		EXTCLK1_DIVIDE_BY => 1,
		EXTCLK1_DUTY_CYCLE => 50,
		EXTCLK1_MULTIPLY_BY => 1,
		EXTCLK1_PHASE_SHIFT => "0",
		EXTCLK1_TIME_DELAY => "0",
		EXTCLK2_COUNTER => "E2",
		EXTCLK2_DIVIDE_BY => 1,
		EXTCLK2_DUTY_CYCLE => 50,
		EXTCLK2_MULTIPLY_BY => 1,
		EXTCLK2_PHASE_SHIFT => "0",
		EXTCLK2_TIME_DELAY => "0",
		EXTCLK3_COUNTER => "E3",
		EXTCLK3_DIVIDE_BY => 1,
		EXTCLK3_DUTY_CYCLE => 50,
		EXTCLK3_MULTIPLY_BY => 1,
		EXTCLK3_PHASE_SHIFT => "0",
		EXTCLK3_TIME_DELAY => "0",
		FEEDBACK_SOURCE => "EXTCLK0",
		G0_HIGH => 1,
		G0_INITIAL => 1,
		G0_LOW => 1,
		G0_MODE => "BYPASS",
		G0_PH => 0,
		G0_TIME_DELAY => 0,
		G1_HIGH => 1,
		G1_INITIAL => 1,
		G1_LOW => 1,
		G1_MODE => "BYPASS",
		G1_PH => 0,
		G1_TIME_DELAY => 0,
		G2_HIGH => 1,
		G2_INITIAL => 1,
		G2_LOW => 1,
		G2_MODE => "BYPASS",
		G2_PH => 0,
		G2_TIME_DELAY => 0,
		G3_HIGH => 1,
		G3_INITIAL => 1,
		G3_LOW => 1,
		G3_MODE => "BYPASS",
		G3_PH => 0,
		G3_TIME_DELAY => 0,
		GATE_LOCK_COUNTER => 0,
		GATE_LOCK_SIGNAL => "NO",
		INCLK0_INPUT_FREQUENCY => 20000,
		INCLK1_INPUT_FREQUENCY => 0,
		INTENDED_DEVICE_FAMILY => "MAX 10",
		INVALID_LOCK_MULTIPLIER => 5,
		L0_HIGH => 1,
		L0_INITIAL => 1,
		L0_LOW => 1,
		L0_MODE => "BYPASS",
		L0_PH => 0,
		L0_TIME_DELAY => 0,
		L1_HIGH => 1,
		L1_INITIAL => 1,
		L1_LOW => 1,
		L1_MODE => "BYPASS",
		L1_PH => 0,
		L1_TIME_DELAY => 0,
		LOCK_HIGH => 1,
		LOCK_LOW => 1,
		LOCK_WINDOW_UI => " 0.05",
		LOOP_FILTER_C => 5,
		LOOP_FILTER_C_BITS => 9999,
		LOOP_FILTER_R => " 1.000000",
		LOOP_FILTER_R_BITS => 9999,
		M => 0,
		M2 => 1,
		M_INITIAL => 0,
		M_PH => 0,
		M_TEST_SOURCE => 5,
		M_TIME_DELAY => 0,
		N => 1,
		N2 => 1,
		N_TIME_DELAY => 0,
		OPERATION_MODE => "NORMAL",
		PFD_MAX => 0,
		PFD_MIN => 0,
		PLL_TYPE => "AUTO",
		PORT_ACTIVECLOCK => "PORT_UNUSED",
		PORT_ARESET => "PORT_USED",
		PORT_CLK0 => "PORT_USED",
		PORT_CLK1 => "PORT_USED",
		PORT_CLK2 => "PORT_USED",
		PORT_CLK3 => "PORT_USED",
		PORT_CLK4 => "PORT_USED",
		PORT_CLK5 => "PORT_UNUSED",
		PORT_CLK6 => "PORT_UNUSED",
		PORT_CLK7 => "PORT_UNUSED",
		PORT_CLK8 => "PORT_UNUSED",
		PORT_CLK9 => "PORT_UNUSED",
		PORT_CLKBAD0 => "PORT_UNUSED",
		PORT_CLKBAD1 => "PORT_UNUSED",
		PORT_CLKENA0 => "PORT_UNUSED",
		PORT_CLKENA1 => "PORT_UNUSED",
		PORT_CLKENA2 => "PORT_UNUSED",
		PORT_CLKENA3 => "PORT_UNUSED",
		PORT_CLKENA4 => "PORT_UNUSED",
		PORT_CLKENA5 => "PORT_UNUSED",
		PORT_CLKLOSS => "PORT_UNUSED",
		PORT_CLKSWITCH => "PORT_UNUSED",
		PORT_CONFIGUPDATE => "PORT_UNUSED",
		PORT_ENABLE0 => "PORT_CONNECTIVITY",
		PORT_ENABLE1 => "PORT_CONNECTIVITY",
		PORT_EXTCLK0 => "PORT_UNUSED",
		PORT_EXTCLK1 => "PORT_UNUSED",
		PORT_EXTCLK2 => "PORT_UNUSED",
		PORT_EXTCLK3 => "PORT_UNUSED",
		PORT_EXTCLKENA0 => "PORT_CONNECTIVITY",
		PORT_EXTCLKENA1 => "PORT_CONNECTIVITY",
		PORT_EXTCLKENA2 => "PORT_CONNECTIVITY",
		PORT_EXTCLKENA3 => "PORT_CONNECTIVITY",
		PORT_FBIN => "PORT_UNUSED",
		PORT_FBOUT => "PORT_CONNECTIVITY",
		PORT_INCLK0 => "PORT_USED",
		PORT_INCLK1 => "PORT_UNUSED",
		PORT_LOCKED => "PORT_USED",
		PORT_PFDENA => "PORT_UNUSED",
		PORT_PHASECOUNTERSELECT => "PORT_USED",
		PORT_PHASEDONE => "PORT_USED",
		PORT_PHASESTEP => "PORT_USED",
		PORT_PHASEUPDOWN => "PORT_USED",
		PORT_PLLENA => "PORT_UNUSED",
		PORT_SCANACLR => "PORT_UNUSED",
		PORT_SCANCLK => "PORT_USED",
		PORT_SCANCLKENA => "PORT_UNUSED",
		PORT_SCANDATA => "PORT_UNUSED",
		PORT_SCANDATAOUT => "PORT_UNUSED",
		PORT_SCANDONE => "PORT_UNUSED",
		PORT_SCANREAD => "PORT_UNUSED",
		PORT_SCANWRITE => "PORT_UNUSED",
		PORT_SCLKOUT0 => "PORT_CONNECTIVITY",
		PORT_SCLKOUT1 => "PORT_CONNECTIVITY",
		PORT_VCOOVERRANGE => "PORT_CONNECTIVITY",
		PORT_VCOUNDERRANGE => "PORT_CONNECTIVITY",
		PRIMARY_CLOCK => "INCLK0",
		QUALIFY_CONF_DONE => "OFF",
		SCAN_CHAIN => "LONG",
		SCLKOUT0_PHASE_SHIFT => "0",
		SCLKOUT1_PHASE_SHIFT => "0",
		SELF_RESET_ON_GATED_LOSS_LOCK => "OFF",
		SELF_RESET_ON_LOSS_LOCK => "OFF",
		SIM_GATE_LOCK_DEVICE_BEHAVIOR => "OFF",
		SKIP_VCO => "OFF",
		SPREAD_FREQUENCY => 0,
		SS => 1,
		SWITCH_OVER_COUNTER => 0,
		SWITCH_OVER_ON_GATED_LOCK => "OFF",
		SWITCH_OVER_ON_LOSSCLK => "OFF",
		SWITCH_OVER_TYPE => "AUTO",
		USING_FBMIMICBIDIR_PORT => "OFF",
		VALID_LOCK_MULTIPLIER => 1,
		VCO_CENTER => 0,
		VCO_DIVIDE_BY => 0,
		VCO_FREQUENCY_CONTROL => "MANUAL_PHASE",
		VCO_MAX => 0,
		VCO_MIN => 0,
		VCO_MULTIPLY_BY => 0,
		VCO_PHASE_SHIFT_STEP => 104,
		VCO_POST_SCALE => 0,
		WIDTH_CLOCK => 5,
		WIDTH_PHASECOUNTERSELECT => 3
	  )
	  PORT MAP ( 
		areset => wire_ddr3_mem_pll0_altpll_upll_memphy_105_areset,
		clk => wire_ddr3_mem_pll0_altpll_upll_memphy_105_clk,
		clkena => wire_ddr3_mem_pll0_altpll_upll_memphy_105_clkena,
		clkswitch => wire_gnd,
		configupdate => wire_gnd,
		extclkena => wire_ddr3_mem_pll0_altpll_upll_memphy_105_extclkena,
		fbin => wire_vcc,
		inclk => wire_ddr3_mem_pll0_altpll_upll_memphy_105_inclk,
		locked => wire_ddr3_mem_pll0_altpll_upll_memphy_105_locked,
		pfdena => wire_vcc,
		phasecounterselect => wire_ddr3_mem_pll0_altpll_upll_memphy_105_phasecounterselect,
		phasedone => wire_ddr3_mem_pll0_altpll_upll_memphy_105_phasedone,
		phasestep => phasestep,
		phaseupdown => phaseupdown,
		pllena => wire_vcc,
		scanaclr => wire_gnd,
		scanclk => scanclk,
		scanclkena => wire_vcc,
		scandata => wire_gnd,
		scanread => wire_gnd,
		scanwrite => wire_gnd
	  );

 END RTL; --ddr3_mem_pll0
--synopsys translate_on
--VALID FILE
