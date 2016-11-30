library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DFL is
	port(
		clk               : in  std_logic;
		ctrl_LDPCCode     : in  integer range 0 to 23; --24 code rates mogelijk 
		DF_Full           : out boolean;
		MPEG_counter      : in  std_logic;
		MPEG_counter_rst  : in  std_logic
	);
end DFL;
architecture DFL_arch of DFL is
begin
	process(clk,ctrl_LDPCCode)
	variable counter: integer range 0 to 40;
	variable max_MPEG: integer range 0 to 40;
	begin

		case ctrl_LDPCCode is
			when 0  => max_MPEG := 1;
			when 1  => max_MPEG := 4;
			when 2  => max_MPEG := 4;
			when 3  => max_MPEG := 3;
			when 4  => max_MPEG := 6;
			when 5  => max_MPEG := 7;
			when 6  => max_MPEG := 7;
			when 7  => max_MPEG := 8;
			when 8  => max_MPEG := 8;
			when 9  => max_MPEG := 9;
			when 10 => max_MPEG := 10;
			when 11 => max_MPEG := 21;
			when 12 => max_MPEG := 17;
			when 13 => max_MPEG := 14;
			when 14 => max_MPEG := 25;
			when 15 => max_MPEG := 28;
			when 16 => max_MPEG := 32;
			when 17 => max_MPEG := 34;
			when 18 => max_MPEG := 35;
			when 19 => max_MPEG := 38;
			when 20 => max_MPEG := 38;
			when others => max_MPEG := 0;
		end case;

		if (clk = '1' and clk'event) then
			if MPEG_counter = '1' then
				counter := counter + 1;
			end if;
			if MPEG_counter_rst = '1' then
				counter := 0;
			end if;
		end if;
		DF_Full <= (counter >= max_MPEG);

	end process;

end DFL_arch;
