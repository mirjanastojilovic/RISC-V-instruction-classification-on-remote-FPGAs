-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sensor_fifo is
  Generic(
    N_SAMPLES : integer := 1024);
  Port(
    -- Write side, written to FIFO in burst when aes_drdy_i is 1
    sensor_i      : in  STD_LOGIC_VECTOR(127 downto 0);
    aes_drdy_i    : in  STD_LOGIC;

    -- Read side, one sample read from FIFO at a time
    blk_drdy_i    : in  STD_LOGIC;
    sensor_o      : out STD_LOGIC_VECTOR(127 downto 0);
    sensor_dvld_o : out STD_LOGIC;
    mux_ctrl_o    : out STD_LOGIC;

    clk_wr        : in  STD_LOGIC;
    clk_rd        : in  STD_LOGIC;
    reset_n       : in  STD_LOGIC
    );
end sensor_fifo;

architecture struct of sensor_fifo is

  COMPONENT fifo_generator_1
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

  type WRITE_CU_states is (WAIT_ENC, WRITE_FIFO);
  signal state_reg_wr, state_next_wr : WRITE_CU_states;

  signal sensor_delay_1_s : std_logic_vector(127 downto 0);
  signal sensor_delay_2_s : std_logic_vector(127 downto 0);

  signal cnt_overflow_s : std_logic; 
  signal fifo_wr_en_s   : std_logic; 
  signal cnt_en_s       : std_logic; 
  

  type READ_CU_states is (READ_FIFO, WAIT_VALID, WRITE_REG, WRITE_OUT, WAIT_SENSOR);
  signal state_reg_rd, state_next_rd : READ_CU_states;

  signal data_q       : std_logic_vector(127 downto 0);
  signal fifo_out_s   : std_logic_vector(127 downto 0);

  signal fifo_valid_s : std_logic; 
  signal fifo_rd_en_s : std_logic; 
  signal reg_en_s     : std_logic;


  signal reset_p      : std_logic;
  
  signal write_ack_s  : std_logic;

begin

  -- FIFO
  fifo: fifo_generator_1
  port map (
    rst         => reset_p, 
    wr_clk      => clk_wr, 
    rd_clk      => clk_rd, 
    din         => sensor_delay_2_s, 
    wr_en       => fifo_wr_en_s, 
    rd_en       => fifo_rd_en_s, 
    dout        => fifo_out_s, 
    full        => open, 
    wr_ack      => write_ack_s, 
    empty       => open, 
    valid       => fifo_valid_s,
    wr_rst_busy => open,
    rd_rst_busy => open
  );

  reset_p <= not reset_n;

  -- WRITE LOGIC, WORKING ON SENSOR CLOCK (clk_wr)

  -- State register
  write_state_proc: process(clk_wr) is
  begin
    if(clk_wr'event and clk_wr='1') then
      if(reset_n = '0') then
        state_reg_wr     <= WAIT_ENC;
        sensor_delay_1_s <= (others => '0');
        sensor_delay_2_s <= (others => '0');
      else
        state_reg_wr     <= state_next_wr;
        sensor_delay_1_s <= sensor_i;
        sensor_delay_2_s <= sensor_delay_1_s;
      end if;
    end if;
  end process;
  
  -- Next state logic
  write_next_state: process(state_reg_wr, aes_drdy_i, cnt_overflow_s) is
  begin
    case state_reg_wr is
      when WAIT_ENC =>
        if(aes_drdy_i = '0') then
            state_next_wr <= WAIT_ENC;
        else
            state_next_wr <= WRITE_FIFO;
        end if;
      when WRITE_FIFO =>
        if(cnt_overflow_s = '0') then
          state_next_wr <= WRITE_FIFO;
        else
          state_next_wr <= WAIT_ENC;
        end if;
    end case;
  end process;

  -- Moore output logic
  write_output_logic: process(state_reg_wr) is
  begin
    -- default values
    fifo_wr_en_s <= '0';
    cnt_en_s     <= '0';
    case state_reg_wr is
      when WAIT_ENC =>
        fifo_wr_en_s <= '0';
        cnt_en_s     <= '0';
      when WRITE_FIFO =>
        fifo_wr_en_s <= '1';
        cnt_en_s     <= '1';
    end case;
  end process;

  -- Counter
  samples_cnt: entity work.counter_simple
  GENERIC MAP (
    MAX => N_SAMPLES
  )
  PORT MAP (
    clk              => clk_wr,
    clk_en_p         => '1',
    reset_p          => reset_p,
    cnt_en           => cnt_en_s,
    count_o          => open,
    overflow_o_p     => open,
    cnt_next_en_o_p  => cnt_overflow_s
  );
  
  -- WRITE LOGIC, WORKING ON LBUS CLK (clk_rd)

  -- State register
  read_state_proc: process(clk_rd) is
  begin
    if(clk_rd'event and clk_rd='1') then
      if(reset_n = '0') then
        state_reg_rd <= WAIT_SENSOR;
      else
        state_reg_rd <= state_next_rd;
      end if;
    end if;
  end process;

  -- Data register
  read_proc: process(clk_rd) is
  begin
    if(clk_rd'event and clk_rd='1') then
      if(reset_n = '0') then
        data_q <= (others => '0');
      elsif (reg_en_s = '1') then
        data_q <= fifo_out_s;
      end if;
    end if;
  end process;

  -- Next state logic
  read_next_state: process(state_reg_rd, blk_drdy_i, fifo_valid_s) is
  begin
    case state_reg_rd is
--      when AES =>
--          if blk_drdy_i= '1' then 
--            state_next_rd <= READ_FIFO;
--          else 
--            state_next_rd <= AES;
--          end if;
--        if(blk_drdy_i = '0') then
--          state_next_rd <= AES;
--        else
--          state_next_rd <= WAIT_FIRST_SENSOR;
--        end if;
--      when WAIT_FIRST_SENSOR =>
--        if(blk_drdy_i = '0') then
--          state_next_rd <= WAIT_FIRST_SENSOR;
--        else
--          state_next_rd <= READ_FIFO;
--        end if;
      when READ_FIFO =>
        state_next_rd <= WAIT_VALID;
      when WAIT_VALID =>
        if(fifo_valid_s = '0') then
          state_next_rd <= WAIT_VALID;
        else
          state_next_rd <= WRITE_REG;
        end if;
      when WRITE_REG =>
        state_next_rd <= WRITE_OUT;
      when WRITE_OUT =>
        state_next_rd <= WAIT_SENSOR;
      when WAIT_SENSOR =>
        if(blk_drdy_i = '0') then
          state_next_rd <= WAIT_SENSOR;
        else
          state_next_rd <= READ_FIFO;
        end if;
    end case;
  end process;

  -- Moore output logic
  read_output_logic: process(state_reg_rd) is
  begin
    -- default values
    mux_ctrl_o    <= '0';
    fifo_rd_en_s  <= '0';
    reg_en_s      <= '0';
    sensor_dvld_o <= '0';
    case state_reg_rd is
      --when WAIT_FIRST_SENSOR =>
      when READ_FIFO =>
        fifo_rd_en_s  <= '1';
        mux_ctrl_o    <= '1';
      when WAIT_VALID =>
        mux_ctrl_o    <= '1';
      when WRITE_REG =>
        reg_en_s      <= '1';
        mux_ctrl_o    <= '1';
      when WRITE_OUT =>
        sensor_dvld_o <= '1';
        mux_ctrl_o    <= '1';
      when WAIT_SENSOR =>
        mux_ctrl_o    <= '1';
    end case;
  end process;

  sensor_o <= data_q;

end architecture;



