-- The RISCY Processor - A simple RISC-V based processor for FPGAs
-- (c) Krishna Subramanian <https://github.com/mongrelgem>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.ry_types.all;
use work.ry_utilities.all;

--! @brief The RISCY Processor.
--! This file provides a Wishbone-compatible interface to the RISCY processor.
entity ry_riscy is
	generic(
		PROCESSOR_ID           : std_logic_vector(31 downto 0) := x"00000000"; --! Processor ID.
		RESET_ADDRESS          : std_logic_vector(31 downto 0) := x"00000000"; --! Address of the first instruction to execute.
		MTIME_DIVIDER          : positive                      := 5;           --! Divider for the clock driving the MTIME counter.
		ICACHE_ENABLE          : boolean                       := true;        --! Whether to enable the instruction cache.
		ICACHE_LINE_SIZE       : natural                       := 4;           --! Number of words per instruction cache line.
		ICACHE_NUM_LINES       : natural                       := 128          --! Number of cache lines in the instruction cache.
	);
	port(
		clk       : in std_logic;
		timer_clk : in std_logic;
		reset     : in std_logic;
		en_cpu    : in std_logic;

		-- Interrupts:
		irq : in std_logic_vector(7 downto 0);

		-- Test interface:
		test_context_out : out test_context;

		-- Wishbone interface:
		wb_adr_out : out std_logic_vector(31 downto 0);
		wb_sel_out : out std_logic_vector( 3 downto 0);
		wb_cyc_out : out std_logic;
		wb_stb_out : out std_logic;
		wb_we_out  : out std_logic;
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_dat_in  : in  std_logic_vector(31 downto 0);
		wb_ack_in  : in  std_logic;
		decode_exception : out std_logic;
		instr_processed: out std_logic_vector(31 downto 0)
	);
end entity ry_riscy;

architecture behaviour of ry_riscy is
    signal opcode: std_logic_vector(4 downto 0);
    signal d_exception : std_logic;
	-- Instruction memory signals:
	signal imem_address : std_logic_vector(31 downto 0);
	signal imem_data    : std_logic_vector(31 downto 0);
	signal imem_req, imem_ack : std_logic;

	-- Data memory signals:
	signal dmem_address   : std_logic_vector(31 downto 0);
	signal dmem_data_in   : std_logic_vector(31 downto 0);
	signal dmem_data_out  : std_logic_vector(31 downto 0);
	signal dmem_data_size : std_logic_vector( 1 downto 0);
	signal dmem_read_req  : std_logic;
	signal dmem_read_ack  : std_logic;
	signal dmem_write_req : std_logic;
	signal dmem_write_ack : std_logic;

	-- Wishbone signals:
	signal icache_inputs, dmem_if_inputs   : wishbone_master_inputs;
	signal icache_outputs, dmem_if_outputs : wishbone_master_outputs;

    -- Arbiter signals:
	signal m1_inputs, m2_inputs   : wishbone_master_inputs;
	signal m1_outputs, m2_outputs : wishbone_master_outputs;
	signal instruction_ready: std_logic;

begin

    decode_exception <= d_exception;
    
	processor: entity work.ry_core
		generic map(
			PROCESSOR_ID => PROCESSOR_ID,
			RESET_ADDRESS => RESET_ADDRESS
		) port map(
		    en_cpu => en_cpu,
			clk => clk,
			reset => reset,
			timer_clk => timer_clk,
			imem_address => imem_address,
			imem_data_in => imem_data,
			imem_req => imem_req,
			imem_ack => imem_ack,
			dmem_address => dmem_address,
			dmem_data_in => dmem_data_in,
			dmem_data_out => dmem_data_out,
			dmem_data_size => dmem_data_size,
			dmem_read_req => dmem_read_req,
			dmem_read_ack => dmem_read_ack,
			dmem_write_req => dmem_write_req,
			dmem_write_ack => dmem_write_ack,
			test_context_out => test_context_out,
			irq => irq,
			decode_exception => d_exception,
			opcodee => opcode,
			instr_rdy => instruction_ready,
			instr_processed => instr_processed
		);

	icache_enabled: if ICACHE_ENABLE
	generate
		icache: entity work.ry_icache
			generic map(
				LINE_SIZE => ICACHE_LINE_SIZE,
				NUM_LINES => ICACHE_NUM_LINES
			) port map(
				clk => clk,
				reset => reset,
				en_cpu => en_cpu,
				mem_address_in => imem_address,
				mem_data_out => imem_data,
				mem_read_req => imem_req,
				mem_read_ack => imem_ack,
				wb_inputs => icache_inputs,
				wb_outputs => icache_outputs
			);

		icache_inputs <= m1_inputs;
		m1_outputs <= icache_outputs;

		dmem_if_inputs <= m2_inputs;
		m2_outputs <= dmem_if_outputs;
	end generate icache_enabled;

	icache_disabled: if not ICACHE_ENABLE
	generate
		imem_if: entity work.ry_wb_adapter
			port map(
			    en_cpu => en_cpu,
				clk => clk,
				reset => reset,
				mem_address => imem_address,
				mem_data_in => (others => '0'),
				mem_data_out => imem_data,
				mem_data_size => (others => '0'),
				mem_read_req => imem_req,
				mem_read_ack => imem_ack,
				mem_write_req => '0',
				mem_write_ack => open,
				wb_inputs => icache_inputs,
				wb_outputs => icache_outputs
			);

		dmem_if_inputs <= m1_inputs;
		m1_outputs <= dmem_if_outputs;

		icache_inputs <= m2_inputs;
		m2_outputs <= icache_outputs;
	end generate icache_disabled;

	dmem_if: entity work.ry_wb_adapter
		port map(
		    en_cpu => en_cpu,
			clk => clk,
			reset => reset,
			mem_address => dmem_address,
			mem_data_in => dmem_data_out,
			mem_data_out => dmem_data_in,
			mem_data_size => dmem_data_size,
			mem_read_req => dmem_read_req,
			mem_read_ack => dmem_read_ack,
			mem_write_req => dmem_write_req,
			mem_write_ack => dmem_write_ack,
			wb_inputs => dmem_if_inputs,
			wb_outputs => dmem_if_outputs
		);

	arbiter: entity work.ry_wb_arbiter
		port map(
		    en_cpu => en_cpu,
			clk => clk,
			reset => reset,
			m1_inputs => m1_inputs,
			m1_outputs => m1_outputs,
			m2_inputs => m2_inputs,
			m2_outputs => m2_outputs,
			wb_adr_out => wb_adr_out,
			wb_sel_out => wb_sel_out,
			wb_cyc_out => wb_cyc_out,
			wb_stb_out => wb_stb_out,
			wb_we_out => wb_we_out,
			wb_dat_out => wb_dat_out,
			wb_dat_in => wb_dat_in,
			wb_ack_in => wb_ack_in
		);

end architecture behaviour;

