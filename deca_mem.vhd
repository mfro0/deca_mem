library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library ddr3_mem;

entity deca_mem is
    port
    (
        -- clocks
        ADC_CLK_10          : in std_logic;
        MAX10_CLK1_50       : in std_logic;
        MAX10_CLK2_50       : in std_logic;
        
        -- keys
        KEY                 : in std_logic_vector(1 downto 0);
        
        -- LEDs
        LED                 : out std_logic_vector(7 downto 0);
        
        -- CapSense button
        CAP_SENSE_I2C_SCL   : inout std_logic;
        CAP_SENSE_I2C_SDA   : inout std_logic;
        
        -- Audio
        AUDIO_BCLK          : inout std_logic;
        AUDIO_DIN_MFP1      : out std_logic;
        AUDIO_DOUT_MFP2     : in std_logic;
        AUDIO_GPIO_MFP5     : inout std_logic;
        AUDIO_MCLK          : out std_logic;
        AUDIO_MISO_MFP4     : in std_logic;
        AUDIO_RESET_n       : in std_logic;
        AUDIO_SCL_SS_n      : out std_logic;
        AUDIO_SCLK_MFP3     : out std_logic;
        AUDIO_SDA_MOSI      : inout std_logic;
        AUDIO_SPI_SELECT    : out std_logic;
        AUDIO_WCLK          : inout std_logic;
        
        -- SDRAM
        DDR3_A              : out std_logic_vector(14 downto 0);
        DDR3_BA             : out std_logic_vector(2 downto 0);
        DDR3_CAS_n          : out std_logic;
        DDR3_CK_n           : inout std_logic;
        DDR3_CK_p           : inout std_logic;
        DDR3_CKE            : out std_logic;
        DDR3_CLK_50         : in std_logic;
        DDR3_CS_n           : out std_logic;
        DDR3_DM             : out std_logic_vector(1 downto 0);
        DDR3_DQ             : inout std_logic_vector(15 downto 0);
        DDR3_DQS_n          : inout std_logic_vector(1 downto 0);
        DDR3_DQS_p          : inout std_logic_vector(1 downto 0);
        DDR3_ODT            : out std_logic;
        DDR3_RAS_n          : out std_logic;
        DDR3_RESET_n        : out std_logic;
        DDR3_WE_n           : out std_logic;
        
        -- FLASH
        FLASH_DATA          : inout std_logic_vector(3 downto 0);
        FLASH_DCLK          : out std_logic;
        FLASH_NCSO          : out std_logic;
        FLASH_RESET_n       : out std_logic;
        
        -- G-Sensor
        G_SENSOR_CS_n       : out std_logic;
        G_SENSOR_INT1       : in std_logic;
        G_SENSOR_INT2       : in std_logic;
        G_SENSOR_SCLK       : inout std_logic;
        G_SENSOR_SDI        : inout std_logic;
        G_SENSOR_SDO        : inout std_logic;
        
        -- HDMI TX
        HDMI_I2C_SCL        : inout std_logic;
        HDMI_I2C_SDA        : inout std_logic;
        HDMI_I2S            : inout std_logic_vector(3 downto 0);
        HDMI_LRCLK          : inout std_logic;
        HDMI_MCLK           : inout std_logic;
        HDMI_SCLK           : inout std_logic;
        HDMI_TXCLK          : out std_logic;
        HDMI_TX_D           : out std_logic_vector(23 downto 0);
        HDMI_TX_DE          : out std_logic;
        HDMI_TX_HS          : out std_logic;
        HDMI_TX_INT         : in std_logic;
        HDMI_TX_VS          : out std_logic;
        
        -- light sensor
        LIGHT_I2C_SCL       : out std_logic;
        LIGHT_I2C_SDA       : inout std_logic;
        LIGHT_INT           : inout std_logic;
        
        -- MIPI
        MIPI_CORE_ENV       : out std_logic;
        MIPI_I2C_SCL        : out std_logic;
        MIPI_I2C_SDA        : inout std_logic;
        MIPI_LP_MC_n        : in std_logic;
        MIPI_LP_MC_p        : in std_logic;
        MIPI_LP_MD_n        : in std_logic_vector(3 downto 0);
        MIPI_LP_MD_p        : in std_logic_vector(3 downto 0);
        MIPI_MC_p           : in std_logic;
        MIPI_MCLK           : out std_logic;
        MIPI_MD_p           : in std_logic_vector(3 downto 0);
        MIPI_RESET_n        : out std_logic;
        MIPI_WP             : out std_logic;
        
        -- Ethernet
        NET_COL             : in std_logic;
        NET_CRS             : in std_logic;
        NET_MDC             : out std_logic;
        NET_MDIO            : inout std_logic;
        NET_PCF_EN          : out std_logic;
        NET_RESET_n         : out std_logic;
        NET_RX_CLK          : in std_logic;
        NET_RX_DV           : in std_logic;
        NET_RX_ER           : in std_logic;
        NET_RXD             : in std_logic_vector(3 downto 0);
        NET_TX_CLK          : in std_logic;
        NET_TX_EN           : out std_logic;
        NET_TXD             : out std_logic_vector(3 downto 0);
        
        -- power monitor
        PMONITOR_ALERT      : in std_logic;
        PMONITOR_I2C_SCL    : out std_logic;
        PMONITOR_I2C_SDA    : inout std_logic;
        
        -- humidity and temperature sensor
        RH_TEMP_DRDY_n      : in std_logic;
        RH_TEMP_I2C_SCL     : out std_logic;
        RH_TEMP_I2C_SDA     : in std_logic;
        
        -- Micro SD card
        SD_CLK              : out std_logic;
        SD_CMD              : inout std_logic;
        SD_CMD_DIR          : out std_logic;
        SD_D0_DIR           : out std_logic;
        SD_D123_DIR         : out std_logic;
        SD_DAT              : inout std_logic_vector(3 downto 0);
        SD_FB_CLK           : in std_logic;
        SD_SEL              : out std_logic;
        
        -- switches
        SW                  : in std_logic_vector(1 downto 0);
        
        -- board temperature sensor
        TEMP_CS_n           : out std_logic;
        TEMP_SC             : out std_logic;
        TEMP_SIO            : inout std_logic;
        
        -- USB
        USB_CLKIN           : in std_logic;
        USB_CS              : out std_logic;
        USB_DATA            : inout std_logic_vector(7 downto 0);
        USB_DIR             : in std_logic;
        USB_FAULT_n         : in std_logic;
        USB_NXT             : in std_logic;
        USB_RESET_n         : out std_logic;
        USB_STP             : out std_logic;
        
        -- BBB connector
        BBB_PWR_BUT         : in std_logic;
        BBB_SYS_RESET_n     : in std_logic;
        GPIO0_D             : inout std_logic_vector(43 downto 0);
        GPIO1_D             : inout std_logic_vector(22 DOWNTO 0)
    );
end entity deca_mem;

architecture rtl of deca_mem is
    signal reset_n                  : std_ulogic := '0';
    signal ddr3_pll_locked          : std_logic;
    signal ddr3_local_init_done     : std_logic;
    signal ddr3_local_cal_success   : std_logic;
    signal ddr3_local_cal_fail      : std_logic;
    
    signal clk_100,
           clk_125,
           clk_150,
           clk_175,
           clk_200                  : std_ulogic;
    signal pll_locked               : std_ulogic;
    
    signal afi_clk                  : std_ulogic;
    signal afi_half_clk             : std_ulogic;
    signal afi_reset_n              : std_ulogic;
    signal afi_reset_export_n       : std_ulogic;
    
    signal avl_ready                : std_ulogic;
    signal avl_burstbegin           : std_ulogic;
    signal avl_addr                 : std_logic_vector(25 downto 0);
    signal avl_rdata_valid          : std_ulogic;
    signal avl_rdata                : std_logic_vector(63 downto 0);
    signal avl_wdata                : std_logic_vector(63 downto 0);
    signal avl_be                   : std_logic_vector(7 downto 0);
    signal avl_read_req             : std_ulogic;
    signal avl_write_req            : std_ulogic;
    signal avl_size                 : std_logic_vector(2 downto 0);
    
    signal ddr3_init_done,
           ddr3_cal_success,
           ddr3_cal_fail,
           ddr3_mem_clk,
           ddr3_write_clk,
           ddr3_capture0_clk,
           ddr3_capture1_clk        : std_ulogic;
    
begin
    i_reset_circuit : entity work.deca_reset
        generic map
        (
            TICKS           => 100
        )
        port map
        (
            clk             => MAX10_CLK1_50,
            reset_n         => reset_n,
            lock_pll        => pll_locked
        );
        
    i_clocks : entity work.deca_clocks
        port map
        (
            clk             => MAX10_CLK1_50,
            reset_n         => reset_n,
            clk_100         => clk_100,
            clk_125         => clk_125,
            clk_150         => clk_150,
            clk_175         => clk_175,
            clk_200         => clk_200,
            locked          => pll_locked
        );

	i_ddr3_memory : entity ddr3_mem.ddr3_mem
		port map
		(
            pll_ref_clk         => MAX10_CLK1_50,
            global_reset_n      => reset_n,
            soft_reset_n        => reset_n,
            afi_clk             => afi_clk,
            afi_half_clk        => afi_half_clk,
            afi_reset_n         => afi_reset_n,
            afi_reset_export_n  => afi_reset_export_n,
            
            mem_a               => DDR3_A,
            mem_ba              => DDR3_BA,
            mem_ck(0)           => DDR3_CK_p,
            mem_ck_n(0)         => DDR3_CK_n,
            mem_cke(0)          => DDR3_CKE,
            mem_cs_n(0)         => DDR3_CS_n,
            mem_dm              => DDR3_DM,
            mem_ras_n(0)        => DDR3_RAS_n,
            mem_cas_n(0)        => DDR3_CAS_n,
            mem_we_n(0)         => DDR3_WE_n,
            mem_reset_n         => DDR3_reset_n,
            mem_dq              => DDR3_DQ,
            mem_dqs             => DDR3_DQS_p,
            mem_dqs_n           => DDR3_DQS_n,
            mem_odt(0)          => DDR3_ODT,
            
            avl_ready           => avl_ready,
            avl_burstbegin      => avl_burstbegin,
            avl_addr            => avl_addr,
            avl_rdata_valid     => avl_rdata_valid,
            avl_rdata           => avl_rdata,
            avl_wdata           => avl_wdata,
            avl_be              => avl_be,
            avl_read_req        => avl_read_req,
            avl_write_req       => avl_write_req,
            avl_size            => avl_size,
            
            local_init_done     => ddr3_init_done,
            local_cal_success   => ddr3_cal_success,
            local_cal_fail      => ddr3_cal_fail,
            
            pll_mem_clk         => ddr3_mem_clk,
            pll_write_clk       => ddr3_write_clk,
            pll_locked          => ddr3_pll_locked,
            pll_capture0_clk    => ddr3_capture0_clk,
            pll_capture1_clk    => ddr3_capture1_clk
        );
            
end architecture rtl;