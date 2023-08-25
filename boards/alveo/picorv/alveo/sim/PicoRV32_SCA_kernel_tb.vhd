-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;

entity PicoRV32_SCA_kernel_tb is
--  Port ( );
end PicoRV32_SCA_kernel_tb;

architecture Behavioral of PicoRV32_SCA_kernel_tb is

  signal wdata  : std_logic_vector(31 downto 0);
  signal awaddr : std_logic_vector(11 downto 0);
  signal aclk, aresetn, awvalid, awready, wvalid, wready, bvalid, bready : std_logic;
  signal wstrb : std_logic_vector(3 downto 0);
  signal bresp : std_logic_vector(1 downto 0);
  
  signal sendIt : std_logic;

  type code_array_type is array (0 to 1) of std_logic_vector(511 downto 0);
  signal code_array : code_array_type := (
    X"fef080939ed10113fd1181934dd202135d328293d5d30313fff3839300140413287484934a95051318f58593fff606130d4686932ff7071380378793fff80813",
    X"000000000000000000000000000000000000000000000000dde888936bf90913bde98993bb0a0a134a2a8a93cf9b0b133f7b8b93000c0c13fbfc8c9300100073"
  );

  type data_array_type is array (0 to 26) of std_logic_vector(31 downto 0);
  signal data_array : data_array_type := (
    -- reset system
    X"00000000",
    -- store sensor 0 calib pt 1
    -- 32-bit IDC
    X"FFFFF000",
    -- store sensor 0 calib pt 2
    -- 96-bit IDF (upper part)
    X"FFFF0000",
    -- store sensor 0 calib pt 3
    -- 96-bit IDF (middle part)
    X"FFFFFFFF",
    -- store sensor 0 calib pt 4
    -- 96-bit IDF (lower part)
    X"FFFFFFFF",
    -- store calib to sensor 0
    X"00000001",
    -- store sensor 1 calib pt 1
    X"FF000000",
    -- store sensor 1 calib pt 2
    X"FFFFFF00",
    -- store sensor 1 calib pt 3
    X"FFFFFFFF",
    -- store sensor 1 calib pt 4
    X"FFFFFFFF",
    -- store calib to sensor 1
    X"00000002",
    -- store sensor 2 calib pt 1
    X"FFFFFF00",
    -- store sensor 2 calib pt 2
    X"FFFFFF00",
    -- store sensor 2 calib pt 3
    X"FFFFFFFF",
    -- store sensor 2 calib pt 4
    X"FFFFFFFF",
    -- store calib to sensor 2
    X"00000004",
    -- store sensor 3 calib pt 1
    X"FFF00000",
    -- store sensor 3 calib pt 2
    X"F0000000",
    -- store sensor 3 calib pt 3
    X"FFFFFFFF",
    -- store sensor 3 calib pt 4
    X"FFFFFFFF",
    -- store calib to sensor 3
    X"00000008",
    -- record calib trace
    X"50000000",
    -- set dump ptr pt 1
    X"12345678",
    -- set dump ptr pt 2
    X"9ABCD012",
    -- set code length
    X"0000001B",
    -- start loading code 
    X"00000000",
    -- start exec
    X"80000000"
  );

  type addr_array_type is array (0 to 26) of std_logic_vector(11 downto 0);
  signal addr_array : addr_array_type := (
    -- reset system
    X"100",
    -- store sensor 0 calib pt 1
    X"500",
    -- store sensor 0 calib pt 2
    X"504",
    -- store sensor 0 calib pt 3
    X"508",
    -- store sensor 0 calib pt 4
    X"50c",
    -- store calib to sensor 0
    X"600",
    -- store sensor 1 calib pt 1
    X"500",
    -- store sensor 1 calib pt 2
    X"504",
    -- store sensor 1 calib pt 3
    X"508",
    -- store sensor 1 calib pt 4
    X"50c",
    -- store calib to sensor 1
    X"600",
    -- store sensor 2 calib pt 1
    X"500",
    -- store sensor 2 calib pt 2
    X"504",
    -- store sensor 2 calib pt 3
    X"508",
    -- store sensor 2 calib pt 4
    X"50c",
    -- store calib to sensor 2
    X"600",
    -- store sensor 3 calib pt 1
    X"500",
    -- store sensor 3 calib pt 2
    X"504",
    -- store sensor 3 calib pt 3
    X"508",
    -- store sensor 3 calib pt 4
    X"50c",
    -- store calib to sensor 3
    X"600",
    -- record calib trace
    X"700",
    -- set dump ptr pt 1
    X"200",
    -- set dump ptr pt 2
    X"204",
    -- set code length
    X"300",
    -- start loading code 
    X"400",
    -- start exec
    X"800"
  );

  signal m_awaddr : std_logic_vector(63 downto 0);

  signal m_wdata : std_logic_vector(511 downto 0);
  signal m_awvalid, m_awready, m_wvalid, m_wready, m_bvalid, m_bready : std_logic;
  signal m_awlen : std_logic_vector(7 downto 0);
  signal m_awsize : std_logic_vector(2 downto 0);
  signal m_wstrb : std_logic_vector(63 downto 0);
  signal m_bresp : std_logic_vector(1 downto 0);

  signal m_rdata : std_logic_vector(511 downto 0);
  signal m_araddr : std_logic_vector(63 downto 0);
  signal m_arvalid, m_arready, m_rvalid, m_rready, m_arid, m_rid : std_logic;
  signal m_arlen : std_logic_vector(7 downto 0);
  signal m_arsize : std_logic_vector(2 downto 0);

begin
  
  DUT: entity work.PicoRV32_SCA_kernel
  port map (
    ap_clk                => aclk,
    ap_rst_n              => aresetn,
    -- AXI Master
    -- Dumps the BRAM content to DRAM
    m_axi_bank_0_AWADDR   => m_awaddr,
    m_axi_bank_0_AWLEN    => m_awlen,
    m_axi_bank_0_AWSIZE   => m_awsize,
    m_axi_bank_0_AWVALID  => m_awvalid,
    m_axi_bank_0_AWREADY  => m_awready,
    m_axi_bank_0_WDATA    => m_wdata,
    m_axi_bank_0_WSTRB    => m_wstrb,
    m_axi_bank_0_WVALID   => m_wvalid,
    m_axi_bank_0_WREADY   => m_wready,
    m_axi_bank_0_BRESP    => m_bresp,
    m_axi_bank_0_BVALID   => m_bvalid,
    m_axi_bank_0_BREADY   => m_bready,
    -- Dumps the DRAM content to BRAM
    m_axi_bank_0_ARID     => m_arid,
    m_axi_bank_0_ARADDR   => m_araddr,
    m_axi_bank_0_ARVALID  => m_arvalid,
    m_axi_bank_0_ARREADY  => m_arready,
    m_axi_bank_0_ARLEN    => m_arlen,
    m_axi_bank_0_ARSIZE   => m_arsize,
    m_axi_bank_0_RDATA    => m_rdata,
    m_axi_bank_0_RVALID   => m_rvalid,
    m_axi_bank_0_RREADY   => m_rready,
    m_axi_bank_0_RID      => m_rid,
    -- AXI Lite Slave
    -- Used by the host to configure the experiments 
    s_axi_control_AWADDR  => awaddr,
    s_axi_control_AWVALID => awvalid,
    s_axi_control_AWREADY => awready,
    s_axi_control_WDATA   => wdata,
    s_axi_control_WSTRB   => wstrb,
    s_axi_control_WVALID  => wvalid,
    s_axi_control_WREADY  => wready,
    s_axi_control_BRESP   => bresp,
    s_axi_control_BVALID  => bvalid,
    s_axi_control_BREADY  => bready,
    s_axi_control_ARADDR  => (others => '0'),
    s_axi_control_ARVALID => '0',
    s_axi_control_ARREADY => open,
    s_axi_control_RDATA   => open,
    s_axi_control_RRESP   => open,
    s_axi_control_RVALID  => open,
    s_axi_control_RREADY  => '0'
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

    wait for 1020 ns;

    aresetn <= '1';

    for i in 0 to 26 loop

      awaddr <= addr_array(i);
      wdata <= data_array(i);
      sendIt <= '1';
      wait for 100 ns;
      sendIt <= '0';

      --wait until falling_edge(bvalid);
      wait until bvalid = '1';
      wait until bvalid = '0';
      
      if(awaddr(awaddr'left downto awaddr'left-3) = X"7") then
        for i in 0 to 127 loop
            wait until m_wready = '1';
            wait until m_bvalid = '1';
        end loop;
      end if;
      
      if(awaddr(awaddr'left downto awaddr'left-3) = X"4") then
        for i in 0 to 1 loop
            wait until m_rready = '1';
            wait until m_rvalid = '1';
        end loop;
        wait for 10000 ns;
      end if;

    end loop;

    --finish;
    wait;
  END PROCESS tb;

  master_tb : PROCESS
  BEGIN

    m_awready <= '0';
    m_wready <= '0';
    m_bresp <= "00";
    m_bvalid <= '0';

    wait until aresetn = '1';

    for i in 1 to 1024 loop
      if(m_awvalid /= '1') then
        wait until m_awvalid = '1';
      end if;
      wait for 520 ns;
      m_awready <= '1';
      wait for 100 ns;
      m_awready <= '0';

      if(m_wvalid /= '1') then
        wait until m_wvalid = '1';
      end if;
      wait for 520 ns;
      m_wready <= '1';
      wait for 100 ns;
      m_wready <= '0';

      m_bvalid <= '1';
      wait for 100 ns;
      m_bvalid <= '0';

    end loop;

    wait until m_awvalid = '1';
    m_awready <= '1';
    m_wready <= '1';
    m_bvalid <= '1';

    wait;

  END PROCESS master_tb;

  master_read_tb : PROCESS
  BEGIN

    m_arready <= '0';
    m_rvalid <= '0';
    m_rid <= '0';
    m_rdata <= (others => '0');

    wait until aresetn = '1';

    for i in 0 to 1 loop

      if(m_arvalid /= '1') then
        wait until m_arvalid = '1';
      end if;
      wait for 520 ns;
      m_arready <= '1';
      wait for 100 ns;
      m_arready <= '0';

      wait for 300 ns;
      m_rvalid <= '1';
      m_rdata <= code_array(i);
      if(m_rready /= '1') then
        wait until m_rready = '1';
      end if;
      wait for 100 ns;
      m_rvalid <= '0';
    
    end loop;

    wait;
  END PROCESS master_read_tb;



end Behavioral;
