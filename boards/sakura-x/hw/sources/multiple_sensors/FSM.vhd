-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.ry_utilities.all;

entity FSM is
  Generic(
    N_SENSORS : integer := 1);
  Port (
    input_data       : in  std_logic_vector (127 downto 0);
    krdy             : in  std_logic;
    kvld             : out std_logic;

    Din              : in  std_logic_vector(127 downto 0);
    Drdy             : in  std_logic;
    bsy              : out std_logic;
    fsm_dvld         : out std_logic;
    dvld_mux         : out std_logic;
    sensor_fifo_dvld : in  std_logic;

    instr            : out std_logic_vector(31 downto 0);
    inst_mem_addr    : out std_logic_vector(11 downto 0);
    inst_mem_en      : out std_logic;
    inst_mem_wen     : out std_logic_vector(0 downto 0);
    en_cpu           : out std_logic;
    rst_cpu          : out std_logic;
    exception        : in  std_logic;
    instr_processed  : in  std_logic_vector(31 downto 0);


    calib_trg        : out std_logic;
    sens_calib_id    : out std_logic_vector(N_SENSORS-1 downto 0);
    sensor_fifo_read : out std_logic;
    sensor_trigger   : out std_logic;
    osc_trigger      : out std_logic;
    reset_fifo       : out std_logic;

    EN  : in std_logic;
    rst : in STD_LOGIC;
    clk : in STD_LOGIC
  );
       
end FSM;

architecture FSM_arch of FSM is

  type states is (IDLE,
                  GET_CMD, 
                  GET_CALIBRATION,
                  CALIBRATE, 
                  WAIT_CALIB,
                  SENS_TRG,
                  RESET_LOGIC, 
                  START_WRITE_INST1,
                  START_WRITE_INST2,
                  START_WRITE_INST3,
                  WRITE_INST1,
                  WRITE_INST2,
                  WRITE_INST3,
                  END_WRITE_INST1,
                  END_WRITE_INST2,
                  END_WRITE_INST3,
                  START_EXEC,
                  ADD_DELAY,
                  EXEC,
                  FINISH_EXEC,
                  RESET_ENABLE,
                  RESET_CPU,
                  WAIT_DATA_CMD,
                  DECODE_CMD,
                  STORE_START_SENS_SAMPLE,
                  EMPTY_SENS_READ,
                  INC_EMPTY_CNT,
                  END_SENS_EMPTY,
                  READ_SENSOR,
                  END_TRACE);

  signal State_next, State : states;
  
  signal addr_counter       : integer := 0;
  signal delay_nb           : integer := 0;
  signal delay_rst          : integer := 0;
  signal sample_cnt         : integer := 0;
  signal en_address_counter : std_logic := '0';
  signal en_delay_counter   : std_logic := '0';
  signal en_delay_reset     : std_logic := '0';
  signal reset_cnt          : std_logic := '0';
  signal reset_addr_cnt     : std_logic := '0';
  signal reset_fifo_s       : std_logic := '0';
  signal wait_cnt_en        : std_logic := '0';
  signal wait_cnt_overflow  : std_logic := '0';
  signal start_sample_en    : std_logic := '0';
  signal sample_cnt_rst     : std_logic := '0';
  signal sample_cnt_en      : std_logic := '0';
  signal calib_trg_s        : std_logic := '0';
  signal start_sample       : std_logic_vector(11 downto 0);
  signal sens_calib_id_s      : std_logic_vector(N_SENSORS-1 downto 0);

begin

  calib_trg <= calib_trg_s;
  sens_calib_id <= sens_calib_id_s;

  fsm_state_proc: process(clk, rst) is
  begin 
    if clk'event and clk='1' then
      if EN = '1'then
        if rst = '0' then 
          State <=IDLE;
          reset_fifo <= '0';
          sens_calib_id_s <= (0 => '1', others => '0');
        else 
          State <= State_next;
          reset_fifo <= reset_fifo_s;
          if(calib_trg_s = '1') then
            sens_calib_id_s <= sens_calib_id_s(N_SENSORS-2 downto 0) & sens_calib_id_s(N_SENSORS-1);
          end if;
        end if;
      end if;
    end if;
  end process; 
          
  fsm_next_state: process (State, input_data, krdy, EN, exception, Drdy, sensor_fifo_dvld, delay_nb, delay_rst, Din, wait_cnt_overflow)
  begin
    case State is 
      when IDLE => 
        if Krdy = '1' then 
          State_next <= GET_CMD;
        else 
          State_next <= IDLE;
        end if;
      when GET_CMD => 
        if input_data(2 downto 0) = "000" then 
          State_next <= START_WRITE_INST1;
        elsif input_data(2 downto 0) = "001" then 
          State_next <= WRITE_INST1;
        elsif input_data(2 downto 0) = "010" then 
          State_next <= END_WRITE_INST1;
        elsif input_data(2 downto 0) = "011" then 
          State_next <= GET_CALIBRATION;
        elsif input_data(2 downto 0) = "111" then
          State_next <= RESET_LOGIC;
        else 
          State_next <= IDLE;
        end if;
      when GET_CALIBRATION =>
        if Krdy = '1' then
          State_next <= CALIBRATE;
        else
          State_next <= GET_CALIBRATION;
        end if;
      when CALIBRATE => 
        State_next <= WAIT_CALIB;
      when WAIT_CALIB =>
        if(wait_cnt_overflow = '1') then
          State_next <= SENS_TRG;
        else
          State_next <= WAIT_CALIB;
        end if;
      when SENS_TRG => 
        State_next <= WAIT_DATA_CMD; 
      when START_WRITE_INST1 => 
        State_next <= START_WRITE_INST2;
      when START_WRITE_INST2 => 
        State_next <= START_WRITE_INST3;
      when START_WRITE_INST3 => 
        State_next <= IDLE;
      when WRITE_INST1 => 
        State_next <= WRITE_INST2;
      when WRITE_INST2 => 
        State_next <= WRITE_INST3;
      when WRITE_INST3 => 
        State_next <= IDLE;
      when END_WRITE_INST1 => 
        State_next <= END_WRITE_INST2;
      when END_WRITE_INST2 => 
        State_next <= END_WRITE_INST3;
      when END_WRITE_INST3 => 
        State_next <= START_EXEC; 
      when START_EXEC => 
        State_next <= ADD_DELAY;
      when ADD_DELAY => 
        if delay_nb = 10 then 
          State_next <= EXEC;
        else 
          State_next <= ADD_DELAY;
        end if;
      when EXEC => 
        if exception = '1' then 
          State_next <= FINISH_EXEC;
        else 
          State_next <= EXEC;
        end if;
      when FINISH_EXEC => 
        State_next <= RESET_ENABLE;
      when RESET_ENABLE => 
        State_next <= RESET_CPU;
      when RESET_CPU => 
        if delay_rst = 20 then 
          State_next <= WAIT_DATA_CMD;
        else 
          State_next <= RESET_CPU;
        end if;
      when WAIT_DATA_CMD => 
        if Drdy='1' then 
          State_next <= DECODE_CMD;
        else 
          State_next <= WAIT_DATA_CMD;
        end if;
      when DECODE_CMD => 
        if Din(7 downto 0) = "00000000" then 
          State_next <= END_TRACE;
        elsif Din(7 downto 0) = "11111111" then 
          State_next <= END_TRACE;
        elsif Din(7 downto 0) = "11111110" then 
          State_next <= READ_SENSOR;
        elsif Din(7 downto 0) = "11111100" then
          State_next <= STORE_START_SENS_SAMPLE;
        else 
          State_next <= END_TRACE;
        end if;                    
      -- Read sensor FIFO in empty
      when STORE_START_SENS_SAMPLE =>
        State_next <= EMPTY_SENS_READ;  
      when EMPTY_SENS_READ =>
        if sensor_fifo_dvld = '1' then
          if (sample_cnt = to_integer(unsigned(start_sample))-1) then
            State_next <= END_SENS_EMPTY;
          else
            State_next <= INC_EMPTY_CNT;
          end if;
        else 
          State_next <= EMPTY_SENS_READ;
        end if;
      when INC_EMPTY_CNT =>
        State_next <= EMPTY_SENS_READ;
      when END_SENS_EMPTY => 
        State_next <= WAIT_DATA_CMD;
      when READ_SENSOR => 
        if sensor_fifo_dvld = '1' then 
          State_next <= WAIT_DATA_CMD;
        else 
          State_next <= READ_SENSOR;
        end if;
      when END_TRACE => 
        State_next <= IDLE;
      when others => 
        State_next <=IDLE;
    end case;
  end process;

  fsm_address_clock: process(clk) is
  begin
    if clk'event and clk='1' then
      if reset_addr_cnt = '1' or rst = '0' then 
        addr_counter <= 0;
      elsif en_address_counter = '1' then
        addr_counter <= addr_counter + 1;
      end if;
    end if;
  end process;

  delay_clock: process(clk) is
  begin
    if clk'event and clk='1' then
      if reset_cnt = '1' or rst = '0' then 
        delay_nb <= 0;
      elsif en_delay_counter = '1' then
        delay_nb <= delay_nb + 1;
      end if;
    end if;
  end process;

  delay_reset: process(clk) is
  begin
    if clk'event and clk='1' then
      if reset_cnt = '1' or rst = '0' then 
        delay_rst <= 0;
      elsif en_delay_reset = '1' then
        delay_rst <= delay_rst + 1;
      end if;
    end if;
  end process;

  wait_cnt: entity work.counter_simple
  GENERIC MAP(
    MAX => 16
  )
  PORT MAP(
    clk             => clk,
    clk_en_p        => '1',
    reset_p         => reset_cnt,
    cnt_en          => wait_cnt_en,
    count_o         => open,
    overflow_o_p    => open,
    cnt_next_en_o_p => wait_cnt_overflow  
  );

  sample_cnt_cnt: process(clk) is
  begin
    if clk'event and clk='1' then
      if sample_cnt_rst = '1' or rst = '0' then 
        sample_cnt <= 0;
      elsif sample_cnt_en = '1' then
        sample_cnt <= sample_cnt + 1;
      end if;
    end if;
  end process;

  sample_reg: process(clk) is
  begin
    if clk'event and clk='1' then
      if rst = '0' then 
        start_sample <= (others => '0');
      elsif start_sample_en = '1' then
        start_sample <= Din(19 downto 8);
      end if;
    end if;
  end process;

  fsm_output_logic: process(State, input_data, addr_counter) is
  begin

    -- default values
    instr              <= X"00000000";
    inst_mem_addr      <= "000000000000";
    inst_mem_wen       <= "1"; 
    inst_mem_en        <= '0';

    en_cpu             <= '0';
    rst_cpu            <= '0';

    calib_trg_s        <= '0';
    sensor_fifo_read   <= '0';
    sensor_trigger     <= '0';
    osc_trigger        <= '1';

    en_address_counter <= '0';
    en_delay_counter   <= '0';
    en_delay_reset     <= '0';
    wait_cnt_en        <= '0';
    
    start_sample_en    <= '0';
    sample_cnt_rst     <= '0';
    sample_cnt_en      <= '0';

    bsy                <= '0';

    reset_cnt          <= '0';
    reset_addr_cnt     <= '0';
    reset_fifo_s       <= '1';

    fsm_dvld           <= '0';
    dvld_mux           <= '0';
        
    case State is
      when IDLE => 
        reset_cnt          <= '1';
      when GET_CMD =>
        inst_mem_wen       <= "1";
      when GET_CALIBRATION =>
      when CALIBRATE => 
        calib_trg_s        <= '1';
      when WAIT_CALIB =>
        wait_cnt_en        <= '1'; 
      when SENS_TRG =>
        sensor_trigger     <= '1';
      when RESET_LOGIC =>
        en_cpu             <= '1';
        rst_cpu            <= '1';
        reset_fifo_s       <= '0';
        en_delay_reset     <= '1';
      when START_WRITE_INST1 => 
        en_address_counter <= '1';
        instr              <= input_data(127 downto 96);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when START_WRITE_INST2 =>
        en_address_counter <= '1';
        instr              <= input_data(95 downto 64);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when START_WRITE_INST3 =>
        en_address_counter <= '1';
        instr              <= input_data(63 downto 32);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when WRITE_INST1 =>
        en_address_counter <= '1';
        instr              <= input_data(127 downto 96);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when WRITE_INST2 =>
        en_address_counter <= '1';
        instr              <= input_data(95 downto 64);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when WRITE_INST3 =>
        en_address_counter <= '1';
        instr              <= input_data(63 downto 32);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when END_WRITE_INST1 =>
        en_address_counter <= '1';
        instr <= input_data(127 downto 96);
        inst_mem_addr <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en <='1';
        inst_mem_wen <="1";
      when END_WRITE_INST2 => 
        en_address_counter <= '1';
        instr              <= input_data(95 downto 64);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when END_WRITE_INST3 => 
        en_address_counter <= '1';
        instr              <= input_data(63 downto 32);
        inst_mem_addr      <= std_logic_vector(to_unsigned(addr_counter, 12));
        inst_mem_en        <= '1';
        inst_mem_wen       <= "1";
      when START_EXEC => 
        sensor_trigger     <= '1';
        osc_trigger        <= '0';
      when ADD_DELAY => 
        en_delay_counter   <= '1';
        osc_trigger        <= '0';
      when EXEC => 
        en_cpu             <= '1';
        osc_trigger        <= '0';
      when FINISH_EXEC => 
        en_cpu             <= '1';
        osc_trigger        <= '0';
      when RESET_ENABLE => 
        en_cpu             <= '1';
        osc_trigger        <= '0';
      when RESET_CPU => 
        en_cpu             <= '1'; 
        rst_cpu            <= '1'; 
        en_delay_reset     <= '1';
        osc_trigger        <= '0';
      when WAIT_DATA_CMD => 
      when DECODE_CMD => 
        bsy                <= '1'; 
      when STORE_START_SENS_SAMPLE =>
        start_sample_en    <= '1';
        sample_cnt_rst     <= '1';
      when EMPTY_SENS_READ =>
        sensor_fifo_read   <= '1'; 
        dvld_mux           <= '1'; 
      when INC_EMPTY_CNT =>
        sample_cnt_en      <= '1';
      when END_SENS_EMPTY =>
        fsm_dvld           <= '1'; 
        dvld_mux           <= '1'; 
      when READ_SENSOR => 
        sensor_fifo_read   <= '1'; 
        bsy                <= '1'; 
      when END_TRACE => 
        bsy                <= '1'; 
        fsm_dvld           <= '1'; 
        dvld_mux           <= '1'; 
        reset_cnt          <= '1';
        reset_addr_cnt     <= '1'; 
        reset_fifo_s       <= '0';
      when others =>
    end case;
  end process;
end FSM_arch;
