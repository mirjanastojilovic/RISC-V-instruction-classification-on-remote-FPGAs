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
  m_axi_bank_0_WLAST    : out std_logic;
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

  constant N_SENSORS            : integer := 6;
  constant IDC_SIZE             : integer := 32;
  constant IDF_SIZE             : integer := 96;
  constant CPU_MEM_SIZE         : integer := 8192;
  constant C_S00_AXI_DATA_WIDTH : integer := 32;
  constant C_S00_AXI_ADDR_WIDTH : integer := 12;
  constant N_SAMPLES            : integer := 2048;
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
  signal base_ptr : std_logic_vector(63 downto 0);
  
  signal trace_bram_rdata : std_logic_vector(511 downto 0);
  signal trace_bram_raddr : std_logic_vector(log2(TRACE_BRAM_SIZE)-1 downto 0);
  signal start_dump, start_dump_sync, trace_bram_ren : std_logic;
  
  signal sens_clk : std_logic;
  signal sensor_val : std_logic_vector(N_SENSORS*SENSOR_WIDTH+32+4-1 downto 0);
  signal sensor_val_ext : std_logic_vector(511 downto 0);
  
  signal trace_bram_wdata, wdatab : std_logic_vector(511 downto 0);
  signal trace_bram_waddr : std_logic_vector(log2(TRACE_BRAM_SIZE)-1 downto 0);
  signal trace_bram_wstrb, wenb : std_logic_vector(63 downto 0);
  signal trace_bram_wen : std_logic;

  signal bram_dump_idle : std_logic;

  signal cpu_status : std_logic_vector(3 downto 0);
  
  signal locked : std_logic;
  signal one_const : std_logic := '1';
  signal zero_const : std_logic := '0';

  component rst_gen
    port (
        slowest_sync_clk     : in  std_logic;
        ext_reset_in         : in  std_logic;
        aux_reset_in         : in  std_logic;
        mb_debug_sys_rst     : in  std_logic;
        dcm_locked           : in  std_logic;
        mb_reset             : out std_logic;
        bus_struct_reset     : out std_logic_vector(0 downto 0);
        peripheral_reset     : out std_logic;
        interconnect_aresetn : out std_logic_vector(0 downto 0);
        peripheral_aresetn   : out std_logic
    );
  end component;

  signal m_axi_bank_0_AWADDR_s   : std_logic_vector( 63 downto 0);
  signal m_axi_bank_0_AWLEN_s    : std_logic_vector(  7 downto 0);
  signal m_axi_bank_0_AWSIZE_s   : std_logic_vector(  2 downto 0);
  signal m_axi_bank_0_AWVALID_s  : std_logic;
  signal m_axi_bank_0_AWREADY_s  : std_logic;
  signal m_axi_bank_0_WDATA_s    : std_logic_vector(511 downto 0);
  signal m_axi_bank_0_WSTRB_s    : std_logic_vector( 63 downto 0);
  signal m_axi_bank_0_WVALID_s   : std_logic;
  signal m_axi_bank_0_WLAST_s    : std_logic;
  signal m_axi_bank_0_WREADY_s   : std_logic;
  signal m_axi_bank_0_BRESP_s    : std_logic_vector(  1 downto 0);
  signal m_axi_bank_0_BVALID_s   : std_logic;
  signal m_axi_bank_0_BREADY_s   : std_logic;
  signal m_axi_bank_0_ARID_s     : std_logic;
  signal m_axi_bank_0_ARADDR_s   : std_logic_vector(63 downto 0);
  signal m_axi_bank_0_ARVALID_s  : std_logic;
  signal m_axi_bank_0_ARREADY_s  : std_logic;
  signal m_axi_bank_0_ARLEN_s    : std_logic_vector(7 downto 0);
  signal m_axi_bank_0_ARSIZE_s   : std_logic_vector(2 downto 0);
  signal m_axi_bank_0_RDATA_s    : std_logic_vector(511 downto 0);
  signal m_axi_bank_0_RVALID_s   : std_logic;
  signal m_axi_bank_0_RREADY_s   : std_logic;
  signal m_axi_bank_0_RID_s      : std_logic;
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

begin

  m_axi_bank_0_AWADDR     <= m_axi_bank_0_AWADDR_s;
  m_axi_bank_0_AWLEN      <= m_axi_bank_0_AWLEN_s;
  m_axi_bank_0_AWSIZE     <= m_axi_bank_0_AWSIZE_s;
  m_axi_bank_0_AWVALID    <= m_axi_bank_0_AWVALID_s;
  m_axi_bank_0_AWREADY_s  <= m_axi_bank_0_AWREADY;
  m_axi_bank_0_WDATA      <= m_axi_bank_0_WDATA_s;
  m_axi_bank_0_WSTRB      <= m_axi_bank_0_WSTRB_s;
  m_axi_bank_0_WVALID     <= m_axi_bank_0_WVALID_s;
  m_axi_bank_0_WLAST      <= m_axi_bank_0_WLAST_s;
  m_axi_bank_0_WREADY_s   <= m_axi_bank_0_WREADY;
  m_axi_bank_0_BRESP_s    <= m_axi_bank_0_BRESP;
  m_axi_bank_0_BVALID_s   <= m_axi_bank_0_BVALID;
  m_axi_bank_0_BREADY     <= m_axi_bank_0_BREADY_s;
  m_axi_bank_0_ARID       <= m_axi_bank_0_ARID_s;
  m_axi_bank_0_ARADDR     <= m_axi_bank_0_ARADDR_s;
  m_axi_bank_0_ARVALID    <= m_axi_bank_0_ARVALID_s;
  m_axi_bank_0_ARREADY_s  <= m_axi_bank_0_ARREADY;
  m_axi_bank_0_ARLEN      <= m_axi_bank_0_ARLEN_s;
  m_axi_bank_0_ARSIZE     <= m_axi_bank_0_ARSIZE_s;
  m_axi_bank_0_RDATA_s    <= m_axi_bank_0_RDATA;
  m_axi_bank_0_RVALID_s   <= m_axi_bank_0_RVALID;
  m_axi_bank_0_RREADY     <= m_axi_bank_0_RREADY_s;
  m_axi_bank_0_RID_s      <= m_axi_bank_0_RID;
  s_axi_control_AWADDR_s  <= s_axi_control_AWADDR;
  s_axi_control_AWVALID_s <= s_axi_control_AWVALID;
  s_axi_control_AWREADY   <= s_axi_control_AWREADY_s;
  s_axi_control_WDATA_s   <= s_axi_control_WDATA;
  s_axi_control_WSTRB_s   <= s_axi_control_WSTRB;
  s_axi_control_WVALID_s  <= s_axi_control_WVALID;
  s_axi_control_WREADY    <= s_axi_control_WREADY_s;
  s_axi_control_BRESP     <= s_axi_control_BRESP_s;
  s_axi_control_BVALID    <= s_axi_control_BVALID_s;
  s_axi_control_BREADY_s  <= s_axi_control_BREADY;
  s_axi_control_ARADDR_s  <= s_axi_control_ARADDR;
  s_axi_control_ARVALID_s <= s_axi_control_ARVALID;
  s_axi_control_ARREADY   <= s_axi_control_ARREADY_s;
  s_axi_control_RDATA     <= s_axi_control_RDATA_s;
  s_axi_control_RRESP     <= s_axi_control_RRESP_s;
  s_axi_control_RVALID    <= s_axi_control_RVALID_s;
  s_axi_control_RREADY_s  <= s_axi_control_RREADY;

  -- ila_probe: entity work.ila_0
  -- port map (
  --   clk     => ap_clk,
  --   -- AXI Master (outputs of AxiFlusher)
  --   probe0  => m_axi_bank_0_AWADDR_s,
  --   probe1  => m_axi_bank_0_AWLEN_s,
  --   probe2  => m_axi_bank_0_AWSIZE_s,
  --   probe3  => m_axi_bank_0_AWVALID_s,
  --   probe4  => m_axi_bank_0_AWREADY_s,
  --   probe5  => m_axi_bank_0_WDATA_s,
  --   probe6  => m_axi_bank_0_WSTRB_s,
  --   probe7  => m_axi_bank_0_WVALID_s,
  --   probe8  => m_axi_bank_0_WREADY_s,
  --   probe9  => m_axi_bank_0_BRESP_s,
  --   probe10 => m_axi_bank_0_BVALID_s,
  --   probe11 => m_axi_bank_0_BREADY_s,
  --   -- AXI FLUSHER
  --   probe12 => base_ptr,
  --   probe13 => trace_bram_raddr,
  --   probe14 => trace_bram_ren,
  --   probe15 => start_dump_sync,
  --   probe16 => dump_idle,
  --   -- BRAM DUMPER
  --   probe17 => sens_trg,
  --   probe18 => start_dump,
  --   probe19 => bram_dump_idle,
  --   probe20 => trace_bram_waddr,
  --   probe21 => trace_bram_wstrb,
  --   probe22 => trace_bram_wen,
  --   -- Status reg
  --   probe23 => s_axi_control_RDATA_s,
  --   -- AXI FLUSHER DATA IN
  --   probe24 => trace_bram_rdata,
  --   -- BRAM DATA IN
  --   probe25 => trace_bram_wdata,
  --   -- CPU SIGNALS
  --   probe26 => cpu_instruction,
  --   probe27 => cpu_en,
  --   probe28 => cpu_trap,
  --   -- AXI READ SIGNALS
  --   probe30 => m_axi_bank_0_ARADDR_s, -- 64
  --   probe31 => m_axi_bank_0_ARVALID_s, -- 1
  --   probe32 => m_axi_bank_0_ARREADY_s, -- 1
  --   probe33 => m_axi_bank_0_ARLEN_s, -- 8
  --   probe34 => m_axi_bank_0_ARSIZE_s, -- 3
  --   probe35 => m_axi_bank_0_RDATA_s, -- 512
  --   probe36 => m_axi_bank_0_RVALID_s, -- 1
  --   probe37 => m_axi_bank_0_RREADY_s, -- 1
  --   -- BRAM LOADER
  --   probe38 => start_load, -- 1
  --   probe39 => load_size, -- 32
  --   probe40 => cpu_mem_wen, -- 1
  --   probe41 => cpu_mem_addr, -- 13
  --   probe42 => cpu_mem_data -- 32
  -- );

  AxiLiteFSM: entity work.AxiLiteFSM
  generic map (
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
    dump_idle      => dump_idle,
    ------ CPU memory BRAM write control signals
    start_load     => start_load,
    load_idle      => load_idle,
    load_size      => load_size,
    ---- Sensor calibration control signals
    ------ Calibration value
    sens_calib_val => sens_calib_val,
    ------ Sensor to be calibrated 
    sens_calib_id  => sens_calib_id,
    ------ Calibration trigger 
    sens_calib_trg => sens_calib_trg,
    ---- Sensor traces offloading from BRAM to DRAM
    ------ Base pointer in DRAM
    base_ptr       => base_ptr,
    -- DEBUG
    bram_dump_idle => bram_dump_idle,
    start_dump     => start_dump,
    start_dump_sync=> start_dump_sync,
    -----------------------------------------------------------------------------
    -- Ports of Axi Lite Slave Interface S00_AXI
    -----------------------------------------------------------------------------
    ---- clk and reset
    aclk           => ap_clk,
    aresetn        => ap_rst_n,
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
    aresetn    => ap_rst_n,
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
    arid       => m_axi_bank_0_ARID_s,
    araddr     => m_axi_bank_0_ARADDR_s,
    arvalid    => m_axi_bank_0_ARVALID_s,
    arready    => m_axi_bank_0_ARREADY_s,
    arlen      => m_axi_bank_0_ARLEN_s,
    arsize     => m_axi_bank_0_ARSIZE_s,
    rdata      => m_axi_bank_0_RDATA_s,
    rvalid     => m_axi_bank_0_RVALID_s,
    rready     => m_axi_bank_0_RREADY_s,
    rid        => m_axi_bank_0_RID_s    
  );

  CPU: entity work.picorv32_top
  port map (
    clk           => ap_clk,
    clk_en        => cpu_en,
    resetn        => cpu_rstn,

    inst_mem_clk  => ap_clk,
    inst_mem_en   => one_const,
    inst_mem_wen  => cpu_mem_wen_ext,
    inst_mem_addr => cpu_mem_addr,
    inst_mem_data => cpu_mem_data,
    inst_fetched  => cpu_instruction,
    inst_mem_rdy  => cpu_status(0),
    inst_mem_vld  => cpu_status(1),
    inst_mem_inst => cpu_status(2),
    dec_trigger   => cpu_status(3),
    trap          => cpu_trap
  );
  cpu_mem_wen_ext <= cpu_mem_wen & cpu_mem_wen & cpu_mem_wen & cpu_mem_wen;

  trap_sync: entity work.cross_clk_sync
  port map (
    clk_in           => ap_clk,
    reset_clkin_n    => ap_rst_n,
    clk_out          => ap_clk,
    reset_clkout_n   => ap_rst_n,
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

    start_dump => start_dump_sync,
    dump_idle  => dump_idle,

    aclk       => ap_clk,
    aresetn    => ap_rst_n,

    awaddr     => m_axi_bank_0_AWADDR_s,
    awlen      => m_axi_bank_0_AWLEN_s,
    awsize     => m_axi_bank_0_AWSIZE_s,
    awvalid    => m_axi_bank_0_AWVALID_s,
    awready    => m_axi_bank_0_AWREADY_s,

    wdata      => m_axi_bank_0_WDATA_s,
    wstrb      => m_axi_bank_0_WSTRB_s,
    wvalid     => m_axi_bank_0_WVALID_s,
    wlast      => m_axi_bank_0_WLAST_s,
    wready     => m_axi_bank_0_WREADY,

    bresp      => m_axi_bank_0_BRESP_s,
    bvalid     => m_axi_bank_0_BVALID_s,
    bready     => m_axi_bank_0_BREADY_s
  );
  
  dump_sync: entity work.cross_clk_sync
  port map (
    clk_in           => sens_clk,
    reset_clkin_n    => sens_rst_n,
    clk_out          => ap_clk,
    reset_clkout_n   => ap_rst_n,
    data_i           => start_dump,
    data_o           => start_dump_sync
  );  

  sensors: entity work.sensor_top_multiple
  generic map (
    N_SENSORS      => N_SENSORS,
    COARSE_WIDTH   => IDC_SIZE,
    FINE_WIDTH     => IDF_SIZE,
    SENSOR_WIDTH   => SENSOR_WIDTH,
    INSTRUCTION    => 1
  )
  port map (
    clk_in           => sens_clk,
    reset_n_in       => sens_rst_n,
    dlay_line_o      => sensor_val,

    sens_calib_clk   => ap_clk,
    sens_calib_val   => sens_calib_val,
    sens_calib_trg   => sens_calib_trg,
    sens_calib_id    => sens_calib_id,

    instruction_word => cpu_instruction,
    cpu_status       => cpu_status
  );

  BramDumper: entity work.BramDumper
  generic map(
    IN_WIDTH        => 512,
    BRAM_DATA_WIDTH => 512,
    BRAM_ADDR_WIDTH => log2(TRACE_BRAM_SIZE),
    N_SAMPLES       => N_SAMPLES,
    BYTE_ADDR       => 0
  )
  port map(
    clk         => sens_clk,
    reset_n     => sens_rst_n,
    clk_en_p_i  => one_const,
    trigger_p_i => sens_trg,
    start_dump  => start_dump,
    bram_dump_idle => bram_dump_idle,
    data_i      => sensor_val_ext,
    data_o      => trace_bram_wdata,
    waddr_o     => trace_bram_waddr,
    strb_o      => trace_bram_wstrb,
    wen_o       => trace_bram_wen
  );
  pad_zeros: if N_SENSORS*SENSOR_WIDTH+32-1 < 511 generate
    sensor_val_ext(511 downto N_SENSORS*SENSOR_WIDTH+32+4) <= (others => '0');
  end generate;
  sensor_val_ext(N_SENSORS*SENSOR_WIDTH+32+4-1 downto 0) <= sensor_val;

  --trace_bram: entity work.trace_bram
  --port map (
  --  -- Dump trace port
  --  clka  => sens_clk,
  --  ena   => trace_bram_wen,
  --  wea   => trace_bram_wstrb,
  --  addra => trace_bram_waddr,
  --  dina  => trace_bram_wdata,
  --  douta => open,
  --  -- Flush trace port
  --  clkb  => ap_clk,
  --  enb   => trace_bram_ren,
  --  web   => wenb,
  --  addrb => trace_bram_raddr,
  --  dinb  => wdatab,
  --  doutb => trace_bram_rdata
  --);

  --wenb <= (others => '0');
  --wdatab <= (others => '0');

  trace_bram: entity work.URAMLike
  generic map (
    DATA_WIDTH => 512,
    ADDR_WIDTH => log2(TRACE_BRAM_SIZE) 
  )
  port map (
    -- Dump trace port
    clka  => sens_clk,
    ena   => trace_bram_wen,
    wea   => trace_bram_wstrb,
    addra => trace_bram_waddr,
    dina  => trace_bram_wdata,
    -- Flush trace port
    clkb  => ap_clk,
    enb   => trace_bram_ren,
    addrb => trace_bram_raddr,
    doutb => trace_bram_rdata
  );


  cpu_clk <= ap_clk;
  sens_clk <= ap_clk;
  sens_rst_n <= ap_rst_n;
  ---- MMCM (additional clocks for CPU and sensor)
  --clk_gen: entity work.clock_generator
  --port map(
  --  cpu_clk  => cpu_clk,
  --  sens_clk => sens_clk,
  --  resetn   => ap_rst_n,
  --  locked   => locked,
  --  axi_clk  => ap_clk
  --);

  --reset_generator: rst_gen
  --port map (
  --  slowest_sync_clk     => sens_clk,
  --  ext_reset_in         => ap_rst_n,
  --  aux_reset_in         => one_const,
  --  mb_debug_sys_rst     => zero_const,
  --  dcm_locked           => locked,
  --  mb_reset             => open,
  --  bus_struct_reset     => open, 
  --  peripheral_reset     => open,
  --  interconnect_aresetn => open,
  --  peripheral_aresetn   => sens_rst_n
  --);

end struct;
