-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CPU_tb is
--  Port ( );
end CPU_tb;

architecture Behavioral of CPU_tb is

signal Kin, Din : std_logic_vector(127 downto 0);
signal clk, reset_n, Drdy, krdy, sensor_fifo_read, bsy, en_cpu: std_logic;
signal kvld, sensor_trigger, calib_trg, fsm_dvld, dvld_mux, rst_cpu, reset_fifo, sensor_fifo_dvld, osc_trigger: std_logic;
signal instruction_processed : std_logic_vector(31 downto 0);

type sig_array is array (1 to 5) of std_logic_vector(127 downto 0);
signal instrs : sig_array := (
1 => X"001479b3001479b3001479b300000001",
2 => X"04cf7d1304cf7d1304cf7d1300000001",
3 => X"00e563b304cf7d13001479b300000001",
4 => X"05846393058463930584639300000001",
5 => X"00ce1b3300ce1b3300ce1b3300000001");

begin

  DUT: entity work.CPU_Comp
  port map ( 
    system_clk            => clk,
    timer_clk             => '1',
    reset_n               => reset_n,
    
    Din                   => Din,  -- sim
    Drdy                  => Drdy, -- sim
    bsy                   => bsy,
    fsm_dvld              => fsm_dvld,
    dvld_mux              => dvld_mux,
    sensor_fifo_dvld      => sensor_fifo_dvld, -- sim

    input_data            => Kin, -- sim
    krdy                  => krdy, -- sim
    kvld                  => kvld,

    calib_trg             => calib_trg,
    sensor_fifo_read      => sensor_fifo_read,
    sensor_trigger        => sensor_trigger,
    osc_trigger           => osc_trigger,
    reset_fifo            => reset_fifo,

    instruction_processed => instruction_processed,
    en_cpu                => en_cpu 

  );
        
  clk_gen: process
  begin
    clk <= '1', '0' after 50 ns;
    wait for 100 ns;
  end process;

  tb : PROCESS
  BEGIN

    reset_n <= '0';
    Kin <= (others => '0');
    Din <= (others => '0');
    Drdy <= '0';
    krdy <= '0';
    sensor_fifo_dvld <= '0';
    
    wait for 620 ns;
    
    reset_n <= '1';
    
    wait for 1000 ns;
    
    -- calibration
    Kin <= X"00000000000000000000000000000003";
    krdy <= '1';
    wait for 100 ns;
    krdy <= '0';
    
    wait for 1000 ns;
    
    -- set IDC_IDF
    Kin <= X"fff000000000000000000000fffff000";
    krdy <= '1';
    wait for 100 ns;
    krdy <= '0';
    
    wait for 10000 ns;
    
    -- read a couple of sensor traces
    for i in 0 to 5 loop
      Din <= X"fffffffffffffffffffffffffffffffe";
      Drdy <= '1';
      wait for 100 ns;
      Drdy <= '0';
      
      wait until sensor_fifo_read = '1';
      wait for 500 ns;
      sensor_fifo_dvld <= '1';
      wait for 100 ns;
      sensor_fifo_dvld <= '0';
      
      wait for 1000 ns;
    end loop;

    -- end read of sensor traces
    Din <= X"ffffffffffffffffffffffffffffffff";
    Drdy <= '1';
    wait for 100 ns;
    Drdy <= '0';
    
    wait until dvld_mux = '1';
    
    wait for 10000 ns;
    
    for trace in 0 to 10 loop
    
        -- rst CPU
        Kin <= X"00000000000000000000000000000007";
        krdy <= '1';
        wait for 100 ns;
        krdy <= '0';
        
        wait for 30000 ns;
        
        if(trace mod 2 = 0) then
          Kin <= X"01a2093301a2093301a2093300000000";
        else
          Kin <= X"02888993028889930288899300000000";
        end if;
        krdy <= '1';
        wait for 100 ns;
        krdy <= '0';
        
        wait for 1000 ns;
        
        -- send instructions
        for i in 1 to 5 loop
          if(trace mod 2 = 0) then
            Kin <= X"01a2093301a2093301a2093300000001";
          else
            Kin <= instrs(i);
          end if;
            krdy <= '1';
            wait for 100 ns;
            krdy <= '0';
            
            wait for 1000 ns;
        end loop;
        
        Kin <= X"0000007e0000007e0000007efffffff2";
        krdy <= '1';
        wait for 100 ns;
        krdy <= '0';
        
        wait for 20000 ns;
        
        -- Offset FIFO
        --Din <= X"fffffffffffffffffffffffffff00afc";
        Din <= X"fffffffffffffffffffffffffff03ffc";
        Drdy <= '1';
        wait for 100 ns;
        Drdy <= '0';
        
        for i in 0 to 62 loop
          wait until sensor_fifo_read = '1';
          wait for 500 ns;
          sensor_fifo_dvld <= '1';
          wait for 100 ns;
          sensor_fifo_dvld <= '0';     
        end loop;
        
        wait for 20000 ns;
        
        -- Read rest of sensor traces
        for i in 0 to 5 loop
            Din <= X"fffffffffffffffffffffffffffffffe";
            Drdy <= '1';
            wait for 100 ns;
            Drdy <= '0';
            
            wait until sensor_fifo_read = '1';
            wait for 500 ns;
            sensor_fifo_dvld <= '1';
            wait for 100 ns;
            sensor_fifo_dvld <= '0';
            
            wait for 1000 ns;
        end loop;
        
        Din <= X"ffffffffffffffffffffffffffffffff";
        Drdy <= '1';
        wait for 100 ns;
        Drdy <= '0';
        
        wait until dvld_mux = '1';
        
        wait for 10000 ns;
   
    end loop;
    

    wait; -- will wait forever
  END PROCESS tb;


end Behavioral;