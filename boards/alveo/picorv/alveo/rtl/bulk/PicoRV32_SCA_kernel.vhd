-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.design_package.all;

entity PicoRV32_SCA_kernel is
  port (
  ap_clk                : in  std_logic;
  ap_rst_n              : in  std_logic;
  -- AXI Master
  -- Dumps the BRAM content to DRAM
  m_axi_bank_0_AWADDR   : out std_logic_vector( 63 downto 0);
  m_axi_bank_0_AWLEN    : out std_logic_vector(  7 downto 0);
  m_axi_bank_0_AWSIZE   : out std_logic_vector(  2 downto 0);
  m_axi_bank_0_AWVALID  : out std_logic;
  m_axi_bank_0_AWREADY  : in  std_logic;
  m_axi_bank_0_WDATA    : out std_logic_vector(511 downto 0);
  m_axi_bank_0_WSTRB    : out std_logic_vector( 63 downto 0);
  m_axi_bank_0_WVALID   : out std_logic;
  m_axi_bank_0_WREADY   : in  std_logic;
  m_axi_bank_0_BRESP    : in  std_logic_vector(  1 downto 0);
  m_axi_bank_0_BVALID   : in  std_logic;
  m_axi_bank_0_BREADY   : out std_logic;
  -- Dumps the DRAM content to BRAM
  m_axi_bank_0_ARID     : out std_logic;
  m_axi_bank_0_ARADDR   : out std_logic_vector(63 downto 0);
  m_axi_bank_0_ARVALID  : out std_logic;
  m_axi_bank_0_ARREADY  : in  std_logic;
  m_axi_bank_0_ARLEN    : out std_logic_vector(7 downto 0);
  m_axi_bank_0_ARSIZE   : out std_logic_vector(2 downto 0);
  m_axi_bank_0_RDATA    : in  std_logic_vector(511 downto 0);
  m_axi_bank_0_RVALID   : in  std_logic;
  m_axi_bank_0_RREADY   : out std_logic;
  m_axi_bank_0_RID      : in  std_logic;
  -- AXI Lite Slave
  -- Used by the host to configure the experiments 
  s_axi_control_AWADDR  : in  std_logic_vector( 11 downto 0);
  s_axi_control_AWVALID : in  std_logic;
  s_axi_control_AWREADY : out std_logic;
  s_axi_control_WDATA   : in  std_logic_vector( 31 downto 0);
  s_axi_control_WSTRB   : in  std_logic_vector(  3 downto 0);
  s_axi_control_WVALID  : in  std_logic;
  s_axi_control_WREADY  : out std_logic;
  s_axi_control_BRESP   : out std_logic_vector(  1 downto 0);
  s_axi_control_BVALID  : out std_logic;
  s_axi_control_BREADY  : in  std_logic;
  s_axi_control_ARADDR  : in  std_logic_vector( 11 downto 0);
  s_axi_control_ARVALID : in  std_logic;
  s_axi_control_ARREADY : out std_logic;
  s_axi_control_RDATA   : out std_logic_vector( 31 downto 0);
  s_axi_control_RRESP   : out std_logic_vector(  1 downto 0);
  s_axi_control_RVALID  : out std_logic;
  s_axi_control_RREADY  : in  std_logic
  );
end PicoRV32_SCA_kernel;

architecture struct of PicoRV32_SCA_kernel is

  constant N_SENSORS_PER_BANK   : integer := 32;
  constant N_BANKS              : integer := 6;
  constant N_SENSORS            : integer := 30;
  constant IDC_SIZE             : integer := 32;
  constant IDF_SIZE             : integer := 96;
  constant CPU_MEM_SIZE         : integer := 8192;
  constant C_S00_AXI_DATA_WIDTH : integer := 32;
  constant C_S00_AXI_ADDR_WIDTH : integer := 12;
  constant N_SAMPLES            : integer := 128;
  constant SENSOR_WIDTH         : integer := 16;
  constant TRACE_BRAM_SIZE      : integer := 4096;
  
  signal cpu_clk, cpu_en, cpu_rstn, cpu_trap, cpu_trap_sync: std_logic;
  signal cpu_mem_en, cpu_mem_wen, start_load, load_idle: std_logic;
  signal cpu_mem_wen_ext : std_logic_vector(3 downto 0);
  signal cpu_mem_addr : std_logic_vector(log2(CPU_MEM_SIZE)-1 downto 0);
  signal cpu_mem_data, cpu_instruction, load_size : std_logic_vector(31 downto 0);
  
  signal sens_trg, sens_calib_trg, dump_idle, sens_rst_n : std_logic;
  signal sens_calib_val : std_logic_vector(IDC_SIZE+IDF_SIZE-1 downto 0);
  signal sens_calib_id : std_logic_vector(N_SENSORS-1 downto 0);
  signal sens_calib_bank_id : std_logic_vector(N_BANKS-1 downto 0);
  signal base_ptr : std_logic_vector(63 downto 0);
  signal dump_bank_id : std_logic_vector(31 downto 0);
  
  signal trace_bram_rdata : std_logic_vector(511 downto 0);
  signal trace_bram_raddr : std_logic_vector(log2(TRACE_BRAM_SIZE)-1 downto 0);
  signal start_dump, store_done_sync, trace_bram_ren : std_logic;
  signal store_done_array :  std_logic_vector(N_BANKS-1 downto 0);
  
  signal sens_clk : std_logic;
  signal sensor_val : std_logic_vector(N_SENSORS*SENSOR_WIDTH+32-1 downto 0);
  signal sensor_val_ext : std_logic_vector(511 downto 0);
  
  signal trace_bram_wdata, wdatab : std_logic_vector(511 downto 0);
  signal trace_bram_waddr : std_logic_vector(log2(TRACE_BRAM_SIZE)-1 downto 0);
  signal trace_bram_wstrb, wenb : std_logic_vector(63 downto 0);
  signal trace_bram_wen : std_logic;
  
  type trace_bram_rdata_type is array (0 to N_BANKS-1) of std_logic_vector(511 downto 0);
  signal trace_bram_rdata_array : trace_bram_rdata_type;
  type trace_bram_raddr_type is array (0 to N_BANKS-1) of std_logic_vector(log2(TRACE_BRAM_SIZE)-1 downto 0);
  signal trace_bram_raddr_array : trace_bram_raddr_type;
  signal trace_bram_ren_array : std_logic_vector(0 to N_BANKS-1);
  
  signal m_axi_bank_0_AWADDR_s   : std_logic_vector( 63 downto 0);
  signal m_axi_bank_0_AWLEN_s    : std_logic_vector(  7 downto 0);
  signal m_axi_bank_0_AWVALID_s  : std_logic;
  signal m_axi_bank_0_AWREADY_s  : std_logic;
  signal m_axi_bank_0_WDATA_s    : std_logic_vector(511 downto 0);
  signal m_axi_bank_0_WSTRB_s    : std_logic_vector( 63 downto 0);
  signal m_axi_bank_0_WVALID_s   : std_logic;
  signal m_axi_bank_0_WREADY_s   : std_logic;
  signal m_axi_bank_0_BRESP_s    : std_logic_vector(  1 downto 0);
  signal m_axi_bank_0_BVALID_s   : std_logic;
  signal m_axi_bank_0_BREADY_s   : std_logic;
  signal m_axi_bank_0_ARADDR_s   : std_logic_vector(63 downto 0);
  signal m_axi_bank_0_ARVALID_s  : std_logic;
  signal m_axi_bank_0_ARREADY_s  : std_logic;
  signal m_axi_bank_0_ARLEN_s    : std_logic_vector(7 downto 0);
  signal m_axi_bank_0_RDATA_s    : std_logic_vector(511 downto 0);
  signal m_axi_bank_0_RVALID_s   : std_logic;
  signal m_axi_bank_0_RREADY_s   : std_logic;

  signal s_axi_control_AWADDR_s  : std_logic_vector( 11 downto 0);
  signal s_axi_control_AWVALID_s : std_logic;
  signal s_axi_control_AWREADY_s : std_logic;
  signal s_axi_control_WDATA_s   : std_logic_vector( 31 downto 0);
  signal s_axi_control_WSTRB_s   : std_logic_vector(  3 downto 0);
  signal s_axi_control_WVALID_s  : std_logic;
  signal s_axi_control_WREADY_s  : std_logic;
  signal s_axi_control_BRESP_s   : std_logic_vector(  1 downto 0);
  signal s_axi_control_BVALID_s  : std_logic;
  signal s_axi_control_BREADY_s  : std_logic;
  signal s_axi_control_ARADDR_s  : std_logic_vector( 11 downto 0);
  signal s_axi_control_ARVALID_s : std_logic;
  signal s_axi_control_ARREADY_s : std_logic;
  signal s_axi_control_RDATA_s   : std_logic_vector( 31 downto 0);
  signal s_axi_control_RRESP_s   : std_logic_vector(  1 downto 0);
  signal s_axi_control_RVALID_s  : std_logic;
  signal s_axi_control_RREADY_s  : std_logic;
  
  signal locked, ap_rst_n_q : std_logic;
  signal one_const : std_logic := '1';
  signal zero_const : std_logic := '0';
  signal zero2_const : std_logic_vector(1 downto 0) := "00";

begin

  AxiLiteRegSlice: entity work.axi_lite_register_slice
  port map (
    aclk => ap_clk,
    aresetn => ap_rst_n_q,
    -- Slave side, going out of the RTL kernel, signals that will be synchronized
    s_axi_awaddr  => s_axi_control_AWADDR,
    s_axi_awvalid => s_axi_control_AWVALID,
    s_axi_awready => s_axi_control_AWREADY,
    s_axi_wdata   => s_axi_control_WDATA,
    s_axi_wstrb   => s_axi_control_WSTRB,
    s_axi_wvalid  => s_axi_control_WVALID,
    s_axi_wready  => s_axi_control_WREADY,
    s_axi_bresp   => s_axi_control_BRESP,
    s_axi_bvalid  => s_axi_control_BVALID,
    s_axi_bready  => s_axi_control_BREADY,
    s_axi_araddr  => s_axi_control_ARADDR,
    s_axi_arvalid => s_axi_control_ARVALID,
    s_axi_arready => s_axi_control_ARREADY,
    s_axi_rdata   => s_axi_control_RDATA,
    s_axi_rresp   => s_axi_control_RRESP,
    s_axi_rvalid  => s_axi_control_RVALID,
    s_axi_rready  => s_axi_control_RREADY,
    -- Master side, driving internal slave signals of the RTL kernel, signals that are synchronized
    m_axi_awaddr  => s_axi_control_AWADDR_s,
    m_axi_awvalid => s_axi_control_AWVALID_s,
    m_axi_awready => s_axi_control_AWREADY_s,
    m_axi_wdata   => s_axi_control_WDATA_s,
    m_axi_wstrb   => s_axi_control_WSTRB_s,
    m_axi_wvalid  => s_axi_control_WVALID_s,
    m_axi_wready  => s_axi_control_WREADY_s,
    m_axi_bresp   => s_axi_control_BRESP_s,
    m_axi_bvalid  => s_axi_control_BVALID_s,
    m_axi_bready  => s_axi_control_BREADY_s,
    m_axi_araddr  => s_axi_control_ARADDR_s,
    m_axi_arvalid => s_axi_control_ARVALID_s,
    m_axi_arready => s_axi_control_ARREADY_s,
    m_axi_rdata   => s_axi_control_RDATA_s,
    m_axi_rresp   => s_axi_control_RRESP_s,
    m_axi_rvalid  => s_axi_control_RVALID_s,
    m_axi_rready  => s_axi_control_RREADY_s
  );

  AxiFullRegSlice: entity work.axi_full_register_slice
  port map (
    aclk => ap_clk,
    aresetn => ap_rst_n_q,
    -- Slave side, driven by the internal master signals that will be synchronized
    s_axi_awaddr  => m_axi_bank_0_AWADDR_s,
    s_axi_awlen   => m_axi_bank_0_AWLEN_s,
    s_axi_awvalid => m_axi_bank_0_AWVALID_s,
    s_axi_awready => m_axi_bank_0_AWREADY_s,
    s_axi_wdata   => m_axi_bank_0_WDATA_s,
    s_axi_wstrb   => m_axi_bank_0_WSTRB_s,
    s_axi_wvalid  => m_axi_bank_0_WVALID_s,
    s_axi_wready  => m_axi_bank_0_WREADY_s,
    s_axi_bresp   => m_axi_bank_0_BRESP_s,
    s_axi_bvalid  => m_axi_bank_0_BVALID_s,
    s_axi_bready  => m_axi_bank_0_BREADY_s,
    s_axi_araddr  => m_axi_bank_0_ARADDR_s,
    s_axi_arlen   => m_axi_bank_0_ARLEN_s,
    s_axi_arvalid => m_axi_bank_0_ARVALID_s,
    s_axi_arready => m_axi_bank_0_ARREADY_s,
    s_axi_rdata   => m_axi_bank_0_RDATA_s,
    s_axi_rvalid  => m_axi_bank_0_RVALID_s,
    s_axi_rready  => m_axi_bank_0_RREADY_s,
    s_axi_wlast   => zero_const,
    s_axi_rresp   => open,
    s_axi_rlast   => open,
    -- Master side, going out of the RTL kernel, but synchronized
    m_axi_awaddr  => m_axi_bank_0_AWADDR,
    m_axi_awlen   => m_axi_bank_0_AWLEN,
    m_axi_awvalid => m_axi_bank_0_AWVALID,
    m_axi_awready => m_axi_bank_0_AWREADY,
    m_axi_wdata   => m_axi_bank_0_WDATA,
    m_axi_wstrb   => m_axi_bank_0_WSTRB,
    m_axi_wvalid  => m_axi_bank_0_WVALID,
    m_axi_wready  => m_axi_bank_0_WREADY,
    m_axi_bresp   => m_axi_bank_0_BRESP,
    m_axi_bvalid  => m_axi_bank_0_BVALID,
    m_axi_bready  => m_axi_bank_0_BREADY,
    m_axi_araddr  => m_axi_bank_0_ARADDR,
    m_axi_arlen   => m_axi_bank_0_ARLEN,
    m_axi_arvalid => m_axi_bank_0_ARVALID,
    m_axi_arready => m_axi_bank_0_ARREADY,
    m_axi_rdata   => m_axi_bank_0_RDATA,
    m_axi_rvalid  => m_axi_bank_0_RVALID,
    m_axi_rready  => m_axi_bank_0_RREADY,
    m_axi_wlast   => open,
    m_axi_rresp   => zero2_const,
    m_axi_rlast   => zero_const
  );

  rst_reg: process(ap_clk) is
  begin 
    if (ap_clk'event and ap_clk='1') then
      ap_rst_n_q <= ap_rst_n;
    end if;
  end process;


  AxiLiteFSM: entity work.AxiLiteFSM
  generic map (
    N_BANKS              => N_BANKS,
    N_SENSORS            => N_SENSORS,
    IDC_SIZE             => IDC_SIZE,
    IDF_SIZE             => IDF_SIZE,
    C_S00_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
    C_S00_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
  )
  port map (
    -----------------------------------------------------------------------------
    -- FSM output signals
    -----------------------------------------------------------------------------
    ---- CPU control signals
    ------ CPU clock enable and reset signals
    cpu_en         => cpu_en,
    cpu_rstn       => cpu_rstn,
    ------ CPU exception (trap) signal
    cpu_trap       => cpu_trap_sync,
    ---- Trace recording trigger
    sens_trg       => sens_trg,
    sens_store_done => store_done_sync,
    dump_idle      => dump_idle,
    ------ CPU memory BRAM write control signals
    start_load     => start_load,
    load_idle      => load_idle,
    load_size      => load_size,
    ---- Sensor calibration control signals
    ------ Calibration value
    sens_calib_val => sens_calib_val,
    ------ Bank in which the sensor to be calibrated is
    sens_calib_bank_id => sens_calib_bank_id,
    ------ Sensor to be calibrated 
    sens_calib_id  => sens_calib_id,
    ------ Calibration trigger 
    sens_calib_trg => sens_calib_trg,
    ---- Sensor traces offloading from BRAM to DRAM
    ------ Base pointer in DRAM
    base_ptr       => base_ptr,
    start_dump     => start_dump,
    dump_bank_id   => dump_bank_id,
    -----------------------------------------------------------------------------
    -- Ports of Axi Lite Slave Interface S00_AXI
    -----------------------------------------------------------------------------
    ---- clk and reset
    aclk           => ap_clk,
    aresetn        => ap_rst_n_q,
    ---- AXI Lite write signals
    ------ write address signals
    awaddr         => s_axi_control_AWADDR_s,
    awvalid        => s_axi_control_AWVALID_s,
    awready        => s_axi_control_AWREADY_s,
    ------ write data signals
    wdata          => s_axi_control_WDATA_s,
    wstrb          => s_axi_control_WSTRB_s,
    wvalid         => s_axi_control_WVALID_s,
    wready         => s_axi_control_WREADY_s,
    ------ write response signals
    bresp          => s_axi_control_BRESP_s,
    bvalid         => s_axi_control_BVALID_s,
    bready         => s_axi_control_BREADY_s,
    ------ AXI Lite read signals (not used)
    -------- read address signals
    araddr         => s_axi_control_ARADDR_s,
    arvalid        => s_axi_control_ARVALID_s,
    arready        => s_axi_control_ARREADY_s,
    ------ read data signals
    rdata          => s_axi_control_RDATA_s,
    rresp          => s_axi_control_RRESP_s,
    rvalid         => s_axi_control_RVALID_s,
    rready         => s_axi_control_RREADY_s
    -----------------------------------------------------------------------------
  );

  AxiLoader: entity work.AxiLoader
  generic map (
    BRAM_DATA_WIDTH => 32,
    BRAM_ADDR_WIDTH => log2(CPU_MEM_SIZE) 
  )
  port map (
    aclk       => ap_clk,
    aresetn    => ap_rst_n_q,
    -- Load trigger
    start_load => start_load, 
    load_idle  => load_idle,
    load_size  => load_size,
    base_ptr   => base_ptr,
    -- BRAM address interface
    wen        => cpu_mem_wen,
    dout       => cpu_mem_data,
    addr       => cpu_mem_addr,
    -- Axi master read interface
    arid       => m_axi_bank_0_ARID,
    araddr     => m_axi_bank_0_ARADDR_s,
    arvalid    => m_axi_bank_0_ARVALID_s,
    arready    => m_axi_bank_0_ARREADY_s,
    arlen      => m_axi_bank_0_ARLEN_s,
    arsize     => m_axi_bank_0_ARSIZE,
    rdata      => m_axi_bank_0_RDATA_s,
    rvalid     => m_axi_bank_0_RVALID_s,
    rready     => m_axi_bank_0_RREADY_s,
    rid        => m_axi_bank_0_RID    
  );

  CPU: entity work.picorv32_top
  port map (
    clk           => cpu_clk,
    clk_en        => cpu_en,
    resetn        => cpu_rstn,

    inst_mem_clk  => ap_clk,
    inst_mem_en   => one_const,
    inst_mem_wen  => cpu_mem_wen_ext,
    inst_mem_addr => cpu_mem_addr,
    inst_mem_data => cpu_mem_data,
    inst_fetched  => cpu_instruction,
    trap          => cpu_trap
  );
  cpu_mem_wen_ext <= cpu_mem_wen & cpu_mem_wen & cpu_mem_wen & cpu_mem_wen;

  trap_sync: entity work.cross_clk_sync
  port map (
    clk_in           => cpu_clk,
    reset_clkin_n    => ap_rst_n_q,
    clk_out          => ap_clk,
    reset_clkout_n   => ap_rst_n_q,
    data_i           => cpu_trap,
    data_o           => cpu_trap_sync
  );  

  AxiBRAMFlusher: entity work.AxiFlusher
  generic map(
    BRAM_DATA_WIDTH => 512,
    BRAM_ADDR_WIDTH => log2(TRACE_BRAM_SIZE),
    WRITE_LENGTH    => N_SAMPLES
  )
  port map(
    base_ptr   => base_ptr,

    douta      => trace_bram_rdata,
    addra      => trace_bram_raddr,
    ena        => trace_bram_ren,

    start_dump => start_dump,
    dump_idle  => dump_idle,

    aclk       => ap_clk,
    aresetn    => ap_rst_n_q,

    awaddr     => m_axi_bank_0_AWADDR_s,
    awlen      => m_axi_bank_0_AWLEN_s,
    awsize     => m_axi_bank_0_AWSIZE,
    awvalid    => m_axi_bank_0_AWVALID_s,
    awready    => m_axi_bank_0_AWREADY_s,

    wdata      => m_axi_bank_0_WDATA_s,
    wstrb      => m_axi_bank_0_WSTRB_s,
    wvalid     => m_axi_bank_0_WVALID_s,
    wready     => m_axi_bank_0_WREADY_s,

    bresp      => m_axi_bank_0_BRESP_s,
    bvalid     => m_axi_bank_0_BVALID_s,
    bready     => m_axi_bank_0_BREADY_s
  );
  
  dump_sync: entity work.cross_clk_sync
  port map (
    clk_in           => sens_clk,
    reset_clkin_n    => ap_rst_n_q,
    clk_out          => ap_clk,
    reset_clkout_n   => ap_rst_n_q,
    data_i           => or_reduct(store_done_array),
    data_o           => store_done_sync
  );  


  bank_generate: for i in 0 to N_BANKS-1 generate
  begin
    first_bank : if i = 0 generate
      bank: entity work.SensorBlock
      generic map ( 
        BRAM_DATA_WIDTH => 512,
        BRAM_ADDR_WIDTH => log2(TRACE_BRAM_SIZE),
        IDC_SIZE        => IDC_SIZE,
        IDF_SIZE        => IDF_SIZE,
        N_SENSORS       => N_SENSORS,
        SENS_SET_BASE   => 0,
        SENSOR_WIDTH    => SENSOR_WIDTH,
        N_SAMPLES       => N_SAMPLES,
        INSTRUCTION     => 1
      ) 
      port map ( 
        ap_clk             => ap_clk,
        sens_clk           => sens_clk,
        reset_n            => sens_rst_n,

        sens_trg           => sens_trg,
        sens_store_done    => store_done_array(i),

        sens_calib_val     => sens_calib_val,
        sens_calib_id      => sens_calib_id,
        sens_calib_trg     => sens_calib_trg,
        sens_calib_bank_id => sens_calib_bank_id(i),

        cpu_instruction    => cpu_instruction,

        trace_bram_rdata   => trace_bram_rdata_array(i),
        trace_bram_raddr   => trace_bram_raddr, --_array(i),
        trace_bram_ren     => trace_bram_ren_array(i)
      );
    end generate first_bank;
    banks: if i /= 0 generate
      bank: entity work.SensorBlock
      generic map ( 
        BRAM_DATA_WIDTH => 512,
        BRAM_ADDR_WIDTH => log2(TRACE_BRAM_SIZE),
        IDC_SIZE        => IDC_SIZE,
        IDF_SIZE        => IDF_SIZE,
        N_SENSORS       => N_SENSORS,
        SENS_SET_BASE   => i*N_SENSORS,
        SENSOR_WIDTH    => SENSOR_WIDTH,
        N_SAMPLES       => N_SAMPLES,
        INSTRUCTION     => 1
      )
      port map ( 
        ap_clk             => ap_clk,
        sens_clk           => sens_clk,
        reset_n            => sens_rst_n,

        sens_trg           => sens_trg,
        sens_store_done    => store_done_array(i),

        sens_calib_val     => sens_calib_val,
        sens_calib_id      => sens_calib_id,
        sens_calib_trg     => sens_calib_trg,
        sens_calib_bank_id => sens_calib_bank_id(i),

        cpu_instruction    => (others => '0'),

        trace_bram_rdata   => trace_bram_rdata_array(i),
        trace_bram_raddr   => trace_bram_raddr, --_array(i),
        trace_bram_ren     => trace_bram_ren_array(i)
      );
    end generate banks;
  end generate;
  
  process(dump_bank_id, trace_bram_rdata_array, trace_bram_ren) is --trace_bram_raddr, trace_bram_ren) is
  begin
    --for i in 0 to N_BANKS-1 loop
    --  trace_bram_raddr_array(i) <= (others => '0');
    --end loop;
    --trace_bram_raddr_array(to_integer(unsigned(dump_bank_id))) <= trace_bram_raddr;
    trace_bram_ren_array <= (others => '0');
    trace_bram_ren_array(to_integer(unsigned(dump_bank_id))) <= trace_bram_ren;

    trace_bram_rdata <= trace_bram_rdata_array(to_integer(unsigned(dump_bank_id)));
  end process;


  cpu_clk <= ap_clk;
  sens_clk <= ap_clk;
  sens_rst_n <= ap_rst_n_q;
  -- MMCM (additional clocks for CPU and sensor)
  --clk_gen: entity work.clock_generator
  --port map(
  --  cpu_clk  => cpu_clk,
  --  sens_clk => sens_clk,
  --  resetn   => ap_rst_n_q,
  --  locked   => locked,
  --  axi_clk  => ap_clk
  --);

end struct;
