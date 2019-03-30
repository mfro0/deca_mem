-- ddr3_mem.vhd

-- Generated using ACDS version 18.1 625

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ddr3_mem is
	port (
		pll_ref_clk        : in    std_logic                     := '0';             --      pll_ref_clk.clk
		global_reset_n     : in    std_logic                     := '0';             --     global_reset.reset_n
		soft_reset_n       : in    std_logic                     := '0';             --       soft_reset.reset_n
		afi_clk            : out   std_logic;                                        --          afi_clk.clk
		afi_half_clk       : out   std_logic;                                        --     afi_half_clk.clk
		afi_reset_n        : out   std_logic;                                        --        afi_reset.reset_n
		afi_reset_export_n : out   std_logic;                                        -- afi_reset_export.reset_n
		mem_a              : out   std_logic_vector(14 downto 0);                    --           memory.mem_a
		mem_ba             : out   std_logic_vector(2 downto 0);                     --                 .mem_ba
		mem_ck             : inout std_logic_vector(0 downto 0)  := (others => '0'); --                 .mem_ck
		mem_ck_n           : inout std_logic_vector(0 downto 0)  := (others => '0'); --                 .mem_ck_n
		mem_cke            : out   std_logic_vector(0 downto 0);                     --                 .mem_cke
		mem_cs_n           : out   std_logic_vector(0 downto 0);                     --                 .mem_cs_n
		mem_dm             : out   std_logic_vector(1 downto 0);                     --                 .mem_dm
		mem_ras_n          : out   std_logic_vector(0 downto 0);                     --                 .mem_ras_n
		mem_cas_n          : out   std_logic_vector(0 downto 0);                     --                 .mem_cas_n
		mem_we_n           : out   std_logic_vector(0 downto 0);                     --                 .mem_we_n
		mem_reset_n        : out   std_logic;                                        --                 .mem_reset_n
		mem_dq             : inout std_logic_vector(15 downto 0) := (others => '0'); --                 .mem_dq
		mem_dqs            : inout std_logic_vector(1 downto 0)  := (others => '0'); --                 .mem_dqs
		mem_dqs_n          : inout std_logic_vector(1 downto 0)  := (others => '0'); --                 .mem_dqs_n
		mem_odt            : out   std_logic_vector(0 downto 0);                     --                 .mem_odt
		avl_ready          : out   std_logic;                                        --              avl.waitrequest_n
		avl_burstbegin     : in    std_logic                     := '0';             --                 .beginbursttransfer
		avl_addr           : in    std_logic_vector(25 downto 0) := (others => '0'); --                 .address
		avl_rdata_valid    : out   std_logic;                                        --                 .readdatavalid
		avl_rdata          : out   std_logic_vector(63 downto 0);                    --                 .readdata
		avl_wdata          : in    std_logic_vector(63 downto 0) := (others => '0'); --                 .writedata
		avl_be             : in    std_logic_vector(7 downto 0)  := (others => '0'); --                 .byteenable
		avl_read_req       : in    std_logic                     := '0';             --                 .read
		avl_write_req      : in    std_logic                     := '0';             --                 .write
		avl_size           : in    std_logic_vector(2 downto 0)  := (others => '0'); --                 .burstcount
		local_init_done    : out   std_logic;                                        --           status.local_init_done
		local_cal_success  : out   std_logic;                                        --                 .local_cal_success
		local_cal_fail     : out   std_logic;                                        --                 .local_cal_fail
		pll_mem_clk        : out   std_logic;                                        --      pll_sharing.pll_mem_clk
		pll_write_clk      : out   std_logic;                                        --                 .pll_write_clk
		pll_locked         : out   std_logic;                                        --                 .pll_locked
		pll_capture0_clk   : out   std_logic;                                        --                 .pll_capture0_clk
		pll_capture1_clk   : out   std_logic                                         --                 .pll_capture1_clk
	);
end entity ddr3_mem;

architecture rtl of ddr3_mem is
	component ddr3_mem_0002 is
		port (
			pll_ref_clk        : in    std_logic                     := 'X';             -- clk
			global_reset_n     : in    std_logic                     := 'X';             -- reset_n
			soft_reset_n       : in    std_logic                     := 'X';             -- reset_n
			afi_clk            : out   std_logic;                                        -- clk
			afi_half_clk       : out   std_logic;                                        -- clk
			afi_reset_n        : out   std_logic;                                        -- reset_n
			afi_reset_export_n : out   std_logic;                                        -- reset_n
			mem_a              : out   std_logic_vector(14 downto 0);                    -- mem_a
			mem_ba             : out   std_logic_vector(2 downto 0);                     -- mem_ba
			mem_ck             : inout std_logic_vector(0 downto 0)  := (others => 'X'); -- mem_ck
			mem_ck_n           : inout std_logic_vector(0 downto 0)  := (others => 'X'); -- mem_ck_n
			mem_cke            : out   std_logic_vector(0 downto 0);                     -- mem_cke
			mem_cs_n           : out   std_logic_vector(0 downto 0);                     -- mem_cs_n
			mem_dm             : out   std_logic_vector(1 downto 0);                     -- mem_dm
			mem_ras_n          : out   std_logic_vector(0 downto 0);                     -- mem_ras_n
			mem_cas_n          : out   std_logic_vector(0 downto 0);                     -- mem_cas_n
			mem_we_n           : out   std_logic_vector(0 downto 0);                     -- mem_we_n
			mem_reset_n        : out   std_logic;                                        -- mem_reset_n
			mem_dq             : inout std_logic_vector(15 downto 0) := (others => 'X'); -- mem_dq
			mem_dqs            : inout std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs
			mem_dqs_n          : inout std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs_n
			mem_odt            : out   std_logic_vector(0 downto 0);                     -- mem_odt
			avl_ready          : out   std_logic;                                        -- waitrequest_n
			avl_burstbegin     : in    std_logic                     := 'X';             -- beginbursttransfer
			avl_addr           : in    std_logic_vector(25 downto 0) := (others => 'X'); -- address
			avl_rdata_valid    : out   std_logic;                                        -- readdatavalid
			avl_rdata          : out   std_logic_vector(63 downto 0);                    -- readdata
			avl_wdata          : in    std_logic_vector(63 downto 0) := (others => 'X'); -- writedata
			avl_be             : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- byteenable
			avl_read_req       : in    std_logic                     := 'X';             -- read
			avl_write_req      : in    std_logic                     := 'X';             -- write
			avl_size           : in    std_logic_vector(2 downto 0)  := (others => 'X'); -- burstcount
			local_init_done    : out   std_logic;                                        -- local_init_done
			local_cal_success  : out   std_logic;                                        -- local_cal_success
			local_cal_fail     : out   std_logic;                                        -- local_cal_fail
			pll_mem_clk        : out   std_logic;                                        -- pll_mem_clk
			pll_write_clk      : out   std_logic;                                        -- pll_write_clk
			pll_locked         : out   std_logic;                                        -- pll_locked
			pll_capture0_clk   : out   std_logic;                                        -- pll_capture0_clk
			pll_capture1_clk   : out   std_logic                                         -- pll_capture1_clk
		);
	end component ddr3_mem_0002;

begin

	ddr3_mem_inst : component ddr3_mem_0002
		port map (
			pll_ref_clk        => pll_ref_clk,        --      pll_ref_clk.clk
			global_reset_n     => global_reset_n,     --     global_reset.reset_n
			soft_reset_n       => soft_reset_n,       --       soft_reset.reset_n
			afi_clk            => afi_clk,            --          afi_clk.clk
			afi_half_clk       => afi_half_clk,       --     afi_half_clk.clk
			afi_reset_n        => afi_reset_n,        --        afi_reset.reset_n
			afi_reset_export_n => afi_reset_export_n, -- afi_reset_export.reset_n
			mem_a              => mem_a,              --           memory.mem_a
			mem_ba             => mem_ba,             --                 .mem_ba
			mem_ck             => mem_ck,             --                 .mem_ck
			mem_ck_n           => mem_ck_n,           --                 .mem_ck_n
			mem_cke            => mem_cke,            --                 .mem_cke
			mem_cs_n           => mem_cs_n,           --                 .mem_cs_n
			mem_dm             => mem_dm,             --                 .mem_dm
			mem_ras_n          => mem_ras_n,          --                 .mem_ras_n
			mem_cas_n          => mem_cas_n,          --                 .mem_cas_n
			mem_we_n           => mem_we_n,           --                 .mem_we_n
			mem_reset_n        => mem_reset_n,        --                 .mem_reset_n
			mem_dq             => mem_dq,             --                 .mem_dq
			mem_dqs            => mem_dqs,            --                 .mem_dqs
			mem_dqs_n          => mem_dqs_n,          --                 .mem_dqs_n
			mem_odt            => mem_odt,            --                 .mem_odt
			avl_ready          => avl_ready,          --              avl.waitrequest_n
			avl_burstbegin     => avl_burstbegin,     --                 .beginbursttransfer
			avl_addr           => avl_addr,           --                 .address
			avl_rdata_valid    => avl_rdata_valid,    --                 .readdatavalid
			avl_rdata          => avl_rdata,          --                 .readdata
			avl_wdata          => avl_wdata,          --                 .writedata
			avl_be             => avl_be,             --                 .byteenable
			avl_read_req       => avl_read_req,       --                 .read
			avl_write_req      => avl_write_req,      --                 .write
			avl_size           => avl_size,           --                 .burstcount
			local_init_done    => local_init_done,    --           status.local_init_done
			local_cal_success  => local_cal_success,  --                 .local_cal_success
			local_cal_fail     => local_cal_fail,     --                 .local_cal_fail
			pll_mem_clk        => pll_mem_clk,        --      pll_sharing.pll_mem_clk
			pll_write_clk      => pll_write_clk,      --                 .pll_write_clk
			pll_locked         => pll_locked,         --                 .pll_locked
			pll_capture0_clk   => pll_capture0_clk,   --                 .pll_capture0_clk
			pll_capture1_clk   => pll_capture1_clk    --                 .pll_capture1_clk
		);

end architecture rtl; -- of ddr3_mem
