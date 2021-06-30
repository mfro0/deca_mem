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
        DDR3_A              : out std_ulogic_vector(14 downto 0);
        DDR3_BA             : out std_ulogic_vector(2 downto 0);
        DDR3_CAS_n          : out std_ulogic;
        DDR3_CK_n           : inout std_ulogic;
        DDR3_CK_p           : inout std_ulogic;
        DDR3_CKE            : out std_ulogic;
        DDR3_CLK_50         : in std_ulogic;
        DDR3_CS_n           : out std_ulogic;
        DDR3_DM             : out std_ulogic_vector(1 downto 0);
        DDR3_DQ             : inout std_ulogic_vector(15 downto 0);
        DDR3_DQS_n          : inout std_ulogic_vector(1 downto 0);
        DDR3_DQS_p          : inout std_ulogic_vector(1 downto 0);
        DDR3_ODT            : out std_ulogic;
        DDR3_RAS_n          : out std_ulogic;
        DDR3_RESET_n        : out std_ulogic;
        DDR3_WE_n           : out std_ulogic;

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
        HDMI_TX_CLK         : out std_ulogic;
        HDMI_TX_D           : out std_ulogic_vector(23 downto 0);
        HDMI_TX_DE          : out std_ulogic;
        HDMI_TX_HS          : out std_ulogic;
        HDMI_TX_INT         : in std_ulogic;
        HDMI_TX_VS          : out std_ulogic;

        -- light sensor
        LIGHT_I2C_SCL       : out std_ulogic;
        LIGHT_I2C_SDA       : inout std_ulogic;
        LIGHT_INT           : inout std_ulogic;

        -- MIPI (Mobile Industry Processor Interface) camera module
        MIPI_CORE_EN        : out std_ulogic;
        MIPI_I2C_SCL        : out std_ulogic;
        MIPI_I2C_SDA        : inout std_ulogic;
        MIPI_LP_MC_n        : in std_ulogic;
        MIPI_LP_MC_p        : in std_ulogic;
        MIPI_LP_MD_n        : in std_ulogic_vector(3 downto 0);
        MIPI_LP_MD_p        : in std_ulogic_vector(3 downto 0);
        MIPI_MC_p           : in std_ulogic;
        MIPI_MCLK           : out std_ulogic;
        MIPI_MD_p           : in std_ulogic_vector(3 downto 0);
        MIPI_RESET_n        : out std_ulogic;
        MIPI_WP             : out std_ulogic;

        -- Ethernet
        NET_COL             : in std_ulogic;
        NET_CRS             : in std_ulogic;
        NET_MDC             : out std_ulogic;
        NET_MDIO            : inout std_ulogic;
        NET_PCF_EN          : out std_ulogic;
        NET_RESET_n         : out std_ulogic;
        NET_RX_CLK          : in std_ulogic;
        NET_RX_DV           : in std_ulogic;
        NET_RX_ER           : in std_ulogic;
        NET_RXD             : in std_ulogic_vector(3 downto 0);
        NET_TX_CLK          : in std_ulogic;
        NET_TX_EN           : out std_ulogic;
        NET_TXD             : out std_ulogic_vector(3 downto 0);

        -- power monitor
        PMONITOR_ALERT      : in std_ulogic;
        PMONITOR_I2C_SCL    : out std_ulogic;
        PMONITOR_I2C_SDA    : inout std_ulogic;

        -- humidity and temperature sensor
        RH_TEMP_DRDY_n      : in std_ulogic;
        RH_TEMP_I2C_SCL     : out std_ulogic;
        RH_TEMP_I2C_SDA     : in std_ulogic;

        -- Micro SD card
        SD_CLK              : out std_ulogic;
        SD_CMD              : inout std_ulogic;
        SD_CMD_DIR          : out std_ulogic;
        SD_D0_DIR           : out std_ulogic;
        SD_D123_DIR         : out std_ulogic;
        SD_DAT              : inout std_ulogic_vector(3 downto 0);
        SD_FB_CLK           : in std_ulogic;
        SD_SEL              : out std_ulogic;

        -- switches
        SW                  : in std_ulogic_vector(1 downto 0);

        -- board temperature sensor
        TEMP_CS_n           : out std_ulogic;
        TEMP_SC             : out std_ulogic;
        TEMP_SIO            : inout std_ulogic;

        -- USB
        USB_CLKIN           : in std_ulogic;
        USB_CS              : out std_ulogic;
        USB_DATA            : inout std_ulogic_vector(7 downto 0);
        USB_DIR             : in std_ulogic;
        USB_FAULT_n         : in std_ulogic;
        USB_NXT             : in std_ulogic;
        USB_RESET_n         : out std_ulogic;
        USB_STP             : out std_ulogic;

        -- BBB connector
        BBB_PWR_BUT         : in std_ulogic;
        BBB_SYS_RESET_n     : in std_ulogic;
        GPIO0_D             : inout std_ulogic_vector(43 downto 0);
        GPIO1_D             : inout std_ulogic_vector(22 downto 0)
    );
end entity deca_mem;

architecture rtl of deca_mem is
    signal reset_n                  : std_ulogic := '0';
    signal ddr3_pll_locked          : std_ulogic;
    signal ddr3_local_init_done     : std_ulogic;
    signal ddr3_local_cal_success   : std_ulogic;
    signal ddr3_local_cal_fail      : std_ulogic;

    signal clk_1536k                : std_ulogic;
    signal pll_locked               : std_ulogic := '1';

    signal afi_clk                  : std_ulogic;
    signal afi_half_clk             : std_ulogic;
    signal afi_reset_n              : std_ulogic;
    signal afi_reset_export_n       : std_ulogic;

    signal avl_ready                : std_ulogic;
    signal avl_burstbegin           : std_ulogic;
    signal avl_addr                 : std_ulogic_vector(25 downto 0);
    signal avl_rdata_valid          : std_ulogic;
    signal avl_rdata                : std_ulogic_vector(63 downto 0);
    signal avl_wdata                : std_ulogic_vector(63 downto 0);
    signal avl_be                   : std_ulogic_vector(7 downto 0);
    signal avl_read_req             : std_ulogic;
    signal avl_write_req            : std_ulogic;
    signal avl_size                 : std_ulogic_vector(2 downto 0);

    signal ddr3_init_done,
           ddr3_cal_success,
           ddr3_cal_fail,
           ddr3_mem_clk,
           ddr3_write_clk,
           ddr3_capture0_clk,
           ddr3_capture1_clk        : std_ulogic := '0';
    signal button_reset_n           : std_ulogic := '0';
    signal blinker                  : std_ulogic := '0';
    signal i2c_ack_err              : std_ulogic := '0';
    signal i2c_verify_start         : std_ulogic := '0';
    signal i2c_verify_button        : std_ulogic;

    signal hdmi_configured          : std_ulogic := '0';

begin
    i_blinker : entity work.blinker
        generic map
        (
            CLK_FREQUENCY       => 50_000_000,
            BLINKS_PER_SECOND   => 5
        )
        port map
        (
            clk                 => MAX10_CLK1_50,
            reset_n             => reset_n,
            led                 => blinker
        );

    i_reset_circuit : entity work.deca_reset
        generic map
        (
            WAIT_TICKS          => 1000
        )
        port map
        (
            clk                 => MAX10_CLK1_50,
            reset_n             => reset_n,
            reset_button_n      => button_reset_n,
            lock_pll            => pll_locked
        );

    i_clocks : entity work.deca_clocks
        port map
        (
            clk                 => MAX10_CLK1_50,
            reset_n             => reset_n,
            clk_1536k           => clk_1536k,
            locked              => pll_locked
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

    i_hdmi_tx : entity work.hdmi_tx
        generic map
        (
            CLK_FREQUENCY       => 50_000_000,
            I2C_FREQUENCY       =>    400_000
        )
        port map
        (
            clk_50              => MAX10_CLK1_50,
            reset_n             => reset_n,

            hdmi_i2c_scl        => HDMI_I2C_SCL,
            hdmi_i2c_sda        => HDMI_I2C_SDA,
            hdmi_i2s            => HDMI_I2S,
            hdmi_lrclk          => HDMI_LRCLK,
            hdmi_mclk           => HDMI_MCLK,
            hdmi_sclk           => HDMI_SCLK,
            hdmi_tx_clk         => HDMI_TX_CLK,
            hdmi_tx_d           => HDMI_TX_D,
            hdmi_tx_de          => HDMI_TX_DE,
            hdmi_tx_hs          => HDMI_TX_HS,
            hdmi_tx_int         => HDMI_TX_INT,
            hdmi_tx_vs          => HDMI_TX_VS,

            hdmi_configured     => hdmi_configured,
            ack_error           => i2c_ack_err,
            i2c_verify_start    => i2c_verify_start,
            reset_button_n      => KEY(1)
        );

    i_hdmi_audio : entity work.hdmi_audio
        generic map
        (
            clk_frequency       => 50_000_000,
            sclk_frequency      => 50_000_000 / 16
        )
        port map
        (
            clk                 => clk_1536k,
            reset_n             => reset_n,

            sclk                => HDMI_SCLK,
            lrclk               => HDMI_LRCLK,
            i2s                 => HDMI_I2S
        );

    i_reset_button : entity work.sync_button
        port map
        (
            clk                 => MAX10_CLK1_50,
            button              => KEY(0),
            button_out_n        => button_reset_n
        );


    i_i2c_verify_button : entity work.sync_button
        port map
        (
            clk                 => MAX10_CLK1_50,
            button              => KEY(1),
            button_out_n        => i2c_verify_button
        );

    b_video_fifo : block
        signal video_fifo_aclr  : std_ulogic;
        signal video_clk        : std_ulogic;
        signal video_rdrq       : std_ulogic;
        signal video_wrclk      : std_ulogic;
        signal video_data       : std_ulogic_vector(23 downto 0);
        signal video_fifo_rdata : std_ulogic_vector(23 downto 0);
        signal video_fifo_empty : std_ulogic;
        signal video_fifo_full  : std_ulogic;

    begin
        i_video_fifo : entity work.video_fifo
            port map
            (
                aclr                => video_fifo_aclr,
                data                => std_logic_vector(video_fifo_rdata),
                rdclk               => video_clk,
                rdreq               => video_rdrq,
                wrclk               => afi_clk,
                wrreq               => video_wrclk,
                std_ulogic_vector(q)=> video_data,
                rdempty             => video_fifo_empty,
                wrfull              => video_fifo_full
            );
    end block b_video_fifo;

    /*
    i_cpu : entity work.simple_m68k
        port map
        (
            clk                 => MAX10_CLK1_50,
            reset_n             => reset_n,

            uart_out_ready      => uart_out_ready,
            uart_out_data       => uart_out_data,
            uart_out_start      => uart_out_start,

            uart_in_data_available  => uart_in_data_available,
            uart_in_data        => uart_in_data
        );
    */

    i2c_verify_start <= not i2c_verify_button;

    LED(0) <= button_reset_n;
    LED(1) <= reset_n;
    LED(2) <= not ddr3_cal_success;
    LED(3) <= not ddr3_cal_fail;
    LED(4) <= blinker;
    LED(5) <= not pll_locked;
    LED(6) <= not i2c_ack_err;
    LED(7) <= not hdmi_configured when reset_n = '1' else not '0';
end architecture rtl;

