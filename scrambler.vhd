--------scrambler--------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL;

entity scrambler is
port(
	clk:					in  std_logic;
	scrambler_rst:			in 	std_logic;
	crc_output:				in 	std_logic;
	out_data:				out std_logic;
	scrambler_CRC_input: 	in std_logic_vector (1 downto 0); ---- 00 header, 11 CRC, 10 data, 01 padding
	scrambler_enable: 		in std_logic;
	data_ser: 				in std_logic;
	header_out: 			in std_logic
	

	
);
end scrambler;

-- polynomial 1+X14+X15
architecture scrambler_arch of scrambler is
	signal scram_bit: std_logic_vector (14 downto 0); -- scrambler bits : 100 101 010 000 000 
	--signal out_data: std_logic_vector (7 downto 0);

begin
	proces_scrambler : process(clk)
	variable scram_input: std_logic;
	variable shift_bit: std_logic;
	begin
		if(CLK'event and CLK = '1') then
			if scrambler_rst ='1' then
				scram_bit <= b"000000010101001";
					    
			elsif scrambler_enable ='1' then
			----- nog corrigeren en eventueel de signalen/variabelen def.
				if scrambler_CRC_input = "00" then
					scram_input := header_out ; -- geen for-lus gebruiken omdat alles in parralel gebeurt 
					shift_bit := scram_bit(14) xor scram_bit(13);
					scram_bit(14 downto 1) <= scram_bit(13 downto 0);
					scram_bit(0) <= shift_bit;
					out_data <= shift_bit xor scram_input;
				elsif scrambler_CRC_input = "11" then
					scram_input := crc_output;
					shift_bit := scram_bit(14) xor scram_bit(13);
					scram_bit(14 downto 1) <= scram_bit(13 downto 0);
					scram_bit(0) <= shift_bit;
					out_data <= shift_bit xor scram_input;
				elsif scrambler_CRC_input = "10" then
					scram_input := data_ser;
					shift_bit := scram_bit(14) xor scram_bit(13);
					scram_bit(14 downto 1) <= scram_bit(13 downto 0);
					scram_bit(0) <= shift_bit;
					out_data <= shift_bit xor scram_input;
				elsif scrambler_CRC_input = "01" then
					scram_input := '0';
					shift_bit := scram_bit(14) xor scram_bit(13);
					scram_bit(14 downto 1) <= scram_bit(13 downto 0);
					scram_bit(0) <= shift_bit;
					out_data <= shift_bit xor scram_input;
				end if;
			end if;
		end if;
	end process;
	
end scrambler_arch;
