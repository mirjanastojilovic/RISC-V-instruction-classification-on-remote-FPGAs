-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.design_package.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

ENTITY system_top_multiple IS
    generic (
        N_SENSORS        : integer := 1;
        COARSE_WIDTH     : integer := 30;
        FINE_WIDTH       : integer := 28;
        SENSOR_WIDTH     : integer := 64
    );
  Port (
    clk_in           : in std_logic;
    reset_n_in       : in std_logic;
    IDC_IDF_in       : in std_logic_vector(COARSE_WIDTH+4*FINE_WIDTH-1  downto 0);
    dlay_line_o      : out std_logic_vector(N_SENSORS*SENSOR_WIDTH+32+16-1 downto 0);
    instruction      : in std_logic_vector(31 downto 0);
    trigger_i        : in std_logic;
    sens_calib_id    : in std_logic_vector(N_SENSORS-1 downto 0);
    en_cpu           : in std_logic
    );
END system_top_multiple;

ARCHITECTURE behavior OF system_top_multiple IS

  -- Sensor signals
  type delay_line_array is array (1 to N_SENSORS) of std_logic_vector(SENSOR_WIDTH-1 downto 0);
  signal delay_line_s : delay_line_array;
  signal state_alert: std_logic_vector(3 downto 0);

  -- Calibration signals
  type IDC_array is array (1 to N_SENSORS) of std_logic_vector(COARSE_WIDTH-1 downto 0);
  signal IDC : IDC_array := (others => (others => '0'));
  type IDF_array is array (1 to N_SENSORS) of std_logic_vector(4*FINE_WIDTH-1 downto 0);
  signal IDF : IDF_array := (others => (others => '0'));

  attribute keep : string;
  attribute keep of delay_line_s           : signal is "yes";
  attribute keep of IDC                    : signal is "yes";
  attribute keep of IDF                    : signal is "yes";

  attribute S : string;
  attribute S of delay_line_s              : signal is "yes";
  attribute S of IDC                       : signal is "yes";
  attribute S of IDF                       : signal is "yes";

  attribute dont_touch : string;
  attribute dont_touch of delay_line_s     : signal is "yes";
  attribute dont_touch of IDC              : signal is "yes";
  attribute dont_touch of IDF              : signal is "yes";
  
BEGIN
    
  dlay_line_o(dlay_line_o'left downto dlay_line_o'left-32+1) <= instruction;
  dlay_line_o(dlay_line_o'left-32 downto dlay_line_o'left-32-16+1) <= "000000000000000"&en_cpu;
  
  sensor_gen: for i in 1 to N_SENSORS generate
    sensor: entity work.sensor_top
    Generic map (
      sens_length => SENSOR_WIDTH,
      initial_delay => COARSE_WIDTH,
      fine_delay => FINE_WIDTH,
      set_number => i
    )
    Port map (
      rst_n              => reset_n_in,
      sys_clk            => clk_in,
      clk_en_p           => '1',
      initial_delay_conf => IDC(i),
      fine_delay_conf    => IDF(i),
      delay_line_o       => delay_line_s(i),
      sensor_clk_i       => clk_in 
    );

    dlay_line_o(i*SENSOR_WIDTH-1 downto (i-1)*SENSOR_WIDTH) <= delay_line_s(i);
    
    IDC_IDF_reg: process(clk_in) is
    begin
      if(rising_edge(clk_in)) then
        if(trigger_i = '1' and sens_calib_id(i-1) = '1') then
          IDC(i) <= IDC_IDF_in(COARSE_WIDTH-1 downto 0);
          IDF(i) <= IDC_IDF_in(COARSE_WIDTH+4*FINE_WIDTH-1 downto COARSE_WIDTH);
        end if;
      end if;
    end process;
    
  end generate;

END;
