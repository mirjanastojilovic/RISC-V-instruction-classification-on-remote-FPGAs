-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;

entity AxiFlusher_tb is
--  Port ( );
end AxiFlusher_tb;

architecture Behavioral of AxiFlusher_tb is

  signal base_ptr, awaddr : std_logic_vector(63 downto 0);

  signal douta, wdata : std_logic_vector(31 downto 0);
  signal addra : std_logic_vector(11 downto 0);
  signal ena, trigger, clk, reset_n, awvalid, awready, wvalid, wready, bvalid, bready : std_logic;
  signal awlen : std_logic_vector(7 downto 0);
  signal awsize : std_logic_vector(2 downto 0);
  signal wstrb : std_logic_vector(3 downto 0);
  signal bresp : std_logic_vector(1 downto 0);

begin

  DUT: entity work.AxiFLusher
  generic map(
    BRAM_DATA_WIDTH => 32,
    BRAM_ADDR_WIDTH => 12,
    WRITE_LENGTH    => 128)
  port map (
    base_ptr   => base_ptr,

    douta      => douta,
    addra      => addra,
    ena        => ena,

    start_dump => trigger,


    aclk       => clk,
    aresetn    => reset_n,

    awaddr     => awaddr,
    awlen      => awlen,
    awsize     => awsize,
    awvalid    => awvalid,
    awready    => awready,

    wdata      => wdata,
    wstrb      => wstrb,
    wvalid     => wvalid,
    wready     => wready,

    bresp      => bresp,
    bvalid     => bvalid,
    bready     => bready
  );

  BRAM: entity work.blk_mem_gen_0
    PORT MAP (
    clka  => clk,
    ena   => ena,
    wea   => "0",
    addra => addra,
    dina  => (others => '0'),
    douta => douta,
    clkb  => clk,
    enb   => '0',
    web   => "0",
    addrb => (others => '0'),
    dinb  => (others => '0'),
    doutb => open
  );

  clk_gen: process
  begin
    clk <= '1', '0' after 50 ns;
    wait for 100 ns;
  end process;

  tb : PROCESS
  BEGIN

    reset_n <= '0';
    trigger <= '0';
    base_ptr <= (others => '0');
    awready <= '0';
    wready <= '0';
    bresp <= "00";
    bvalid <= '0';

    wait for 620 ns;

    reset_n <= '1';

    wait for 1000 ns;

    trigger <= '1';

    for i in 1 to 5 loop
      if(awvalid /= '1') then
        wait until awvalid = '1';
      end if;
      wait for 520 ns;
      awready <= '1';
      wait for 100 ns;
      awready <= '0';

      if(wvalid /= '1') then
        wait until wvalid = '1';
      end if;
      wait for 520 ns;
      wready <= '1';
      wait for 100 ns;
      wready <= '0';

      bvalid <= '1';
      wait for 100 ns;
      bvalid <= '0';

    end loop;

    wait until awvalid = '1';
    awready <= '1';
    wready <= '1';
    bvalid <= '1';

    wait;

    finish;
  END PROCESS tb;


end Behavioral;
