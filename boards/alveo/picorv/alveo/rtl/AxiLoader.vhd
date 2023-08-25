-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.design_package.all;

entity AxiLoader is
  generic (
    BRAM_DATA_WIDTH : integer := 32;
    BRAM_ADDR_WIDTH : integer := 12
  );
  port (
    aclk       : in  std_logic;
    aresetn    : in  std_logic;
    -- Load trigger
    start_load : in  std_logic;
    load_idle  : out std_logic;
    load_size  : in  std_logic_vector(31 downto 0);
    base_ptr   : in  std_logic_vector(63 downto 0);
    -- BRAM address interface
    wen        : out std_logic;
    dout       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    addr       : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    -- Axi master read interface
    arid       : out std_logic;
    araddr     : out std_logic_vector(63 downto 0);
    arvalid    : out std_logic;
    arready    : in  std_logic;
    arlen      : out std_logic_vector(7 downto 0);
    arsize     : out std_logic_vector(2 downto 0);
    rdata      : in  std_logic_vector(511 downto 0);
    rvalid     : in  std_logic;
    rready     : out std_logic;
    rid        : in  std_logic
  );
end AxiLoader;

architecture FSM of AxiLoader is

  type states is (IDLE,
                  PUSH_ADDR,
                  WAIT_DATA,
                  STORE_DATA,
                  WRITE_BRAM,
                  INC_BRAM_ADDR);

  signal state_next, state : states;

  signal addr_s : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal araddr_s : unsigned(63 downto 0);
  signal mux_ctrl : unsigned(log2(512/BRAM_DATA_WIDTH)-1 downto 0);
  signal dreg : std_logic_vector(511 downto 0);
  signal araddr_rst, araddr_inc, addr_rst, addr_inc, dreg_en, mux_ctrl_rst, mux_ctrl_inc : std_logic;
  
  constant max_val : unsigned(log2(512/BRAM_DATA_WIDTH)-1 downto 0) := (others => '1');

begin

  fsm_state: process (aclk, aresetn) is
  begin
    if (aclk'event and aclk='1') then
      if (aresetn = '0') then
        state <= IDLE;
        dreg <= (others => '0');
        araddr_s <= unsigned(base_ptr);
        addr_s <= (others => '0');
        mux_ctrl <= (others => '0');
      else
        state <= state_next;
        if (araddr_rst = '1') then
          araddr_s <= unsigned(base_ptr);
        elsif (araddr_inc = '1') then
          araddr_s <= araddr_s + 512/8; 
        end if;
        if (addr_rst = '1') then
          addr_s <= (others => '0');
        elsif (addr_inc = '1') then
          addr_s <= addr_s + 1;
        end if;
        if (dreg_en = '1') then
          dreg <= rdata;
        end if;
        if (mux_ctrl_rst = '1') then
          mux_ctrl <= (others => '0');
        elsif (mux_ctrl_inc = '1') then
          mux_ctrl <= mux_ctrl + 1;
        end if;
      end if;
    end if;
  end process;

  fsm_next_state: process (state, start_load, arready, rvalid, addr_s) is
  begin
    case state is
      when IDLE =>
        if(start_load = '1') then
          state_next <= PUSH_ADDR;
        else
          state_next <= IDLE;
        end if;
      when PUSH_ADDR =>
        if(arready = '1') then
          state_next <= WAIT_DATA;
        else
          state_next <= PUSH_ADDR;
        end if;
      when WAIT_DATA =>
        if(rvalid = '1') then
          state_next <= STORE_DATA;
        else
          state_next <= WAIT_DATA;
        end if;
      when STORE_DATA => 
        state_next <= WRITE_BRAM;
      when WRITE_BRAM =>
        state_next <= INC_BRAM_ADDR; 
      when INC_BRAM_ADDR => 
        -- if we loaded the whole code, we're done
        if (addr_s = unsigned(load_size)-1) then
          state_next <= IDLE;
        -- if we stored all the 512/BRAM_DATA_WIDTH words to the BRAM
        -- then fetch another 512-bit word from DRAM
        elsif (addr_s(log2(512/BRAM_DATA_WIDTH)-1 downto 0) = max_val) then
          state_next <= PUSH_ADDR;
        -- otherwise continue writing the current 512-bit word to DRAM
        else
          state_next <= WRITE_BRAM;
        end if;
    end case;
  end process;

  fsm_output_logic: process (state) is
  begin

    -- default values
    arvalid <= '0';
    rready <= '0';
    dreg_en <= '0';
    araddr_inc <= '0';
    araddr_rst <= '0';
    addr_rst <= '0';
    addr_inc <= '0';
    mux_ctrl_inc <= '0';
    mux_ctrl_rst <= '0';
    wen <= '0';
    load_idle <= '0';

    case state is
      when IDLE =>
        araddr_rst <= '1';
        addr_rst <= '1';
        mux_ctrl_rst <= '1';
        load_idle <= '1';
      when PUSH_ADDR =>
        arvalid <= '1';
      when WAIT_DATA =>
        rready <= '1';
        dreg_en <= '1';
      when STORE_DATA => 
        araddr_inc <= '1';
        mux_ctrl_rst <= '1';
      when WRITE_BRAM => 
        wen <= '1';
      when INC_BRAM_ADDR => 
        addr_inc <= '1';
        mux_ctrl_inc <= '1';
    end case;
    
  end process;

  arid   <= '0';
  arlen  <= X"00";
  -- for 512 bit data, it's 110
  arsize <= "110";
  araddr <= std_logic_vector(araddr_s);
  addr   <= std_logic_vector(addr_s);
  dout   <= dreg((to_integer(mux_ctrl)+1)*BRAM_DATA_WIDTH-1 downto to_integer(mux_ctrl)*BRAM_DATA_WIDTH); 

end FSM;

