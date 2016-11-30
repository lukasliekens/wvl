library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity header is
port(
	-- Clock
	clk			: in 	std_logic;
	header_send	: in 	std_logic;
	header_rst	: in 	std_logic;
	header_out	: out	std_logic;
	ctrl_LDPCCode :	in integer range 0 to 23
);
end header;  


architecture header_arch of header is
-- T1 : reset
-- T2 : MAT en UPL uitzenden
-- T3 : DFL uitzenden
-- T4 : Sync uitzenden
-- T5 : SYNCD uitzenden
-- (T6 : CRC8 uitzenden)
	type header_states is (T1,T2,T3); -- T6 toevoegen indien de CRC_8 via de header wordt uitgezonden
	signal state : header_states;
	signal MAT_and_UPL : std_logic_vector (31 downto 0) := "11110000000000000000010111100000";
	signal DFL : std_logic_vector (15 downto 0);																		
	signal SYNC_and_SYNCD : std_logic_vector (23 downto 0) := "010001110000000000000000" ;



begin

		
	header_calc : process(CLK)
	variable counter_MAT_and_UPL : integer range 0 to 31 := 31;
	variable counter_DFL : integer range 0 to 15 := 15;
	variable counter_SYNC_and_SYNCD : integer range 0 to 23 := 23;
	
	
	begin

		if header_rst = '1' then
			counter_MAT_and_UPL := 31;
			counter_DFL := 15;
			counter_SYNC_and_SYNCD := 23;
		elsif(CLK'event and CLK = '1') then
			if header_send = '1' then
			case state is
			when T1 => 
				
				counter_DFL := 15;
				counter_SYNC_and_SYNCD := 23;
				
			
				
				case ctrl_LDPCCode is
				when 0  => DFL <= "0000101110110000";-- fout "0000110000000000"; --3072  // juist 2992
				when 1  => DFL <= "0001101100101000";--"0001101101111000"; --7032 --6952
				when 2  => DFL <= "0001100001011000";--"0001100010101000"; --6312 --6232
				when 3  => DFL <= "0001010000100000";--"0001010001110000"; --5232 --5152
				when 4  => DFL <= "0010010100000000";--"0010010101010000"; --9552 --9472
				when 5  => DFL <= "0010100100111000";--"0010100110001000"; --10632 --10552
				
--								  "0010110101110000"
				when 6  => DFL <= "0010110101110000";--"0010110101110000"; --11712 --11632
				when 7  => DFL <= "0011000001000000";--"0011000010010000"; --12432 --12352
				when 8  => DFL <= "0011001100010000";--"0011001101100000"; --13152 --13072
				when 9  => DFL <= "0011011101001000";--"0011011110011000"; --14232 --14152
				when 10 => DFL <= "0011111000111000";--"0011111010001000"; --16008 --15928
				when 11 => DFL <= "0111110110000000";--"0111110111010000"; --32208 --32128
				when 12 => DFL <= "0110010000110000";--"0110010010000000"; --25728 --25648
				when 13 => DFL <= "0101001101010000";--"0101001110100000"; --21408 --21328
				when 14 => DFL <= "1001011011010000";--"1001011100100000"; --38688 --38608
				when 15 => DFL <= "1010011111010000";--"1010100000100000"; --43040 --42960
				when 16 => DFL <= "1011110011001000";--"1011110100011000"; --48408 --48328
				when 17 => DFL <= "1100100101110000";--"1100100111000000"; --51648 --51568
				when 18 => DFL <= "1101001000000000";--"1101001001010000"; --53840 --53760
				when 19 => DFL <= "1110000000110000";--"1110000010000000"; --57472 --57392
				when 20 => DFL <= "1110001100000000";--"1110001101010000"; --58192 --58112
				when others => DFL <= "0000000000000000";
				end case;
				header_out <= MAT_and_UPL(counter_MAT_and_UPL);
				if counter_MAT_and_UPL = 0 then
					state <= T2;
				else 
					counter_MAT_and_UPL := counter_MAT_and_UPL - 1;
				end if;
					
			when T2 =>
				header_out <= DFL(counter_DFL);
				if counter_DFL = 0 then
					state <= T3;
				else
					counter_DFL := counter_DFL - 1;
				end if;
			when T3 =>
				header_out <= SYNC_and_SYNCD(counter_SYNC_and_SYNCD);
				counter_MAT_and_UPL := 31;
				if counter_SYNC_and_SYNCD = 0 then
					state <= T1;
				else
					counter_SYNC_and_SYNCD := counter_SYNC_and_SYNCD - 1;
				end if;
			end case;
			end if;
		end if;	
	end process header_calc;
end header_arch;
