-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity SensorBlock is
  Generic ( 
    BRAM_DATA_WIDTH : integer := 512;     
    BRAM_ADDR_WIDTH : integer := 12;     
    IDC_SIZE        : integer := 30;
    IDF_SIZE        : integer := 28;
    N_SENSORS       : integer := 30;
    SENS_SET_BASE   : integer := 0;
    SENSOR_WIDTH    : integer := 16;
    N_SAMPLES       : integer := 1024;   
    INSTRUCTION     : integer := 0);     
  Port ( 
    ap_clk           : in  std_logic;
    sens_clk         : in  std_logic;
    reset_n          : in  std_logic;

    sens_trg         : in  std_logic;
    sens_store_done  : out std_logic;

    sens_calib_val   : in  std_logic_vector(IDC_SIZE+IDF_SIZE-1 downto 0);
    sens_calib_id    : in  std_logic_vector(N_SENSORS-1 downto 0);
    sens_calib_trg   : in  std_logic;
    sens_calib_bank_id : in  std_logic;

    cpu_instruction  : in  std_logic_vector(31 downto 0); 

    trace_bram_rdata : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    trace_bram_raddr : in  std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    trace_bram_ren   : in  std_logic);

end SensorBlock;

architecture behavior of SensorBlock is

  signal one_const : std_logic := '1';

  signal trace_bram_wdata, wdatab : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal trace_bram_waddr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal trace_bram_wstrb, wenb: std_logic_vector(BRAM_DATA_WIDTH/8-1 downto 0);
  signal trace_bram_wen : std_logic;

  signal sensor_val : std_logic_vector(N_SENSORS*SENSOR_WIDTH+INSTRUCTION*32-1 downto 0);
  signal sensor_val_ext : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal sens_bank_calib_trg : std_logic;

begin

  BramDumper: entity work.BramDumper
  generic map(
    IN_WIDTH        => BRAM_DATA_WIDTH,
    BRAM_DATA_WIDTH => BRAM_DATA_WIDTH,
    BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
    N_SAMPLES       => N_SAMPLES,
    BYTE_ADDR       => 0
  )
  port map(
    clk         => sens_clk,
    reset_n     => reset_n,
    clk_en_p_i  => one_const,
    trigger_p_i => sens_trg,
    start_dump  => sens_store_done,
    data_i      => sensor_val_ext,
    data_o      => trace_bram_wdata,
    waddr_o     => trace_bram_waddr,
    strb_o      => trace_bram_wstrb,
    wen_o       => trace_bram_wen
  );
  pad_zeros: if N_SENSORS*SENSOR_WIDTH+32-1 < 511 generate
    sensor_val_ext(511 downto N_SENSORS*SENSOR_WIDTH+32) <= (others => '0');
  end generate;
  sensor_val_ext(N_SENSORS*SENSOR_WIDTH+32-1 downto 0) <= sensor_val;

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
    DATA_WIDTH => BRAM_DATA_WIDTH,
    ADDR_WIDTH => BRAM_ADDR_WIDTH 
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
  
  sens_bank_calib_trg <= sens_calib_trg and sens_calib_bank_id;

  sensors: entity work.sensor_top_multiple
  generic map (
    N_SENSORS        => N_SENSORS,
    SENS_SET_BASE    => SENS_SET_BASE,
    COARSE_WIDTH     => IDC_SIZE,
    FINE_WIDTH       => IDF_SIZE,
    SENSOR_WIDTH     => SENSOR_WIDTH,
    INSTRUCTION      => INSTRUCTION
  )
  port map (
    clk_in           => sens_clk,
    reset_n_in       => reset_n,
    dlay_line_o      => sensor_val,

    sens_calib_clk   => ap_clk,
    sens_calib_val   => sens_calib_val,
    sens_calib_trg   => sens_bank_calib_trg,
    sens_calib_id    => sens_calib_id,

    instruction_word => cpu_instruction
  );

end behavior;

