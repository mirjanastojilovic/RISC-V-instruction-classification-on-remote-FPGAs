-- The RISCY Processor - A simple RISC-V based processor for FPGAs
-- (c) Krishna Subramanian <https://github.com/mongrelgem>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ry_counter is
	generic(
		COUNTER_WIDTH : natural := 64;
		COUNTER_STEP  : natural :=  1
	);
	port(
		clk   : in std_logic;
		reset : in std_logic;
		en_cpu: in std_logic;
		
		count     : out std_logic_vector(COUNTER_WIDTH - 1 downto 0);
		increment : in std_logic
	);
end entity ry_counter;

architecture behaviour of ry_counter is
	signal current_count : std_logic_vector(COUNTER_WIDTH - 1 downto 0);
begin

	count <= current_count;

	counter: process(clk)
	begin
		if rising_edge(clk) then	  
		  if en_cpu = '1' then
			if reset = '1' then
				current_count <= (others => '0');
			elsif increment = '1' then
				current_count <= std_logic_vector(unsigned(current_count) + COUNTER_STEP);
			end if;
		end if;
	  end if;
	end process counter;

end architecture behaviour;