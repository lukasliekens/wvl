
--SR_ctrlsync--
-- SR flip flop that holds the value of ctrl sync
-- the output of this SR FF goes to a 3-AND port with the (inverse of ctrl sync) and (in_inputValid)
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity SR_ctrlsync is
	PORT(
		in_inputValid		 : in  std_logic;
		ctrl_sync                : in  std_logic;
		serializer_rst           : in  std_logic;
		clk                      : in  std_logic;
		input_valid		 : out std_logic;
		in_readyForPreviousBlock2 : in std_logic
	);
end SR_ctrlsync;

architecture behavioral of SR_ctrlsync is

begin
	PROCESS(clk)
	variable tmp : std_logic;
	begin
		if (clk = '1' and clk'event) then
			if (ctrl_sync = '1' and in_inputValid = '1' and serializer_rst = '0') then	
				tmp := '1';
			elsif serializer_rst = '1' then
				tmp := '0';
			else
				tmp := tmp;
			

			--if in_inputValid = '1' then
			--if (ctrl_sync = '0' and serializer_rst = '0') then
			--	tmp := tmp;
			--elsif (ctrl_sync = '1' and serializer_rst = '1') then
			--	tmp := 'Z';
			--elsif (ctrl_sync = '0' and serializer_rst = '1') then
			--	tmp := '0';
			--else
			--	tmp := '1';
			--end if;
			end if;		
		end if;
		input_valid <= (not ctrl_sync) AND tmp and in_inputValid and in_readyForPreviousBlock2;
	end PROCESS;
end behavioral;
