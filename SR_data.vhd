


--SR_data--
-- SR flip flop that holds the value of accept_data
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity SR_data is
	PORT(
		accept_data    			: in  std_logic;
		serializer_rst 			: in  std_logic;
		clk            			: in  std_logic;
		input_valid   			: in  std_logic;
		in_readyForPreviousBlock	: out std_logic;
		in_readyForPreviousBlock2	: out std_logic
	);
end SR_data;

architecture behavioral of SR_data is
begin
	PROCESS(clk)
	variable tmp : std_logic := '0';
	variable counter : integer range 0 to 189 := 0;
	begin
			
		if (clk = '1' and clk'event) then
			--if (accept_data = '0' and serializer_rst = '0') then
			--	tmp := tmp;
			--elsif (accept_data = '1' and serializer_rst = '1') then
			--	tmp := 'Z';
			--elsif (accept_data = '0' and serializer_rst = '1') then
			--	tmp := '0';
			--else
			--	tmp := '1';
			--end if;
			if serializer_rst = '0' and accept_data = '1' then
				tmp := '1';
			elsif serializer_rst = '1' then
				tmp := '0';
			else	
				tmp := tmp;
			end if;
			
			if input_valid = '1' then
				counter := counter + 1;
			end if;
			
			if serializer_rst = '1' then
				counter := 0;
			end if;
			
			if (counter /= 188 and tmp = '1')then
				in_readyForPreviousBlock <= '1';
				in_readyForPreviousBlock2 <= '1';
			else
				in_readyForPreviousBlock <= '0';
				in_readyForPreviousBlock2 <= '0';
			end if;
		end if;


	end PROCESS;
end behavioral;
