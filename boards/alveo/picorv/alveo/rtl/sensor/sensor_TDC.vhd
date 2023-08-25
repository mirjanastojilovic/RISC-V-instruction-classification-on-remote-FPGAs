-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity sensor is
  generic (
    initial_delay      : integer := 16; -- length of elements preceding the sensor
    fine_delay         : integer := 8; -- intermediate carry8 elements
    observable_delay   : integer := 64; -- 64 registers are used for the measurments
    set_number         : integer := 1 -- Unique number per sensor instance to group  them in the same RLOC system
  );
  port (
    input_clk          : in  std_logic;
    shifted_clk        : in  std_logic;
    initial_delay_conf : in  std_logic_vector(initial_delay-1 downto 0);
    fine_delay_conf    : in  std_logic_vector(8*fine_delay-1 downto 0);
    measurment         : out std_logic_vector(observable_delay - 1 downto 0)
  );
end sensor;

architecture Behavioral of sensor is

  component LUT5 -- LUT in first part of delay chain
    generic (INIT: bit_vector(31 downto 0) := x"2222_2222");
    port (O  : out std_ulogic;
          I0 : in std_ulogic;
          I1 : in std_ulogic;
          I2 : in std_ulogic;
          I3 : in std_ulogic;
          I4 : in std_ulogic
          );
  end component;

  component CARRY8 -- used in last part of delay chain
    port(
      CO     : out std_logic_vector(7 downto 0);
      O      : out std_logic_vector(7 downto 0);
      CI     : in std_ulogic := 'L';
      CI_TOP : in std_ulogic := 'L';
      DI     : in std_logic_vector(7 downto 0);
      S      : in std_logic_vector(7 downto 0)
      );
  end component;

  component LD -- used at the samme time as LUT5 to fill CLBs
    generic(INIT : bit := '0');
    port(Q : out std_ulogic := '0';
         D : in std_ulogic;
         G : in std_ulogic
         );
  end component;

  component FD -- register, used at the end to take measurments
    generic(INIT : bit := '0');
    port(Q : out std_ulogic;
         C : in std_ulogic;
         D : in std_ulogic
         );
  end component;

  signal chain_clk : std_ulogic;

  signal pre_chain : std_logic_vector(2 * initial_delay - 1 downto 0); -- wiring
  signal clk_vector : std_logic_vector(3 downto 0);
  signal fine_chain : std_logic_vector(fine_delay - 1 downto 0);
  signal chain : std_logic_vector(observable_delay - 1 downto 0);

  signal reg_res : std_logic_vector(observable_delay - 1 downto 0) := (others => '0');

  attribute keep_hierarchy : string; -- keep the tdc comp for ucf file
  attribute keep_hierarchy of Behavioral: architecture is "true";

  -- set instantiation type, avoid warnings
  attribute box_type : string;
  attribute box_type of CARRY8 : component is "black_box";
  attribute box_type of LUT5 : component is "black_box";
  attribute box_type of LD : component is "black_box";
  attribute box_type of FD : component is "black_box";

  -- set user set constraints
  attribute U_SET : string;

  attribute U_SET of coarse_init : label is "chainset" & integer'image(set_number);
  attribute U_SET of coarse_ld_init : label is "chainset" & integer'image(set_number);
  attribute U_SET of pre_buf_chain_gen : label is "chainset" & integer'image(set_number);
  attribute U_SET of first_fine_carry : label is "chainset" & integer'image(set_number);
  attribute U_SET of fine_chain_carry : label is "chainset" & integer'image(set_number);
  attribute U_SET of first_obs_carry : label is "chainset" & integer'image(set_number);
  attribute U_SET of measurment_chain_obs : label is "chainset" & integer'image(set_number);
  attribute U_SET of measurment_chain_regs : label is "chainset" & integer'image(set_number);

  attribute U_SET of pre_chain : signal is "chainset" & integer'image(set_number);
  attribute U_SET of fine_chain : signal is "chainset" & integer'image(set_number);
  attribute U_SET of chain : signal is "chainset" & integer'image(set_number);
  attribute U_SET of reg_res : signal is "chainset" & integer'image(set_number);

  attribute U_SET of CARRY8 : component is "chainset" & integer'image(set_number);
  attribute U_SET of LUT5 : component is "chainset" & integer'image(set_number);
  attribute U_SET of LD : component is "chainset" & integer'image(set_number);
  attribute U_SET of FD : component is "chainset" & integer'image(set_number);

  -- save nets constraints
  attribute S : string; -- prevent trimming (logic optimisation)
  attribute keep : string; -- keep externally visible in synthesis
  attribute syn_keep : string; -- keep externally visible
  
  attribute DONT_TOUCH : string;

  attribute KEEP of pre_chain : signal is "true";
  attribute DONT_TOUCH of pre_chain : signal is "true";
  attribute S of pre_chain : signal is "true"; -- somehow translated to keep?
  attribute S of fine_chain : signal is "true";
  attribute S of chain : signal is "true";
  attribute S of reg_res : signal is "true";

  attribute keep of reg_res: signal is "true";
  attribute keep of chain_clk : signal is "true";
  attribute keep of input_clk: signal is "true";
  attribute keep of fine_chain : signal is "true";
  --attribute keep of chain : signal is "true";

  attribute syn_keep of pre_buf_chain_gen : label is "true";
  attribute syn_keep of fine_chain_carry : label is "true";
  attribute syn_keep of measurment_chain_obs : label is "true";
  attribute syn_keep of measurment_chain_regs : label is "true";

  attribute S of pre_buf_chain_gen : label is "true";
  attribute S of fine_chain_carry : label is "true";
  attribute S of measurment_chain_obs : label is "true";
  attribute S of measurment_chain_regs : label is "true";

  attribute S of coarse_init : label is "true";
  attribute S of coarse_ld_init : label is "true";
  attribute S of first_fine_carry : label is "true";
  --attribute keep of first_inter_carry : label is "true";
  attribute S of first_obs_carry : label is "true";

  -- all registers at the end of the chain are equivalent, don't remove
  attribute equivalent_register_removal: string;
  attribute equivalent_register_removal of reg_res : signal is "no";

  -- problems when you plug a clock as an input
  attribute clock_signal : string;
  attribute clock_signal of fine_chain : signal is "no";
  attribute clock_signal of pre_chain : signal is "no";
  attribute clock_signal of chain : signal is "no";

  attribute maxdelay : string;
  attribute maxdelay of chain : signal is "1000ms";
  attribute maxdelay of pre_chain : signal is "1000ms";
  attribute maxdelay of fine_chain : signal is "1000ms";

  -- define necessary general bel location
  type numlut_bel_t is array(7 downto 0) of string(1 to 5);
  constant lutbel : numlut_bel_t := ("H6LUT", "G6LUT", "F6LUT", "E6LUT", "D6LUT", "C6LUT", "B6LUT", "A6LUT");

  type ff_bel_t is array(7 downto 0) of string(1 to 3);
  --constant ffbel : ff_bel_t := ("FFH", "FFG", "FFF", "FFE", "FFD", "FFC", "FFB", "FFA");
  constant ffbel : ff_bel_t := ("HFF", "GFF", "FFF", "EFF", "DFF", "CFF", "BFF", "AFF");

  type ld_bel_t is array(7 downto 0) of string(1 to 4);
  --constant ldbel : ld_bel_t := ("FFH", "FFG", "FFF", "FFE", "FFD", "FFC", "FFB", "FFA");
  constant ldbel : ld_bel_t := ("HFF2", "GFF2", "FFF2", "EFF2", "DFF2", "CFF2", "BFF2", "AFF2");

  -- define locations
  attribute rloc_origin : string;
  --attribute rloc_origin of sensor_init: label is "X10Y50";
  --attribute rloc_origin of first_fine_carry: label is "X10Y50";
  --attribute rloc_origin of first_fine_carry: label is "X10Y82";

  attribute RLOC : string;
  attribute BEL : string;

  attribute RLOC of coarse_init: label is
    "X0" &
    "Y" & integer'image(integer(fine_delay)); -- ceil(initial_delay/4)
  attribute RLOC of coarse_ld_init: label is
    "X0" &
    "Y" & integer'image(integer(fine_delay)); -- ceil(initial_delay/4)
  attribute BEL of coarse_init: label is lutbel(0);
  attribute BEL of coarse_ld_init: label is ldbel(0);

  attribute RLOC of first_fine_carry: label is "X0Y0";
  --  "X0" &
  --  "Y" & integer'image(integer((initial_delay+4-1) / 4)); -- ceil(initial_delay/4)

  attribute RLOC of first_obs_carry: label is
    "X0" &
    "Y" & integer'image(integer((initial_delay+8-1) / 8  + fine_delay)); -- ceil(initial_delay/4)

begin
  -- instantiate chain
  
  -- fine initial delay, used for fine callibration
  first_fine_carry : CARRY8
    port map (
      CO(7) => fine_chain(0), -- output
      CO(6 downto 0) => open,
      O  => open, -- unused
      CI => input_clk, -- init: in CYINIT
      CI_TOP => '0', -- init: in CYINIT
      DI(0) => input_clk,
      DI(1) => input_clk,
      DI(2) => input_clk,
      DI(3) => input_clk, 
      DI(4) => input_clk, 
      DI(5) => input_clk, 
      DI(6) => input_clk, 
      DI(7) => input_clk, 
      S  => fine_delay_conf(7 downto 0) -- select carry path (not DI)
      );

  fine_chain_carry : for i in 1 to (fine_chain'high) generate
    attribute RLOC of fine_carry: label is
      "X0" &
      "Y" & integer'image(integer(i)); -- ceil(initial_delay/4)+i
  begin
    fine_carry : CARRY8
      port map (
        CO(7) => fine_chain(i), -- output
        CO(6 downto 0) => open,
        O  => open, -- unused
        CI => fine_chain(i-1), -- use cout path
        CI_TOP => '0', -- use cout path
        DI(0) => input_clk,
        DI(1) => input_clk,
        DI(2) => input_clk,
        DI(3) => input_clk, 
        DI(4) => input_clk, 
        DI(5) => input_clk, 
        DI(6) => input_clk, 
        DI(7) => input_clk, 
        S  => fine_delay_conf(i*8+7 downto i*8) -- select carry path (not DI)
        );
  end generate;

  -- coarse observable delay, used for coarse calibration
  coarse_init : LUT5 generic map(INIT => X"2222_2222")
    port map (O => pre_chain(0), I0 => fine_chain(fine_chain'high), I1 => '0', I2 => '0', I3 => '0', I4 => '0');

  coarse_ld_init : LD -- critical path incrementor latch
    port map (Q => pre_chain(1), D => pre_chain(0), G => '1');

  pre_buf_chain_gen : for i in 1 to pre_chain'high/2 generate
    attribute RLOC of lut_chain: label is
      "X0" &
      "Y" & integer'image(integer(fine_delay + i/8 ));
    attribute RLOC of ld_chain: label is
      "X0" &
      "Y" & integer'image(integer(fine_delay + i/8 ));
    attribute BEL of lut_chain: label is lutbel(integer(i MOD lutbel'length));
    attribute BEL of ld_chain: label is ldbel(integer(i MOD ldbel'length));
  begin
    lut_chain : LUT5 generic map (INIT => x"acac_acac")
      port map (O => pre_chain(2*i), I0 => pre_chain(2*i-1), I1 => fine_chain(fine_chain'high), I2 => initial_delay_conf(i), I3 => '0', I4 => '0');
    ld_chain : LD -- transparent latch
      port map (Q => pre_chain(2*i+1), D => pre_chain(2*i), G => '1');
  end generate;

  -- last part, measurment part, always same length
  first_obs_carry : CARRY8
    port map (
      CO => chain(7 downto 0), -- output
      O  => open, -- unused
      CI => pre_chain(pre_chain'high), -- init: in CYINIT
      CI_TOP => '0', -- init: in CYINIT
      DI => x"00", -- unused
      S  => x"FF" -- select carry path (not DI)
      );

  measurment_chain_obs : for i in 1 to (observable_delay)/8 - 1 generate
    attribute RLOC of obs_carry: label is
      "X0" &
      "Y" & integer'image(integer((initial_delay+8-1) / 8 + fine_delay+ i)); -- ceil(initial_delay/4)
  begin
    obs_carry : CARRY8
      port map (
        CO => chain(i * 8 + 7 downto i * 8), -- outputxs
        O  => open, -- unused
        CI => chain(i * 8 - 1), -- use cout path
        CI_TOP => '0', -- use cout path
        DI => x"00", -- unused
        S  => x"FF" -- select carry path (not DI)
        );
  end generate;

  measurment_chain_regs : for i in 0 to reg_res'high generate
    attribute RLOC of obs_regs: label is
    "X0" &
    "Y" & integer'image(integer((initial_delay+8-1) / 8 + fine_delay + i/8)); -- ceil(initial_delay/4)
    attribute BEL of obs_regs: label is ffbel(integer(i MOD ffbel'length));
  begin
    obs_regs : FD
      port map(Q => reg_res(i),
           C => shifted_clk,
           D => chain(i)
           );

  end generate;

  measurment <= reg_res;

end Behavioral;

