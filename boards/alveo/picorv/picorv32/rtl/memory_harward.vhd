-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory_harward is
  Port( 
    clk       : in   STD_LOGIC;
    mem_valid : in   STD_LOGIC;
    mem_instr : in   STD_LOGIC;
    mem_ready : out  STD_LOGIC;
    mem_addr  : in   STD_LOGIC_VECTOR(11 downto 0);
    mem_wdata : in   STD_LOGIC_VECTOR(31 downto 0);
    mem_wstrb : in   STD_LOGIC_VECTOR(3 downto 0); 
    mem_rdata : out  STD_LOGIC_VECTOR(31 downto 0));
end memory_harward;

architecture Behavioral of memory_harward is

  signal mem_valid_q, mem_ready_q: STD_LOGIC;
  signal imem_wstrb, dmem_wstrb : STD_LOGIC_VECTOR(3 downto 0);
  signal imem_addr, dmem_addr : STD_LOGIC_VECTOR(11 downto 0);
  signal imem_wdata, dmem_wdata : STD_LOGIC_VECTOR(31 downto 0);
  signal imem_rdata, dmem_rdata : STD_LOGIC_VECTOR(31 downto 0);


begin

  -- valid delay 
  process(clk) is
  begin
    if(clk'event and clk='1') then
      mem_valid_q <= mem_valid;
      mem_ready <= mem_ready_q;
    end if;
  end process;

  mem_ready_q <= not(mem_valid_q) and mem_valid;

  process(mem_instr, mem_wstrb, mem_addr, mem_wdata, dmem_rdata, imem_rdata) is
  begin
    if(mem_instr = '0') then
      imem_wstrb <= (others => '0');
      imem_addr  <= (others => '0');
      imem_wdata <= (others => '0');
      dmem_wstrb <= mem_wstrb;
      dmem_addr  <= mem_addr;
      dmem_wdata <= mem_wdata;

      mem_rdata  <= dmem_rdata;
    else
      imem_wstrb <= mem_wstrb;
      imem_addr  <= mem_addr;
      imem_wdata <= mem_wdata;
      dmem_wstrb <= (others => '0');
      dmem_addr  <= (others => '0');
      dmem_wdata <= (others => '0');

      mem_rdata  <= imem_rdata;
    end if;
  end process;
  
  instruction_memory : entity work.blk_mem_gen_0
  PORT MAP (
    clka  => clk,
    ena   => '1',
    wea   => imem_wstrb,
    addra => imem_addr,
    dina  => imem_wdata,
    douta => imem_rdata
  );

  data_memory : entity work.blk_mem_gen_1
  PORT MAP (
    clka  => clk,
    ena   => '1',
    wea   => dmem_wstrb,
    addra => dmem_addr,
    dina  => dmem_wdata,
    douta => dmem_rdata
  );
  
  
end Behavioral;

