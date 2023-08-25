-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity read_fifo_fsm is
  Port( 
    fifo_valid_i : in   STD_LOGIC;
    fifo_empty_i : in   STD_LOGIC;

    fifo_rd_en_o : out  STD_LOGIC;
    reg_en_o     : out  STD_LOGIC;
    dvld_o       : out  STD_LOGIC;


    clk          : in   STD_LOGIC;
    reset_n      : in   STD_LOGIC);
end read_fifo_fsm;

architecture Behavioral of read_fifo_fsm is

  type CU_states is (IDLE, READ, WRITE, WAIT_S);
  signal state_reg, state_next: CU_states;

begin

  -- state register
  state_proc: process(clk) is
  begin
    if(clk'event and clk='1') then
      if(reset_n = '0') then
          state_reg <= IDLE;
      else
        state_reg <= state_next;
      end if;
    end if;
  end process;

  -- next state logic
  next_state: process(state_reg, fifo_valid_i, fifo_empty_i) is
  begin
    
    case state_reg is
      when IDLE =>
        if(fifo_valid_i = '1') then
          state_next <= READ;
        else
          state_next <= IDLE;
        end if;
      when READ =>
        state_next <= WRITE;
      when WRITE =>
        state_next <= WAIT_S;
      when WAIT_S =>
        if(fifo_empty_i = '0') then
          state_next <= IDLE;
        else
          state_next <= WAIT_S;
        end if;
    end case;    
  end process;

   -- Moore output logic
  output_logic: process(state_reg) is
  begin
    -- default values
    fifo_rd_en_o <= '0';
    reg_en_o     <= '0';
    dvld_o       <= '0';
    case state_reg is
      when IDLE =>
        fifo_rd_en_o <= '1';
      when READ =>
        reg_en_o     <= '1';
      when WRITE =>
        dvld_o       <= '1';
      when WAIT_S =>
    end case;
  end process;
  

end architecture;

