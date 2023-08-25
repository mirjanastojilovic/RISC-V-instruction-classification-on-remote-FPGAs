-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory is
  Port( 
    clk           : in   STD_LOGIC;
    clk_en        : in   STD_LOGIC;
    reset_n       : in   STD_LOGIC;
    mem_valid     : in   STD_LOGIC;
    mem_instr     : in   STD_LOGIC;
    mem_ready     : out  STD_LOGIC;
    mem_addr      : in   STD_LOGIC_VECTOR(12 downto 0);
    mem_wdata     : in   STD_LOGIC_VECTOR(31 downto 0);
    mem_wstrb     : in   STD_LOGIC_VECTOR(3  downto 0); 
    mem_rdata     : out  STD_LOGIC_VECTOR(31 downto 0);
    inst_mem_clk  : in   STD_LOGIC;
    inst_mem_en   : in   STD_LOGIC;
    inst_mem_wen  : in   STD_LOGIC_VECTOR(3  downto 0);
    inst_mem_addr : in   STD_LOGIC_VECTOR(12 downto 0);
    inst_mem_data : in   STD_LOGIC_VECTOR(31 downto 0));
end memory;

architecture Behavioral of memory is

  signal mem_valid_q, mem_ready_q: STD_LOGIC;
  signal one_const : STD_LOGIC := '1';

begin

  process(clk) is
  begin
    if(clk'event and clk='1') then
      if(reset_n = '0') then
        mem_valid_q <= '0';
        mem_ready <= '0';
      elsif(clk_en = '1') then
        mem_valid_q <= mem_valid;
        mem_ready <= mem_ready_q;
      end if;
    end if;
  end process;

  mem_ready_q <= not(mem_valid_q) and mem_valid;
  
  --memory : entity work.blk_mem_gen_0
  --PORT MAP (
  --  clka  => clk,
  --  ena   => '1',
  --  wea   => mem_wstrb,
  --  addra => mem_addr,
  --  dina  => mem_wdata,
  --  douta => mem_rdata
  --);
  memory : entity work.memory_bram
    PORT MAP (
    clka  => clk,
    ena   => one_const,
    wea   => mem_wstrb,
    addra => mem_addr,
    dina  => mem_wdata,
    douta => mem_rdata,
    clkb  => inst_mem_clk,
    enb   => inst_mem_en,
    web   => inst_mem_wen,
    addrb => inst_mem_addr,
    dinb  => inst_mem_data,
    doutb => open
  );
  
end Behavioral;

