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

ENTITY system_top IS
    generic (
        COARSE_WIDTH     : integer := 30;
        FINE_WIDTH       : integer := 28;
        SENSOR_WIDTH     : integer := 64
    );
  Port (
    clk_in           : in std_logic;
    reset_n_in       : in std_logic;
    IDC_IDF_in       : in std_logic_vector(COARSE_WIDTH+4*FINE_WIDTH-1 downto 0);
    dlay_line_o      : out std_logic_vector(127 downto 0);
    instruction      : in std_logic_vector(31 downto 0);
    trigger_i        : in std_logic;
    en_cpu           : in std_logic
    );
END system_top;

ARCHITECTURE behavior OF system_top IS

  -- Sensor signals
  signal delay_line_s : std_logic_vector(SENSOR_WIDTH-1 downto 0); -- sensor delay line
  signal state_alert: std_logic_vector(3 downto 0);

  -- Calibration signals
  signal IDC : STD_LOGIC_VECTOR(COARSE_WIDTH-1 downto 0);
  signal IDF : STD_LOGIC_VECTOR(4*FINE_WIDTH-1 downto 0);

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
    
  dlay_line_o(127 downto 96) <= instruction;
  dlay_line_o(95 downto 65) <= "0000000000000000000000000000000";
  dlay_line_o(64) <= en_cpu;
  dlay_line_o(63 downto 16) <= (others => '0');
  dlay_line_o(15 downto 0) <= delay_line_s;
  
  sensor: entity work.sensor_top
  Generic map (
    sens_length => SENSOR_WIDTH,
    initial_delay => COARSE_WIDTH,
    fine_delay => FINE_WIDTH,
    set_number => 1
  )
  Port map (
    rst_n              => reset_n_in,
    sys_clk            => clk_in,
    clk_en_p           => '1',
    initial_delay_conf => IDC,
    fine_delay_conf    => IDF,
    delay_line_o       => delay_line_s,
    sensor_clk_i       => clk_in 
  );

  IDC_IDF_reg: process(clk_in) is
  begin
    if(rising_edge(clk_in)) then
      if(reset_n_in = '0') then
        IDC <= (others => '0');
        IDF <= (others => '0');
      elsif(trigger_i = '1') then
        IDC <= IDC_IDF_in(COARSE_WIDTH-1 downto 0);
        IDF <= IDC_IDF_in(COARSE_WIDTH+4*FINE_WIDTH-1 downto COARSE_WIDTH);
      end if;
    end if;
  end process;

END;

