-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.design_package.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter is
  Generic(
    MAX : integer := 1024);
  Port (
    clk              : in  STD_LOGIC;
    clk_en_p         : in  STD_LOGIC;
    reset_p          : in  STD_LOGIC;
    cnt_en           : in  STD_LOGIC;
    count_o          : out  STD_LOGIC_VECTOR (log2(MAX)-1 downto 0);
    mid_overflow_o_p : out  STD_LOGIC;
    overflow_o_p     : out  STD_LOGIC;
    cnt_next_en_o_p  : out  STD_LOGIC);
end counter;

architecture Behavioral of counter is

  signal count_s : unsigned(log2(MAX) downto 0) := (others => '0');
  signal count_q : unsigned(log2(MAX)-1 downto 0) := (others => '0');
  
  attribute use_dsp48 : string;
  attribute use_dsp48 of count_s : signal is "yes";  
  attribute use_dsp48 of count_q : signal is "yes";

begin

  process(clk) is
  begin
    if(clk'event and clk = '1') then
      if(reset_p = '1') then
        count_q <= (others => '0');
        overflow_o_p <= '0';
        cnt_next_en_o_p <= '0';
        mid_overflow_o_p <= '0';
      elsif(clk_en_p = '1') then
        if(cnt_en = '1') then
          if(count_s = MAX) then
            count_q <= (others => '0');
            overflow_o_p <= '1';
          else
            count_q <= count_s(log2(MAX)-1 downto 0);
            overflow_o_p <= '0';
          end if;
          if(count_s = (MAX-1)) then
            cnt_next_en_o_p <= '1';
          else
            cnt_next_en_o_p <= '0';
          end if;
          if(count_s = MAX/2) then
            mid_overflow_o_p <= '1';
          else
            mid_overflow_o_p <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  count_s <= "0"&count_q + 1;
  count_o <= std_logic_vector(count_q);

end Behavioral;

