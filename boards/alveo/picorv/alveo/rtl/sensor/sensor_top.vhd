-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.design_package.all;

library unisim;
use unisim.vcomponents.all;

entity sensor_top is
  generic(
    sens_length        : integer := 64;
    initial_delay      : integer := 16;
    fine_delay         : integer := 4;
    set_number         : integer := 1
  );
  port(
    sys_clk            : in  std_logic;
    rst_n              : in  std_logic;
    clk_en_p           : in  std_logic;
    sensor_clk_i       : in  std_logic;
    initial_delay_conf : in  std_logic_vector(initial_delay-1 downto 0);
    fine_delay_conf    : in  std_logic_vector(8*fine_delay-1 downto 0);
    delay_line_o       : out std_logic_vector(sens_length - 1 downto 0)
  );
end sensor_top;

architecture synth of sensor_top is

  component sensor -- the sensor
  generic (
    initial_delay      : integer := 16; -- length of elements preceding the sensor
    fine_delay         : integer := 8;  -- intermediate carry4 elements
    observable_delay   : integer := 64; -- 64 registers are used for the measurments
    set_number         : integer := 1   -- Unique number per sensor instance to group
  );
  port (
    input_clk          : in  std_logic;
    shifted_clk        : in  std_logic;
    initial_delay_conf : in  std_logic_vector(initial_delay-1 downto 0);
    fine_delay_conf    : in  std_logic_vector(8*fine_delay-1 downto 0);
    measurment         : out std_logic_vector(observable_delay - 1 downto 0)
  );
  end component;
  
  signal delaym_0 :  std_logic_vector(sens_length - 1 downto 0);
  
  attribute KEEP : string;
  attribute S : string;
  attribute dont_touch : string;
  attribute KEEP of delaym_0: signal is "true";
  attribute S of delaym_0: signal is "true";
  attribute dont_touch of delaym_0: signal is "true";
  
begin

  tdc0 : sensor 
  generic map (
    initial_delay      => initial_delay, -- extremely important to fill entier number of slices
    fine_delay         => fine_delay,
    observable_delay   => sens_length,
    set_number         => set_number) 
  port map (
    input_clk          => sensor_clk_i, 
    shifted_clk        => sys_clk,
    initial_delay_conf => initial_delay_conf,
    fine_delay_conf    => fine_delay_conf,
    measurment         => delaym_0
  );
  
  delay_line_o <= delaym_0;

end synth;



