-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fifo_wrapper is
  Port(
    Din_i     : in  STD_LOGIC_VECTOR(127 downto 0);
    Dvalid_i  : in  STD_LOGIC;
    Din_ack_o : out STD_LOGIC;

    Dout_o    : out STD_LOGIC_VECTOR(127 downto 0);
    Dvalid_o  : out STD_LOGIC;

    clk_rd    : in  STD_LOGIC;
    clk_wr    : in  STD_LOGIC;
    rst_rd_n  : in STD_LOGIC;
    rst_wr_n  : in  STD_LOGIC);
end fifo_wrapper;

architecture struct of fifo_wrapper is

  COMPONENT fifo_generator_0
    PORT (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      full : OUT STD_LOGIC;
      wr_ack : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      valid : OUT STD_LOGIC;
      wr_rst_busy : OUT STD_LOGIC;
      rd_rst_busy : OUT STD_LOGIC
    );
  END COMPONENT;
  
  signal data_reg_q  : std_logic_vector(127 downto 0);
  signal fifo_dout_s : std_logic_vector(127 downto 0);
  
  signal Dvalid_s     : std_logic;
  signal Din_ack_s    : std_logic;
  signal reg_en_s     : std_logic;
  signal fifo_read_s  : std_logic;
  signal fifo_empty_s : std_logic;
  signal fifo_valid_s : std_logic;
  
  signal reset_p      : std_logic;

begin

  -- FIFO
  fifo: fifo_generator_0
  port map (
    rst         => reset_p, 
    wr_clk      => clk_wr, 
    rd_clk      => clk_rd, 
    din         => Din_i, 
    wr_en       => Dvalid_i, 
    rd_en       => fifo_read_s, 
    dout        => fifo_dout_s, 
    full        => open, 
    wr_ack      => Din_ack_s, 
    empty       => fifo_empty_s, 
    valid       => fifo_valid_s,
    wr_rst_busy => open,
    rd_rst_busy => open
  );
  
  reset_p <= not rst_wr_n;

  -- Data register
  state_proc: process(clk_rd) is
  begin
    if(clk_rd'event and clk_rd='1') then
      if(rst_rd_n = '0') then
        data_reg_q <= (others => '0');
      elsif (reg_en_s = '1') then
        data_reg_q <= fifo_dout_s;
      end if;
    end if;
  end process;

  -- FSM
  fsm: entity work.read_fifo_fsm
  port map(
    fifo_valid_i => fifo_valid_s, 
    fifo_empty_i => fifo_empty_s, 
    fifo_rd_en_o => fifo_read_s, 
    reg_en_o     => reg_en_s, 
    dvld_o       => Dvalid_s, 
    clk          => clk_rd, 
    reset_n      => rst_rd_n 
  );
  
  Dout_o    <= data_reg_q;
  Dvalid_o  <= Dvalid_s;
  Din_ack_o <= Din_ack_s;

end architecture;


