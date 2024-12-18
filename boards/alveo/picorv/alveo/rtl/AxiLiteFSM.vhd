-- Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
-- Copyright 2023, School of Computer and Communication Sciences, EPFL.
--
-- All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE.md file.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.design_package.all;

-- ADD STATE THAT SETS FROM WHICH SENSOR BANK THE TRACES ARE DUMPED
-- ADD STATE THAT SETS THE SENSOR BANK ID FOR CALIBRATION
-- REMOVE THE BINARY TO ONE HOT DECODING, BECAUSE WE'LL HAVE A SEPARATE REGISTER FOR THE BANK ID
-- CHANGE THE SENSOR CALIB TRIGGER TO A ONE-HOT VECTOR, SO THAT EACH BANK HAS A SEPARATE CALIB TRIGGER
-- THIS WAY WE TAKE THE BANK ID, DECODE IT, AND ACTIVATE IT'S OWN CALIB TRIGGER, SO THE SENSOR WITH CALIB_ID IN THAT BANK WILL GET CALIBRATED

entity AxiLiteFSM is
  generic (
    N_SENSORS            : integer := 1;
    IDC_SIZE             : integer := 32;
    IDF_SIZE             : integer := 96;
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 12
  );
  port (
    -----------------------------------------------------------------------------
    -- FSM output signals
    -----------------------------------------------------------------------------
    ---- CPU control signals
    ------ CPU clock enable and reset signals
    cpu_en         : out std_logic;
    cpu_rstn       : out std_logic;
    ------ CPU exception (trap) signal
    cpu_trap       : in  std_logic;
    ------ CPU memory BRAM write control signals
    start_load     : out std_logic;
    load_idle      : in  std_logic;
    load_size      : out std_logic_vector(31 downto 0);
    ---- Trace recording trigger 
    sens_trg       : out std_logic;
    dump_idle      : in  std_logic;
    ---- Sensor calibration control signals
    ------ Calibration value
    sens_calib_val : out std_logic_vector(IDC_SIZE+IDF_SIZE-1 downto 0);
    ------ Sensor to be calibrated 
    sens_calib_id  : out std_logic_vector(N_SENSORS-1 downto 0);
    ------ Calibration trigger 
    sens_calib_trg : out std_logic;
    ---- Sensor traces offloading from BRAM to DRAM
    ------ Base pointer in DRAM
    base_ptr       : out std_logic_vector(63 downto 0);
    -- DEBUG STATUS BITS
    bram_dump_idle : in std_logic;
    start_dump     : in std_logic;
    start_dump_sync: in std_logic;
    -----------------------------------------------------------------------------
    -- Ports of Axi Lite Slave Interface S00_AXI
    -----------------------------------------------------------------------------
    ---- clk and reset
    aclk           : in  std_logic;
    aresetn        : in std_logic;
    ---- AXI Lite write signals
    ------ write address signals
    awaddr         : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    awvalid        : in  std_logic;
    awready        : out std_logic;
    ------ write data signals
    wdata          : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    wstrb          : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    wvalid         : in  std_logic;
    wready         : out std_logic;
    ------ write response signals
    bresp          : out std_logic_vector(1 downto 0);
    bvalid         : out std_logic;
    bready         : in  std_logic;
    ------ AXI Lite read signals (not used)
    -------- read address signals
    araddr         : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    arvalid        : in std_logic;
    arready        : out std_logic;
    ------ read data signals
    rdata          : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    rresp          : out std_logic_vector(1 downto 0);
    rvalid         : out std_logic;
    rready         : in std_logic
    -----------------------------------------------------------------------------
  );
end AxiLiteFSM;

architecture FSM_arch of AxiLiteFSM is

  type wstates is (IDLE,
                  GET_ADDR,
                  WAIT_DATA,
                  GET_DATA,
                  DECODE,
                  RST,
                  RST_END,
                  STORE_CODE,
                  STORE_TO_SENSOR_ID,
                  STORE_SENSOR_CALIB,
                  TRIGGER_CALIB_TRACE,
                  TRIGGER_TRACE,
                  PREPARE_CPU_EXEC,
                  TRIGGER_CPU_EXEC,
                  SET_DUMP_PTR,
                  SET_CODE_SIZE,
                  PUSH_RESP);

  signal wstate_next, wstate : wstates;

  type rstates is (RIDLE,
                   RPUSH_ARSP,
                   RPUSH_DATA); 

  signal rstate_next, rstate : rstates;

  signal areg : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
  signal dreg, status_reg : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal areg_en, dreg_en : std_logic;
  signal calib_reg_en, base_ptr_en, delay_end, cnt_en, cnt_rstn, load_size_en, cpu_en_s, cpu_en_set, cpu_en_rst, cpu_rstn_s, sens_trg_s : std_logic;

  signal sens_calib_id_exp  : std_logic_vector(2**log2(N_SENSORS)-1 downto 0);
  
  type calib_reg_type is array (0 to (IDC_SIZE+IDF_SIZE)/32-1) of std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal calib_reg : calib_reg_type;

begin

  fsm_wstate_proc: process(aclk, aresetn) is
  begin 
    if (aclk'event and aclk='1') then
      if (aresetn = '0') then 
        wstate     <= IDLE;
        areg      <= (others => '0');
        dreg      <= (others => '0');
        calib_reg <= (others => (others => '0'));
        base_ptr  <= (others => '0');
        load_size <= (others => '0');
        cpu_en_s  <= '0';
        cpu_en    <= '0';
      else 
        wstate <= wstate_next;
        cpu_en <= cpu_en_s;
        cpu_rstn <= cpu_rstn_s;
        -- If the address register is enabled
        -- store the AXI address to the address register
        if (areg_en = '1') then
          -- Shift byte addressable AXI address
          areg      <= "00" & awaddr(awaddr'left downto 2);
        end if;
        -- If the data register is enabled
        -- store the AXI data to the data register
        if (dreg_en = '1') then
          dreg      <= wdata;
        end if;
        -- If the calibration set of registers is enabled
        -- store the data from the data register 
        -- to the calibration register specified in the LSBs of the address register
        if (calib_reg_en = '1') then
          calib_reg(to_integer(unsigned(areg(log2((IDC_SIZE+IDF_SIZE)/32)-1 downto 0)))) <= dreg;
        end if;
        -- If the base pointer register is enabled
        -- store the data from the data register 
        if (base_ptr_en = '1') then
          if (areg(0) = '0') then
            base_ptr(31 downto 0)  <= dreg;
          else
            base_ptr(63 downto 32) <= dreg;
          end if;
        end if;
        -- If the load size register is enabled
        -- store the data from the data register
        if (load_size_en = '1') then
          load_size <= dreg;
        end if;
        -- set and reset for the cpu_en signal
        -- the control fsm resets the cpu_en while the delay in the cpu start execution is happening
        -- the control fsm sets the cpu_en to 1 when the CPU should start executing
        -- the cpu_en signal is reset again when the cpu_trap signal becomes 1, i.e. when the CPU finishes execution.
        if (cpu_en_rst = '1' or cpu_trap = '1') then
          cpu_en_s <= '0';
        elsif (cpu_en_set = '1') then
          cpu_en_s <= '1';
        end if;
      end if;
    end if;
  end process; 

  wfsm_next_wstate: process (wstate, awvalid, wvalid, bready, areg, delay_end, cpu_trap)
  begin
    case wstate is 
      -- In IDLE we wait for the write address transfer to be initiated
      when IDLE =>
        if(awvalid = '1') then
          wstate_next <= GET_ADDR;
        else
          wstate_next <= IDLE;
        end if;
      -- When the address transfer is initiated, we have go and wait for the data transfer
      when GET_ADDR =>
        wstate_next <= WAIT_DATA;
      -- Here we wait for the write data transfer to be initiated
      when WAIT_DATA =>
        if(wvalid = '1') then
          wstate_next <= GET_DATA;
        else
          wstate_next <= WAIT_DATA;
        end if;
      -- We finish he write data transfer, and decode the stored address to decide what to do next
      when GET_DATA =>
        wstate_next <= DECODE;
      when DECODE =>
        case areg(areg'left-2 downto areg'left-5) is
          when X"1" =>
            wstate_next <= RST;
          when X"2" =>
            wstate_next <= SET_DUMP_PTR;
          when X"3" =>
            wstate_next <= SET_CODE_SIZE;
          when X"4" =>
            wstate_next <= STORE_CODE;
          when X"5" =>
            wstate_next <= STORE_SENSOR_CALIB;
          when X"6" =>
            wstate_next <= STORE_TO_SENSOR_ID;
          when X"7" =>
            wstate_next <= TRIGGER_CALIB_TRACE;
          when X"8" =>
            wstate_next <= TRIGGER_TRACE;
          when others =>
            wstate_next <= PUSH_RESP;
        end case;
      -- Reset the CPU, and keep reset active until counter has finished counting
      when RST =>
        if (delay_end = '1') then
          wstate_next <= RST_END;
        else
          wstate_next <= RST;
        end if;
      -- When the reset counter finished counting, disable the CPU
      when RST_END =>
        wstate_next <= PUSH_RESP;
      -- Store the code to the BRAM and finish transaction
      when STORE_CODE =>
        wstate_next <= PUSH_RESP;
      -- Store the calibration value in the register and finish transaction
      when STORE_SENSOR_CALIB =>
        wstate_next <= PUSH_RESP;
      -- Trigger the calibration of the sensor ID in the data register and finish transaction
      when STORE_TO_SENSOR_ID =>
        wstate_next <= PUSH_RESP;
      -- Trigger the recording of a trace to check the calibration
      when TRIGGER_CALIB_TRACE =>
        wstate_next <= PUSH_RESP;
      -- Trigger the recording of the CPU execution and then start CPU execution
      when TRIGGER_TRACE =>
        wstate_next <= PREPARE_CPU_EXEC;
      -- Wait until the counter finished counting, and start the CPU execution
      when PREPARE_CPU_EXEC =>
        if (delay_end = '1') then
          wstate_next <= TRIGGER_CPU_EXEC;
        else
          wstate_next <= PREPARE_CPU_EXEC;
        end if;
      -- Trigger the CPU execution, i.e., set the cpu_en to 1
      when TRIGGER_CPU_EXEC =>
        wstate_next <= PUSH_RESP;
      -- Save the base pointer
      when SET_DUMP_PTR =>
        wstate_next <= PUSH_RESP;
      -- Save the size of the code to an internal register
      when SET_CODE_SIZE =>
        wstate_next <= PUSH_RESP;
      -- Finish the AXI Lite write transaction
      when PUSH_RESP =>
        if(bready = '1') then
          wstate_next <= IDLE;
        else
          wstate_next <= PUSH_RESP;
        end if;
    end case;
  end process;

  sens_trg <= sens_trg_s;

  wfsm_output_logic: process(wstate) is
  begin

    -- default values
    areg_en        <= '0';
    dreg_en        <= '0';

    cnt_en         <= '0';
    cnt_rstn       <= '1';

    cpu_en_rst     <= '0';
    cpu_en_set     <= '0';
    cpu_rstn_s     <= '1';
    start_load     <= '0';

    sens_trg_s       <= '0';
    sens_calib_trg <= '0';
    calib_reg_en   <= '0';

    base_ptr_en    <= '0';
    load_size_en   <= '0';

    awready        <= '0';
    wready         <= '0';
    bvalid         <= '0';
    bresp          <= "00";

    case wstate is
      when IDLE =>
        cnt_rstn <= '0';
      when GET_ADDR =>
        awready <= '1';
        areg_en <= '1';
      when WAIT_DATA =>
      when GET_DATA =>
        wready  <= '1';
        dreg_en <= '1';
      when DECODE =>
      when RST =>
        cnt_en     <= '1';
        cpu_rstn_s <= '0';
        cpu_en_set <= '1';
      when RST_END =>
        cpu_en_rst <= '1';
      when STORE_CODE =>
        start_load <= '1';
      when STORE_SENSOR_CALIB =>
        calib_reg_en <= '1';
      when STORE_TO_SENSOR_ID =>
        sens_calib_trg <= '1';
      when TRIGGER_CALIB_TRACE =>
        sens_trg_s <= '1';
      when TRIGGER_TRACE =>
        sens_trg_s <= '1';
      when PREPARE_CPU_EXEC =>
        cnt_en <= '1';
        cpu_en_rst <= '1';
      when TRIGGER_CPU_EXEC =>
        cpu_en_set <= '1';
      when SET_DUMP_PTR =>
        base_ptr_en <= '1';
      when SET_CODE_SIZE =>
        load_size_en <= '1';
      when PUSH_RESP =>
        bvalid <= '1';
        bresp  <= "00";
    end case;
  end process;

  delay_cnt: entity work.counter_simple
  GENERIC MAP(
    MAX => 16
  )
  PORT MAP(
    clk             => aclk,
    clk_en_p        => '1',
    reset_n         => cnt_rstn,
    cnt_en          => cnt_en,
    count_o         => open,
    overflow_o_p    => open,
    cnt_next_en_o_p => delay_end
  );

  -- Decode sensor ID from binary to one-hot
  -- because N_SENSORS can be not a power of two, use a helper signal to fill it to a power of 2
  -- cut the unnecessary bits from the helper signal
  process (dreg) is
  begin
    sens_calib_id_exp <= (others => '0');
    sens_calib_id_exp(to_integer(unsigned(dreg(log2(N_SENSORS)-1 downto 0)))) <= '1';
  end process;
  sens_calib_id <= sens_calib_id_exp(N_SENSORS-1 downto 0);

  calib_val_connect: for i in 0 to (IDC_SIZE+IDF_SIZE)/32-1 generate
    sens_calib_val(32*(i+1)-1  downto 32*i) <= calib_reg(i);
  end generate;

  -- Status registers and read state register
  fsm_rstate_proc: process(aclk, aresetn) is
  begin 
    if (aclk'event and aclk='1') then
      if (aresetn = '0') then 
        rstate <= RIDLE;
        status_reg <= (others => '0');
      else 
        rstate <= rstate_next;
        status_reg <= (0 => load_idle, 1 => dump_idle, 2 => bram_dump_idle, 3 => start_dump, 4 => start_dump_sync, 5 => cpu_en_s, 6 => sens_trg_s, others => '0');
      end if;
    end if;
  end process; 

  rfsm_next_rstate: process(rstate, arvalid, rready) is
  begin
    case rstate is
      when RIDLE =>
        if (arvalid = '1') then
          rstate_next <= RPUSH_ARSP;
        else
          rstate_next <= RIDLE;
        end if;
      when RPUSH_ARSP =>
        rstate_next <= RPUSH_DATA;
      when RPUSH_DATA =>
        if (rready = '1') then
          rstate_next <= RIDLE;
        else
          rstate_next <= RPUSH_DATA;
        end if;
    end case;
  end process;

  rfsm_output_logic: process(rstate) is
  begin
    arready <= '0';
    rvalid <= '0';

    case rstate is
      when RIDLE =>
      when RPUSH_ARSP =>
        arready <= '1';
      when RPUSH_DATA =>
        rvalid <= '1';
    end case;
  end process;

  rdata <= status_reg; 
  rresp <= "00";

end FSM_arch;
