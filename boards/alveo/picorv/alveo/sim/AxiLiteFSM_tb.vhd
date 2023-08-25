-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;

entity AxiLiteFSM_tb is
--  Port ( );
end AxiLiteFSM_tb;

architecture Behavioral of AxiLiteFSM_tb is

  signal wdata, awaddr : std_logic_vector(31 downto 0);
  signal aclk, aresetn, awvalid, awready, wvalid, wready, bvalid, bready : std_logic;
  signal wstrb : std_logic_vector(3 downto 0);
  signal bresp : std_logic_vector(1 downto 0);
  
  signal sendIt : std_logic;

  signal cpu_en         : std_logic;
  signal cpu_rstn       : std_logic;
  signal cpu_mem_en     : std_logic;
  signal cpu_mem_wen    : std_logic;
  signal cpu_mem_addr   : std_logic_vector(12 downto 0);
  signal cpu_mem_data   : std_logic_vector(31 downto 0);
  signal cpu_trap       : std_logic;
  signal sens_trg       : std_logic;
  signal sens_calib_val : std_logic_vector(127 downto 0);
  signal sens_calib_id  : std_logic_vector(3 downto 0);
  signal sens_calib_trg : std_logic;
  signal base_ptr       : std_logic_vector(63 downto 0);

  type array_type is array (0 to 32) of std_logic_vector(31 downto 0);
  signal data_array : array_type := (
    -- reset system
    X"00000000",
    -- store sensor 0 calib pt 1
    X"FFFFFFFF",
    -- store sensor 0 calib pt 2
    X"FFFFFFFF",
    -- store sensor 0 calib pt 3
    X"0000FFFF",
    -- store sensor 0 calib pt 4
    X"000FFFFF",
    -- store calib to sensor 0
    X"00000001",
    -- store sensor 1 calib pt 1
    X"FFFFFFFF",
    -- store sensor 1 calib pt 2
    X"FFFFFFFF",
    -- store sensor 1 calib pt 3
    X"00FFFFFF",
    -- store sensor 1 calib pt 4
    X"000000FF",
    -- store calib to sensor 1
    X"00000002",
    -- store sensor 2 calib pt 1
    X"FFFFFFFF",
    -- store sensor 2 calib pt 2
    X"FFFFFFFF",
    -- store sensor 2 calib pt 3
    X"00FFFFFF",
    -- store sensor 2 calib pt 4
    X"00FFFFFF",
    -- store calib to sensor 2
    X"00000004",
    -- store sensor 3 calib pt 1
    X"FFFFFFFF",
    -- store sensor 3 calib pt 2
    X"FFFFFFFF",
    -- store sensor 3 calib pt 3
    X"0000000F",
    -- store sensor 3 calib pt 4
    X"00000FFF",
    -- store calib to sensor 3
    X"00000008",
    -- record calib trace
    X"50000000",
    -- store some code 
    X"356A18B5",
    -- store some code 
    X"18C85B21",
    -- store some code 
    X"99FD32AB",
    -- store some code 
    X"A95B12CF",
    -- store some code 
    X"5421FBCD",
    -- store some code 
    X"BCCA4516",
    -- store some code 
    X"FF5159DD",
    -- store some code 
    X"94FADC49",
    -- set dump ptr pt 1
    X"12345678",
    -- set dump ptr pt 2
    X"9ABCD012",
    -- start exec
    X"80000000"
  );

  signal addr_array : array_type := (
    -- reset system
    X"00000000",
    -- store sensor 0 calib pt 1
    X"20000000",
    -- store sensor 0 calib pt 2
    X"20000004",
    -- store sensor 0 calib pt 3
    X"20000008",
    -- store sensor 0 calib pt 4
    X"2000000c",
    -- store calib to sensor 0
    X"40000004",
    -- store sensor 1 calib pt 1
    X"20000000",
    -- store sensor 1 calib pt 2
    X"20000004",
    -- store sensor 1 calib pt 3
    X"20000008",
    -- store sensor 1 calib pt 4
    X"2000000c",
    -- store calib to sensor 1
    X"40000008",
    -- store sensor 2 calib pt 1
    X"20000000",
    -- store sensor 2 calib pt 2
    X"20000004",
    -- store sensor 2 calib pt 3
    X"20000008",
    -- store sensor 2 calib pt 4
    X"2000000c",
    -- store calib to sensor 2
    X"40000010",
    -- store sensor 3 calib pt 1
    X"20000000",
    -- store sensor 3 calib pt 2
    X"20000004",
    -- store sensor 3 calib pt 3
    X"20000008",
    -- store sensor 3 calib pt 4
    X"2000000c",
    -- store calib to sensor 3
    X"40000020",
    -- record calib trace
    X"50000000",
    -- store some code 
    X"10000000",
    -- store some code 
    X"10000004",
    -- store some code 
    X"10000008",
    -- store some code 
    X"1000000c",
    -- store some code 
    X"10000010",
    -- store some code 
    X"10000014",
    -- store some code 
    X"10000018",
    -- store some code 
    X"1000001c",
    -- set dump ptr pt 1
    X"C0000000",
    -- set dump ptr pt 2
    X"C0000004",
    -- start exec
    X"80000000"
  );

begin

  DUT: entity work.AxiLiteFSM
  generic map(
    N_SENSORS            => 4,
    IDC_SIZE             => 32,
    IDF_SIZE             => 96,
    CPU_MEM_SIZE         => 8192,
    C_S00_AXI_DATA_WIDTH => 32,
    C_S00_AXI_ADDR_WIDTH => 32
  )
  port map (

    cpu_en         => cpu_en,
    cpu_rstn       => cpu_rstn,
    cpu_mem_en     => cpu_mem_en,
    cpu_mem_wen    => cpu_mem_wen,
    cpu_mem_addr   => cpu_mem_addr,
    cpu_mem_data   => cpu_mem_data,
    -- TO DRIVE
    cpu_trap       => cpu_trap,
    sens_trg       => sens_trg,
    sens_calib_val => sens_calib_val,
    sens_calib_id  => sens_calib_id,
    sens_calib_trg => sens_calib_trg,
    base_ptr       => base_ptr,

    -- TO DRIVE
    aclk           => aclk,
    -- TO DRIVE
    aresetn        => aresetn,

    -- TO DRIVE
    awaddr         => awaddr,
    -- TO DRIVE
    awvalid        => awvalid,
    awready        => awready,

    -- TO DRIVE
    wdata          => wdata,
    -- TO DRIVE
    wstrb          => wstrb,
    -- TO DRIVE
    wvalid         => wvalid,
    wready         => wready,

    bresp          => bresp,
    bvalid         => bvalid,
    -- TO DRIVE
    bready         => bready
  );

 send : PROCESS
 BEGIN
    awvalid<='0';
    wvalid<='0';
    bready<='0';
    loop
        wait until sendIt = '1';
        wait until aclk= '0';
            awvalid<='1';
        wait until awready = '1';
            wvalid<='1';
        wait until wready = '1';  --Client ready to read address/data        
            --bready<='1';
        wait until bvalid = '1';  -- Write result valid
            assert bresp = "00" report "AXI data not written" severity failure;
            awvalid<='0';
            wvalid<='0';
            bready<='1';
        wait until bvalid = '0';  -- All finished
            bready<='0';
    end loop;
 END PROCESS send;

  clk_gen: process
  begin
    aclk <= '1', '0' after 50 ns;
    wait for 100 ns;
  end process;

  tb : PROCESS
  BEGIN

    aresetn <= '0';
    sendIt <= '0';
    cpu_trap <= '0';

    wait for 1020 ns;

    aresetn <= '1';

    for i in 0 to 32 loop

      awaddr <= addr_array(i);
      wdata <= data_array(i);
      sendIt <= '1';
      wait for 100 ns;
      sendIt <= '0';

      if(awaddr(31 downto 28) = "1000") then 
        wait for 15000 ns;
        cpu_trap <= '1';
        wait for 100 ns;
        cpu_trap <= '0';
      end if;

      --wait until falling_edge(bvalid);
      wait until bvalid = '1';
      wait until bvalid = '0';

    end loop;

    finish;
    wait;
  END PROCESS tb;

end Behavioral;
