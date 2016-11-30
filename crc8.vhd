-----------CRC8----------
--- entity of the scrambler
--- TODO: check which variables/signals have to be redefined

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CRC8 is                          -- X8 + X7 + X6 + X4 + X2 + 1
	port(	 clk       		: in  std_logic;
		 scrambler_CRC_input	: in std_logic_vector(1 downto 0); -- 2 bit -- bepaalt of we de header of data coderen
		 CRC_rst    		: in  std_logic;    --active high reset
		 data_ser   		: in  std_logic;    --serial input voor data zelf (dus bit per bit)
		 header_out		: in  std_logic;    -- serial input voor header
		 crc_output 		: out std_logic; 	--serial output
		 CRC_enable 		: in std_logic;
		 CRC_send   		: in std_logic;
		 count_show		: out integer range 0 to 8 := 0;
		 crc_temp_show		: out unsigned(7 downto 0)  := (others => '0');
		 data_show		: out std_logic := '0'
	);
end CRC8;

architecture crc_behavioral of CRC8 is

	signal crc_temp 	: unsigned(7 downto 0)  := (others => '0');
	
	

begin
	process(clk, CRC_rst)
		variable data	: std_logic := '0';
		variable count	: integer range 0 to 8 := 0;
		
	begin
		
		if (CRC_rst = '1') then
			crc_temp  <= (others => '0'); --voor crc 8 worden deze op 0 gezet, voor crc 32 zou dit 1 zijn (hier niet nodig)
			count     := 0;
			crc_output <= 'Z';
		
		elsif (clk ='1' and clk'event) then
			--crc calculation in the next four lines.
			if CRC_enable = '1' then
			crc_temp(0) <= data xor crc_temp(7);
			crc_temp(1) <= crc_temp(0);
			crc_temp(2) <= crc_temp(1) xor data xor crc_temp(7);
			crc_temp(3) <= crc_temp(2);
			crc_temp(4) <= crc_temp(3) xor data xor crc_temp(7);
			crc_temp(5) <= crc_temp(4);
			crc_temp(6) <= crc_temp(5) xor data xor crc_temp(7);
			crc_temp(7) <= crc_temp(6) xor data xor crc_temp(7);
			end if;

			
			
			crc_temp_show <= crc_temp;
			count_show <= count;

			if count = 8 then
				count := 0;
			elsif (CRC_send = '1') then
				count := count + 1;
			end if;

			if count = 0 then
				crc_output <= 'Z';
			elsif count = 1 then
				crc_output <= crc_temp(6) xor data xor crc_temp(7);
			elsif count = 2 then
				crc_output <= crc_temp(5) xor data xor crc_temp(7);
			elsif count = 3 then
				crc_output <= crc_temp(4);
			elsif count = 4 then
				crc_output <= crc_temp(3) xor data xor crc_temp(7);
			elsif count = 5 then
				crc_output <= crc_temp(2);
			elsif count = 6 then
				crc_output <= crc_temp(1) xor data xor crc_temp(7);
			elsif count = 7 then
				crc_output <= crc_temp(0);
			elsif count = 8 then
				crc_output <= data xor crc_temp(7);
			end if;
			data_show <= data;
		
		end if;
			
			if (scrambler_CRC_input = "00") then
				data := header_out;
			elsif (scrambler_CRC_input = "10") then
				data := data_ser;
			end if;
	end process;


end crc_behavioral;
