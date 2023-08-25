--
-- MIT License
--
-- Copyright (c) 2022 Ognjen Glamočanin, David Spielmann, Mirjana Stojilović
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

-- This sensor consists of an initial delay line followed by a group of registers. The
-- initial delay line consists of LUTs, open latches and CARRY4s for calibration. Thanks to 
-- this design, it allows calibration at runtime. The registers are constrained to be 
-- within a pblock. Please note that there are no routing constraints.

entity sensor is

  generic (
    -- initial_delay: number of LUT/LD elements preceding the sensor
    -- fine_delay: number of CARRY4 elements preceding the sensor. 
    -- observable_delay: number of FDs used for the measurements
    -- set_number: unique number per sensor. If there is only one sensor, set_number is fixed to 1. 
    initial_delay       : integer := 32; 
    fine_delay         : integer := 24;
    observable_delay       : integer := 128; 
    set_number         : integer := 1 
  );
  port (
    --input_clk: clock that propagates through the elements
    --shifted_clk: clock for the FDs
    --initial_delay_conf: specifies the number of LUTs/LD elements preceding the sensor.
    --fine_delay_conf: specifies the number of CARRY4 elements preceding the sensor.
    --measurement: output of the sensor
    input_clk       : in  std_logic;
    shifted_clk     : in  std_logic;
    initial_delay_conf        : in  std_logic_vector(initial_delay - 1 downto 0);
    fine_delay_conf          : in std_logic_vector(8 * fine_delay - 1 downto 0);
    measurment           : out std_logic_vector(observable_delay - 1 downto 0)
  );
end sensor;

architecture Behavioral of sensor is

--CARRY4s that are used in the fine delay line
 component CARRY8 
    port(
      CO     : out std_logic_vector(7 downto 0);
      O      : out std_logic_vector(7 downto 0);
      CI     : in std_ulogic := 'L';
      CI_TOP : in std_ulogic := 'L';
      DI     : in std_logic_vector(7 downto 0);
      S      : in std_logic_vector(7 downto 0)
      );
  end component;

  --LUTs that are used in the initial delay line
  component LUT5 
    generic (INIT: bit_vector(31 downto 0) := x"0000_0002");
    port (O  : out std_ulogic;
          I0 : in std_ulogic;
          I1 : in std_ulogic;
          I2 : in std_ulogic;
          I3 : in std_ulogic;
          I4 : in std_ulogic
          );
  end component;

  --LDs used (along with LUTs) in the initial delay line
  component LD 
    generic(INIT : bit := '0');
    port(Q : out std_ulogic := '0';
         D : in std_ulogic;
         G : in std_ulogic
         );
  end component;


  --FDs used to take the measurements
  component FD 
    generic(INIT : bit := '0'); 
    port(Q : out std_ulogic;
         C : in std_ulogic;
         D : in std_ulogic
         );
  end component;


  signal ID_coarse_s : std_logic_vector(2 * initial_delay - 1 downto 0);
  signal ID_fine_s   : std_logic_vector(fine_delay - 1 downto 0);
  signal measurement_s  : std_logic_vector(observable_delay - 1 downto 0) := (others => '0');

  --KEEP_HIERARCHY: prevent optimizations along the hierarchy boundaries
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of Behavioral: architecture is "true";

  --BOX_TYPE: set instantiation type, avoid warnings
  attribute box_type : string;
  attribute box_type of LUT5 : component is "black_box";
  attribute box_type of LD : component is "black_box";
  attribute box_type of FD : component is "black_box";

  --U_SET: set user set constraints
  attribute U_SET : string;
  attribute U_SET of coarse_init : label is "chainset" & integer'image(set_number);
  attribute U_SET of coarse_ld_init : label is "chainset" & integer'image(set_number);
  attribute U_SET of fine_init : label is "chainset" & integer'image(set_number);
  attribute U_SET of pre_buf_chain_gen : label is "chainset" & integer'image(set_number);
  attribute U_SET of measurement_regs : label is "chainset" & integer'image(set_number);
  attribute U_SET of ID_coarse_s : signal is "chainset" & integer'image(set_number);
  attribute U_SET of ID_fine_s : signal is "chainset" & integer'image(set_number);
  attribute U_SET of measurement_s : signal is "chainset" & integer'image(set_number);
  attribute U_SET of LUT5 : component is "chainset" & integer'image(set_number);
  attribute U_SET of LD : component is "chainset" & integer'image(set_number);
  attribute U_SET of FD : component is "chainset" & integer'image(set_number);

  --S (SAVE): save nets constraint and prevent optimizations
  attribute S : string; 
  attribute S of ID_coarse_s : signal is "true";
  attribute S of ID_fine_s : signal is "true"; 
  attribute S of measurement_s : signal is "true";
  attribute S of pre_buf_chain_gen : label is "true";

  attribute S of measurement_regs : label is "true";
  attribute S of coarse_init : label is "true";
  attribute S of fine_init : label is "true";
  attribute S of coarse_ld_init : label is "true";


  --KEEP: prevent optimizations 
  attribute keep : string; 
  attribute keep of measurement_s: signal is "true";
  attribute keep of input_clk: signal is "true";
  attribute keep of ID_coarse_s : signal is "true";
  attribute keep of ID_fine_s : signal is "true";

  --SYN_KEEP: keep externally visible
  attribute syn_keep : string; 
  attribute syn_keep of pre_buf_chain_gen : label is "true";

  attribute syn_keep of measurement_regs : label is "true";

  --DONT_TOUCH: prevent optimizations
  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of ID_coarse_s : signal is "true";
  attribute DONT_TOUCH of ID_fine_s : signal is "true";
  
  --EQUIVALENT_REGISTER_REMOVAL: disable removal of equivalent registers described at RTL level
  attribute equivalent_register_removal: string;
  attribute equivalent_register_removal of measurement_s : signal is "no";

  --CLOCK_SIGNAL: clock signal will go through combinatorial logic
  attribute clock_signal : string;
  attribute clock_signal of ID_coarse_s : signal is "no";
  attribute clock_signal of ID_fine_s : signal is "no";

  --MAXDELAY: set max delay for chain and pre_chain
  attribute maxdelay : string;
  attribute maxdelay of ID_coarse_s : signal is "1000ms";
  attribute maxdelay of ID_fine_s : signal is "1000ms";

  --RLOC: Define relative location
  attribute RLOC : string;
  attribute RLOC of coarse_init: label is
    "X0" &
    "Y" & integer'image(integer(fine_delay)); 
  attribute RLOC of coarse_ld_init: label is
    "X0" &
    "Y" & integer'image(integer(fine_delay)); 
  attribute RLOC of fine_init: label is "X0Y0";  

begin

  --first CARRY4 of the fine delay line
  fine_init : CARRY8
     port map(
         CO(7) => ID_fine_s(0),
         CO(6 downto 0) => open,
         O  => open, 
         CI => input_clk, 
         CI_TOP => '0', 
         DI(0) => input_clk,
         DI(1) => input_clk,
         DI(2) => input_clk,
         DI(3) => input_clk, 
         DI(4) => input_clk, 
         DI(5) => input_clk, 
         DI(6) => input_clk, 
         DI(7) => input_clk, 
         S  => fine_delay_conf(7 downto 0)
     );

  --add the CARRY4s in the fine delay line for calibration.
  fine_chain_carry : for i in 1 to (ID_fine_s'high) generate
  begin
  fine_carry : CARRY8
     port map (
	 CO(7) => ID_fine_s(i),
         CO(6 downto 0) => open,
         O  => open, 
         CI => ID_fine_s(i-1), 
         CI_TOP => '0', 
         DI(0) => input_clk,
         DI(1) => input_clk,
         DI(2) => input_clk,
         DI(3) => input_clk, 
         DI(4) => input_clk, 
         DI(5) => input_clk, 
         DI(6) => input_clk, 
         DI(7) => input_clk, 
         S  => fine_delay_conf(i*8+7 downto i*8) 
         );
  end generate;

  --First LUT/LD of initial delay line for calibration
  --The (INIT => X"0000_0002") defines the output for the cases when
  --ID_fine_s(ID_fine_s'high)=0 and when ID_fine_s(ID_fine_s'high)=1.
  coarse_init : LUT5 generic map(INIT => X"0000_0002")
    port map (O => ID_coarse_s(0), I0 => ID_fine_s(ID_fine_s'high), I1 => '0', I2 => '0', I3 => '0', I4 => '0');
  coarse_ld_init : LD 
    port map (Q => ID_coarse_s(1), D => ID_coarse_s(0), G => '1');

  --LUTs/FDs of initial delay line for calibration
  pre_buf_chain_gen : for i in 1 to ID_coarse_s'high/2 generate
    attribute RLOC of lut_chain: label is
      "X0" &
      "Y" & integer'image(integer(fine_delay +  i/8));
    attribute RLOC of ld_chain: label is
      "X0" &
      "Y" & integer'image(integer(fine_delay +  i/8));
  begin

    --LUT_CHAIN: define the LUT. The (INIT => x"0000_00ac") defines the output
    --for the corresponding cases.
    lut_chain : LUT5 generic map (INIT => x"0000_00ac")
      port map (O => ID_coarse_s(2*i), I0 => ID_coarse_s(2*i-1), I1 => ID_fine_s(ID_fine_s'high), I2 => initial_delay_conf(i), I3 => '0', I4 => '0');

    --LD_CHAIN: define the transparent LD
    ld_chain : LD 
      port map (Q => ID_coarse_s(2*i+1), D => ID_coarse_s(2*i), G => '1');
  end generate;

  

  --FDs to take the measurements
  measurement_regs : for i in 0 to measurement_s'high generate
  begin
    obs_regs : FD
      port map(Q => measurement_s(i),
           C => shifted_clk,
           D => ID_coarse_s(ID_coarse_s'high)
           );

  end generate;

 measurment <= measurement_s;
end Behavioral;

