-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity FifoDumper is
  Generic ( 
    DATA_WIDTH          : integer := 8;
    N_SAMPLES           : integer := 1024
  );
  Port (
    clk            : in  STD_LOGIC;
    reset_n        : in  STD_LOGIC;
    clk_en_p_i     : in  STD_LOGIC;
    trigger_p_i    : in  STD_LOGIC;
    start_dump     : out STD_LOGIC;
    fifo_dump_idle : out STD_LOGIC;
    data_i         : in  STD_LOGIC_VECTOR (DATA_WIDTH-1      downto 0);
    data_o         : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
    wen_o          : out STD_LOGIC
  );
end FifoDumper;

architecture Behavioral of FifoDumper is

  type CU_states is (IDLE, WRITE, DUMP);
  signal state_reg, state_next: CU_states;

  signal overflow_last_s : std_logic;
  signal cnt_en_s : std_logic;

begin

  -- state register
  state_proc: process(clk) is
  begin
    if(clk'event and clk='1') then
      if(reset_n = '0') then
        state_reg <= IDLE;
      elsif(clk_en_p_i = '1') then
        state_reg <= state_next;
      end if;
    end if;
  end process;

  -- next state logic
  next_state: process(state_reg, trigger_p_i, overflow_last_s) is
  begin
    case state_reg is
      when IDLE =>
        if(trigger_p_i = '1') then
          state_next <= WRITE;
        else
          state_next <= IDLE;
        end if;
      when WRITE =>
        if(overflow_last_s = '1' ) then
          state_next <= DUMP;
        else
          state_next <= WRITE;
        end if;
      when DUMP =>
        state_next <= IDLE;
    end case;
  end process;

  -- Moore output logic
  output_logic: process(state_reg) is
  begin
    case state_reg is
      when IDLE =>
        cnt_en_s       <= '0';
        wen_o          <= '0';
        start_dump     <= '0';
        fifo_dump_idle <= '1';
      when WRITE =>
        cnt_en_s       <= '1';
        wen_o          <= '1';
        start_dump     <= '0';
        fifo_dump_idle <= '0';
      when DUMP =>
        cnt_en_s       <= '0';
        wen_o          <= '0';
        start_dump     <= '1';
        fifo_dump_idle <= '0';
    end case;
  end process;
  
  address_counter: entity work.counter_simple
  GENERIC MAP ( 
    MAX      => N_SAMPLES)
  PORT MAP (
    clk              => clk, 
    clk_en_p         => clk_en_p_i, 
    reset_n          => reset_n, 
    cnt_en           => cnt_en_s, 
    count_o          => open, 
    overflow_o_p     => open, 
    cnt_next_en_o_p  => overflow_last_s
  );

  data_o <= data_i;

end Behavioral;
