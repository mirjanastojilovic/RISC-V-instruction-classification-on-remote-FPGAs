-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.ry_utilities.all;
library work;

entity CPU_Comp is
  Generic(
    N_SENSORS : integer := 1);
  port ( 

    system_clk            : in  std_logic;
    timer_clk             : in  std_logic;
    reset_n               : in  std_logic;
    
    Din                   : in  std_logic_vector(127 downto 0);
    Drdy                  : in  std_logic;
    bsy                   : out std_logic;
    fsm_dvld              : out std_logic;
    dvld_mux              : out std_logic;
    sensor_fifo_dvld      : in  std_logic;

    input_data            : in  STD_LOGIC_VECTOR (127 downto 0);
    krdy                  : in  std_logic;
    kvld                  : out std_logic;

    calib_trg             : out std_logic;
    sens_calib_id         : out std_logic_vector(N_SENSORS-1 downto 0);
    sensor_fifo_read      : out std_logic;
    sensor_trigger        : out std_logic;
    osc_trigger           : out std_logic;
    reset_fifo            : out std_logic;

    instruction_processed : out std_logic_vector(31 downto 0);
    en_cpu                : out std_logic

  );
end CPU_Comp;


architecture Behavioral of CPU_Comp is

  signal exception: std_logic;
  signal instr: std_logic_vector(31 downto 0);
  signal inst_mem_addr: std_logic_vector(11 downto 0);
  signal inst_mem_en: std_logic;
  signal inst_mem_wen: std_logic_vector(0 downto 0);
  signal enable_cpu: std_logic;
  signal instr_processed : std_logic_vector(31 downto 0);
  signal rst_cpu: std_logic;
  
  signal uart0_txd : std_logic := '0';
  signal uart1_txd : std_logic := '0';
  signal uart0_rxd : std_logic;
  signal uart1_rxd : std_logic;
  signal gpio_pins : std_logic_vector(11 downto 0);
  signal EN: std_logic :='1';

begin

  instruction_processed <= instr_processed;
  en_cpu <= enable_cpu;

  FSM: entity work.FSM
    generic map (N_SENSORS => N_SENSORS)
    port map(

      input_data => input_data, 
      krdy => krdy,
      kvld => kvld,

      Din => Din,
      Drdy => Drdy, 
      bsy => bsy,

      instr => instr, 
      inst_mem_addr => inst_mem_addr, 
      inst_mem_en => inst_mem_en, 
      inst_mem_wen => inst_mem_wen, 

      en_cpu => enable_cpu,
      rst_cpu => rst_cpu,
      exception => exception,
      instr_processed => instr_processed,

      calib_trg => calib_trg,
      sens_calib_id => sens_calib_id,
      sensor_fifo_read => sensor_fifo_read,
      sensor_trigger => sensor_trigger,
      osc_trigger => osc_trigger,
      fsm_dvld => fsm_dvld,
      dvld_mux => dvld_mux,
      sensor_fifo_dvld => sensor_fifo_dvld,
      reset_fifo => reset_fifo,

      EN => EN, 
      rst => reset_n, 
      clk => system_clk
    );
 
  CPU: entity work.toplevel
    port map(
      system_clk => system_clk,
      timer_clk => timer_clk,
      reset_n=> reset_n,

      gpio_pins => gpio_pins,
      uart0_txd => uart0_txd,
      uart0_rxd => uart0_rxd,
      uart1_txd => uart1_txd,
      uart1_rxd => uart1_rxd,

      instr => instr,
      inst_mem_addr => inst_mem_addr,
      inst_mem_en => inst_mem_en,
      inst_mem_wen => inst_mem_wen,
      en_cpu => enable_cpu,
      rst_cpu => rst_cpu,
      exception => exception,
      instr_processed => instr_processed
    );

end Behavioral;

