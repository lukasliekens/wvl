

library ieee;
use ieee.numeric_std.all;
use work.config.all;
use work.functions.all;
use ieee.std_logic_1164.all;

entity bch is
generic(
    fecConfig: FEC_CONFIG := FEC_CONFIG_DVBT2
);
port(
	-- Clock
	clk: in std_logic;

    -- Control signals
    -- This signal should be pulsed before the beginning of a frame
    -- to clear the internal state of the block
    in_frame_start: in std_logic;
    -- And this one at the end of the user data
    in_frame_end: in std_logic;

    -- Interface for reading bits
    in_inputValid: in std_logic;
    in_readyForPreviousBlock: out std_logic;
    in_data: in std_logic;
	
	--  control signal to select which polynomial to use for encoding.
	-- 3 opties: 8,10,12
	--#Poly selection: 0=64k 12-bch, 1=64k 10-bch, (2=64k 8-bch) 3=16k 12-bch, (4=32k 12-bch) (S2X specific poly)
    bch_polynomial: in integer range 0 to fecConfig.bch_maxPolynomial;

    -- Interface for writing result bits
    out_outputValid: out std_logic;
    out_nextBlockReady: in std_logic;
    out_data: out std_logic;
    
    -- Control signals to LDPC block
    out_bchFrameEnded: out std_logic
);
end bch;  

architecture bch_arch of bch is
	-- T1: reset and accept new data
	-- T2: calculations and bypassing data
	-- T3: sending remainder (bch)
	Type state_type is (T1_reset,T2_bypass_data,T3_remainder);
	signal STATE: state_type := T1_reset;
	signal shift_reg: std_logic_vector(0 to 191);
	signal shift_reg_160_64k: std_logic_vector(0 to 159); --:= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
	signal shift_reg_192_64k: std_logic_vector(0 to 192); -- := "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
	signal shift_reg_168_16k: std_logic_vector(0 to 168); -- := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
	signal shift_bit: std_logic;
	signal xor_bit: std_logic;
	signal polynomial: std_logic_vector(0 to 191);
	--signal polynoom_192_64k : std_logic_vector(191 downto 0); -- := "1010011100010011000001110100000111000010001011100010100010001110001010000110011110010110011011000110111000010010100001000100010010000001101000111100001011111011101000110000000100101010111100111";
	--signal polynoom_160_64k : std_logic_vector(159 downto 0); -- := "10110000000010101000011001110110111111100001010100011001100011111011010100111100001010111000000111110111111010001001000110000000110111000101110110110010110010001" ;
	--signal polynoom_168_16k : std_logic_vector(167 downto 0); -- := "1010000000110001011011011111010101001100001101001101100100110001011001101001000111010001110010000011010010101001010001111111001111101011111010001000110010000010110100101";

begin
	bch_states : process(CLK)
	begin
		-- in_frame_start : pulsing this signal at the beginning (reset internal state)
		-- in_inputValid : we need a valid input to start the first state
		-- out_bchFrameEnded : after the second state ends we need to return to the first state,
				-- Can we set out_bchFrameEnded ='1' as default value????
						-- No, you can't use a output value to compare!!
		if(CLK'event and CLK = '1') then
			if in_frame_start ='1' then
				out_outputValid <= '0';
				out_bchFrameEnded <= '0';
				in_readyForPreviousBlock <= '0';
				--out_nextBlockReady <= '0'; (can no be assigned)???
				STATE <= T1_reset;
			elsif in_inputValid='1' and out_nextBlockReady ='1' then --is de data geldig? kan ze ontvangen worden?
				out_outputValid <= '1'; --bypass every data you get, and calculate the remainder at the same time
				in_readyForPreviousBlock <= '1';
				STATE <= T2_bypass_data;
			elsif  in_frame_end='1' then -- after the last bit is processed
				in_readyForPreviousBlock <= '0';
				STATE <= T3_remainder;
			end if;
		end if;
	end process bch_states;
	bch_calc : process(CLK)
	variable constante: integer;
	variable counter_T3: integer;
	begin
		if(CLK'event and CLK = '1') then
			case STATE is
				when T1_reset =>
					if bch_polynomial = 0 then -- first bit removed
						shift_reg(0 to 159) <= shift_reg_160_64k(0 to 159);
						polynomial(0 to 159) <= "0110000000010101000011001110110111111100001010100011001100011111011010100111100001010111000000111110111111010001001000110000000110111000101110110110010110010001";
						constante := 159;
						counter_T3 := 159;
					elsif bch_polynomial = 1 then  
						shift_reg(0 to 191) <= shift_reg_192_64k(0 to 191);
						polynomial(0 to 191) <= "010011100010011000001110100000111000010001011100010100010001110001010000110011110010110011011000110111000010010100001000100010010000001101000111100001011111011101000110000000100101010111100111";
						counter_T3 := 191;
						constante := 191;
					elsif bch_polynomial = 3 then
						shift_reg(0 to 167) <= shift_reg_168_16k(0 to 167);
						polynomial(0 to 167) <= "010000000110001011011011111010101001100001101001101100100110001011001101001000111010001110010000011010010101001010001111111001111101011111010001000110010000010110100101";
						constante := 167;
						counter_T3 := 167;
					end if;
				when T2_bypass_data =>
					out_data <= in_data; --bypass
					shift_bit <= shift_reg(0);
					xor_bit <= (in_data xor shift_reg(0));
					shift_reg(0 to (constante-1)) <= shift_reg(1 to constante);
					shift_reg(constante) <= xor_bit;
					division : for i in (constante-1) downto 0 loop
						if polynomial(i) ='1' then
							shift_reg(i) <= shift_reg(i) xor shift_bit;
						end if;
					end loop division;
					--shift_reg((constante-1) downto 0) <= shift_reg(constante downto 1);
					--shift_reg(constante) <= in_data xor shift_bit;
					--shift_reg(constante downto 0) <= shift_reg(constante downto 0) xor polynomial(constante downto 0);				
				when T3_remainder =>
					out_data <= shift_reg(constante - counter_T3);
					if counter_T3 = 0 then
						out_outputValid <= '0';
						out_bchFrameEnded <= '1';
						in_readyForPreviousBlock <= '1';
					else
						counter_T3 := counter_T3 -1;
					end if;				
			end case;
		end if;
	end process bch_calc;
end bch_arch;

