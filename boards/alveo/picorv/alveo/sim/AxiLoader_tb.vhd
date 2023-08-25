-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;

entity AxiLoader_tb is
--  Port ( );
end AxiLoader_tb;

architecture Behavioral of AxiLoader_tb is

  type data_array_type is array (1 to 5) of std_logic_vector(511 downto 0);
  signal data_array : data_array_type := (
    X"51d9a13ba39a73155c4ec90219ab810c3a288de6b1647b063b3ab02d74bbe6d798928386e2e3ad428a25483394bbba5e7ce032fbd1a42d374ba18463e4721ad5",
    X"82fdcf14623082263549cf7ca8327b46abbb6702436224fb8fae5cfc9d6953462d9bb2eb11c4e6cf6027c14a5c29c132e2a86d51ed162c9e6e799ccbceb130df",
    X"1b3df15af54242691b5a6e7117cc0abe070b809930b83c200e07ae104cb410d67cc04a997f13d364b131a821c867ce6ce988e05d134608bc2786eeea42288cb0",
    X"e741a6bfded45b395f782695c8538fb80dce9ea38075b2510d9be03a6046d32381a405fedd753d1fcdd4f5923739b38a9b466a51d5454935398b3c8dfdb9b744",
    X"9091bd68d41c5a2c170e868d79291cf284c96ceae492b96723e85b7c1bddf7860231a7ddd4ce6009f9d70ba35667904f934f1b2009df6ebfeb95733c900984f5"
  );

  type base_ptr_type is array (1 to 2) of std_logic_vector(63 downto 0);
  type load_size_type is array (1 to 2) of std_logic_vector(31 downto 0);
  signal base_ptr_array : base_ptr_type := (
    X"0000000000000000",
    X"0123456789abcdef"
  );
  signal load_size_array : load_size_type := (
    X"00000050",
    X"00000017"
  );


  signal base_ptr, araddr : std_logic_vector(63 downto 0);
  signal rdata : std_logic_vector(511 downto 0);

  signal douta, load_size : std_logic_vector(31 downto 0);
  signal addra : std_logic_vector(11 downto 0);
  signal wen, trigger, clk, reset_n, arvalid, arready, rvalid, rready, arid, rid : std_logic;
  signal arlen : std_logic_vector(7 downto 0);
  signal arsize : std_logic_vector(2 downto 0);
  signal wen_concat : std_logic_vector(3 downto 0);

begin

  DUT: entity work.AxiLoader
  generic map(
    BRAM_DATA_WIDTH => 32,
    BRAM_ADDR_WIDTH => 12)
  port map (

    dout      => douta,
    addr      => addra,
    wen        => wen,

    start_load => trigger,
    load_size  => load_size,
    base_ptr   => base_ptr,

    aclk       => clk,
    aresetn    => reset_n,

    arid       => arid,
    araddr     => araddr,
    arvalid    => arvalid,
    arready    => arready,
    arlen      => arlen,
    arsize     => arsize,

    rdata      => rdata,
    rvalid     => rvalid,
    rready     => rready,
    rid        => rid
  );

  BRAM: entity work.blk_mem_gen_0
    PORT MAP (
    clka  => clk,
    ena   => '1',
    wea   => wen_concat,
    addra => addra,
    dina  => douta,
    douta => open,
    clkb  => clk,
    enb   => '0',
    web   => (others => '0'),
    addrb => (others => '0'),
    dinb  => (others => '0'),
    doutb => open
  );
  
  wen_concat <= wen & wen & wen & wen;

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
    arready <= '0';
    rvalid <= '0';
    rid <= '0';
    rdata <= (others => '0');

    wait for 620 ns;

    reset_n <= '1';

    for j in 1 to 2 loop

        wait for 10000 ns;

        trigger <= '1';
        base_ptr <= base_ptr_array(j);
        load_size <= load_size_array(1);

        wait for 100 ns;
        trigger <= '0';

        for i in 1 to 5 loop
          if(arvalid /= '1') then
            wait until arvalid = '1';
          end if;
          wait for 520 ns;
          arready <= '1';
          wait for 100 ns;
          arready <= '0';

          wait for 300 ns;
          rvalid <= '1';
          rdata <= data_array(i);
          if(rready /= '1') then
            wait until rready = '1';
          end if;
          wait for 100 ns;
          rvalid <= '0';

        end loop;
        
        wait for 10000 ns;

        trigger <= '1';
        base_ptr <= base_ptr_array(j);
        load_size <= load_size_array(2);

        wait for 100 ns;
        trigger <= '0';

        for i in 1 to 2 loop
          if(arvalid /= '1') then
            wait until arvalid = '1';
          end if;
          wait for 520 ns;
          arready <= '1';
          wait for 100 ns;
          arready <= '0';

          wait for 300 ns;
          rvalid <= '1';
          rdata <= data_array(i);
          if(rready /= '1') then
            wait until rready = '1';
          end if;
          wait for 100 ns;
          rvalid <= '0';

        end loop;
    end loop;
    
    wait for 10000 ns;

    finish;
  END PROCESS tb;


end Behavioral;
