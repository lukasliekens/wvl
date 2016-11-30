library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- OPMERKING de libraries moeten per entity ook gedeclareerd worden

--INPUT PROCESSING
entity inputProcessing is
	generic(
		bypassScrambler : boolean := false -- je krijgt een output die niet gescrambled is (nodig als je wil testen)
	);
	port(
		--Clock
		clk                      : in std_logic;
		

		--Control signals
		ctrl_reset               : in std_logic; --Reset internal state at beginning of each BBFRAME
		ctrl_rolloff             : in std_logic_vector(1 downto 0);
		ctrl_sync                : in std_logic; --High while in_data is SYNC byte (no fragmentation)
		ctrl_LDPCCode            : in integer range 0 to 23; --LDPC code used (Standard: Table 6.a)
		ctrl_fragmentation       : in std_logic; --Fragment incoming data stream = No Padding
		ctrl_bbFrameEnd          : out std_logic; --Signal next blocks BBFRAME end
		ctrl_bbFrameStart        : out std_logic;
		ctrl_FECInputIdle        : in std_logic; --next block ready
		
		--Buffered MODCOD
		ctrl_modcod_id_in        : in integer range 0 to 31;
		ctrl_modcod_id_out       : out integer range 0 to 31;
		
		--Input interfaces
		in_inputValid            : in std_logic;
		in_readyForPreviousBlock : out std_logic; --Inform previous block that this one is ready
		in_data                  : in std_logic_vector(7 downto 0);
		
		--Output interfaces
		out_outputValid          : out std_logic;
		out_nextBlockReady       : in  std_logic;	
		out_data                 : out std_logic
	);
end inputProcessing;

	-- Add code here
architecture inputProcessing_arch of inputProcessing is
	type different_states is (state_1, state_2, state_3, state_4, state_5, state_6,DS_1,DS_2);
	signal state : different_states;

	-- extra defined ---------------------------------------------------------------------------------------------
	-- in
	signal DF_full                  : boolean;
	
	-- out
	signal scrambler_CRC_input      : std_logic_vector(1 downto 0);
	signal data_send                : std_logic;
	signal MPEG_counter             : std_logic;
	signal accept_data              : std_logic; -- 188Bytes opslaan (serializer)
	signal scrambler_enable         : std_logic;
	signal header_send		: std_logic;
	signal CRC_enable 		: std_logic;
	signal CRC_send			: std_logic;
	
	-- resets	
	signal scrambler_rst            : std_logic;
	signal serializer_rst           : std_logic;
	--signal MPEG_rst                 : std_logic;
	signal CRC_rst                  : std_logic;
	signal MPEG_counter_rst         : std_logic;
	signal header_rst				: std_logic;

	-- signals used between entities
	signal data_ser				: std_logic;
	signal header_out			: std_logic;
	signal crc_output			: std_logic;
	signal input_valid			: std_logic;
	signal max_MPEG				: integer range 0 to 40;
	signal padding_length			: integer range 0 to 1503;
--	signal MPEG_count_amount	: integer range 0 to 40;
	signal in_readyForPreviousBlock2	: std_logic; 
	signal count_show			: integer range 0 to 8 := 0;
	signal crc_temp_show			: unsigned(7 downto 0)  := (others => '0');
	signal data_show			: std_logic;

	
	--	variable state_counter_1: integer := 0; --juiste grootte moet nog bepaald worden (fsm schema)
				
	signal state_counter_2 : integer range 0 to 72:= 72;
	signal state_counter_3 : integer range 0 to 8:= 8;
	signal state_counter_4 : integer range 0 to 1496:= 1496;
	signal state_counter_5 : integer range 0 to 8:= 8;
	signal state_counter_6 : integer range 0 to 1504:= padding_length;
	signal DS_counter : integer range 0 to 8:=8; 
	signal DS2_enable: std_logic:= '0';	


begin
	-- Instantiation of all extra entities
	crc8: entity work.crc8
		port map(
			 clk					=> clk,
			 scrambler_CRC_input	=> scrambler_CRC_input,
			 CRC_rst   				=> CRC_rst,
			 data_ser   		 	=> data_ser,
			 header_out				=> header_out,
			 crc_output 				=> crc_output, 
			 CRC_enable 				=> CRC_enable,
			 CRC_send   				=> CRC_send,
			 count_show				=> count_show,
			 crc_temp_show			=> crc_temp_show,
			 data_show			=> data_show	
		);
		
	scrambler: entity work.scrambler
		port map(
			clk						=> clk,
			scrambler_rst			=> scrambler_rst,	
			crc_output				=> crc_output,
			out_data				=> out_data,
			scrambler_CRC_input		=> scrambler_CRC_input,
			scrambler_enable		=> scrambler_enable,
			data_ser 				=> data_ser,
			header_out				=> header_out
		);
	
	padding: entity work.padding
		port map(
			clk				=> clk,
			ctrl_LDPCCode	=> ctrl_LDPCCode,
			padding_length	=> padding_length
		);
	
	header: entity work.header
		port map(
			clk				=> clk,
			header_send		=> header_send,
			header_rst		=> header_rst,
			header_out		=> header_out,
			ctrl_LDPCCode	=> ctrl_LDPCCode
		);	
	
	--serializer instantiation
	MEM: entity work.MEM
		port map(
			clk							=> clk,
			data_send	    			=> data_send,
			input_valid 				=> input_valid,   
			in_data       				=> in_data,
			data_ser      				=> data_ser,
			serializer_rst				=> serializer_rst,
			empty           			=> open,
			full          				=> open
		);
		

		
	SR_data: entity work.SR_data
		port map(
			clk					=> clk,
			accept_data    		=> accept_data,
			serializer_rst 		=> serializer_rst,        
			input_valid    		=> input_valid,
			in_readyForPreviousBlock=> in_readyForPreviousBlock,
			in_readyForPreviousBlock2=> in_readyForPreviousBlock2
		);	

	SR_ctrlsync: entity work.SR_ctrlsync
		port map(
			clk							=> clk,
			in_inputValid				=> in_inputValid,	
			ctrl_sync                	=> ctrl_sync,
			serializer_rst          	=> serializer_rst,                    
			input_valid					=> input_valid,
			in_readyForPreviousBlock2 	=> in_readyForPreviousBlock2
		);	
	
	--DFL instantiation
--	counter: entity work.counter
--		port map(
--			clk							=> clk,
--			MPEG_counter     			=> MPEG_counter, 
--			MPEG_counter_rst 			=> MPEG_counter_rst,
--			MPEG_count_amount 			=> MPEG_count_amount
--		);
		
	DFL: entity work.DFL
		port map(
			clk              	=> clk,
			ctrl_LDPCCode		=> ctrl_LDPCCode,
			MPEG_counter      	=> MPEG_counter,
			MPEG_counter_rst  	=> MPEG_counter_rst,
			DF_Full           	=> DF_full
		);		
	
	
	state_tracking : process(clk)
	

				
	begin
		if (clk = '1'and clk'event)then
		case state is                   -- we hebben in totaal 6 toestanden
			when state_1 =>             --start
				if out_nextBlockReady = '0' then
					state               <= state_1;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <=  0;
					out_outputValid     <= '0';
					scrambler_CRC_input <= "00";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '0';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';
					header_rst			<= '0';
				else
					state               <= state_2;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '0';
					scrambler_CRC_input <= "00";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '1';
					scrambler_rst	    <= '1';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '0';
					header_send 		<= '1';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';
					header_rst			<= '0';
				end if;
			when state_2 =>             --header output
				state_counter_2 <= state_counter_2 - 1;
				if state_counter_2 > 1 then
					state               <= state_2;
					ctrl_bbFrameEnd     <= '0';
					ctrl_modcod_id_out  <= 0;
					if (state_counter_2 = 72) then
						out_outputValid     <= '0';
					else
						out_outputValid     <= '1';
					end if;
					if state_counter_2 = 71 then
						ctrl_bbFrameStart <= '1';
					else
						ctrl_bbFrameStart <= '0';
					end if;
					scrambler_CRC_input <= "00";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '1';
					CRC_enable 			<= '1';
					CRC_send 			<= '0';
					header_rst			<= '0';
				else
					state               <= state_3;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "00";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '1';
					CRC_send 			<= '1';
					header_rst			<= '0';
				end if;
			when state_3 =>             --header CRC
				state_counter_3 <= state_counter_3 - 1;
				if state_counter_3 > 1 then
					state               <= state_3;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "11";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '1';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '1';
					header_rst			<= '0';
				else
					state               <= DS_1;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "11";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '1';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';
					header_rst			<= '0';					
				end if;
				
			when DS_1 =>				--extra state to reset the CRC
				DS_counter <= DS_counter -1;				
				if DS_counter > 1 then
				state				<= DS_1;
				ctrl_bbFrameEnd     <= '0';
				ctrl_bbFrameStart   <= '0';
				ctrl_modcod_id_out  <= 0;
				out_outputValid     <= '1';
				scrambler_CRC_input <= "01";
				data_send           <= '0';
				MPEG_counter        <= '0';
				accept_data         <= '0';
				CRC_rst				<= '0';
				scrambler_rst	    <= '0';
				serializer_rst      <= '0';
				MPEG_counter_rst    <= '0';
				scrambler_enable    <= '1';
				header_send 		<= '0';
				CRC_enable 			<= '0';
				CRC_send 			<= '0';
				header_rst			<= '0';	
				else
				state				<= state_4;
				ctrl_bbFrameEnd     <= '0';
				ctrl_bbFrameStart   <= '0';
				ctrl_modcod_id_out  <= 0;
				out_outputValid     <= '1';
				scrambler_CRC_input <= "01";
				data_send           <= '1';
				MPEG_counter        <= '0';
				accept_data         <= '0';
				CRC_rst				<= '1';
				scrambler_rst	    <= '0';
				serializer_rst      <= '0';
				MPEG_counter_rst    <= '0';
				scrambler_enable    <= '1';
				header_send 		<= '0';
				CRC_enable 			<= '0';
				CRC_send 			<= '0';
				header_rst			<= '0';
				end if;					
			when state_4 =>             --Data output
				state_counter_4 <= state_counter_4 - 1;
				if state_counter_4 > 1 then
					state               <= state_4;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					if (state_counter_4 = 1496 and DS2_enable = '1') then
					out_outputValid     <= '0';
					else	
					out_outputValid     <= '1';
					end if;					
					scrambler_CRC_input <= "10";
					data_send           <= '1';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '1';
					CRC_send 			<= '0';
					header_rst			<= '0';
				else
					state               <= state_5;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "10";
					data_send           <= '0';
					MPEG_counter        <= '1';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '1';
					CRC_send 			<= '1';
					header_rst			<= '0';
					state_counter_5		<= 8;
				end if;
			when state_5 =>             --data CRC
				state_counter_5 <= state_counter_5 - 1;
				if state_counter_5 > 1 then
					state               <= state_5;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "11";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '1';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '1';
					header_rst			<= '0';
				elsif state_counter_5 = 1 and DF_full = false then
					state               <= DS_2;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "11";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '1';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';
					header_rst			<= '0';
				else
					state               <= state_6;
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "11";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';
					header_rst			<= '0';
					state_counter_6		<= padding_length;
				end if;
				
			when DS_2 =>
				state				<= state_4; 	
				ctrl_bbFrameEnd     <= '0';
				ctrl_bbFrameStart   <= '0';
				ctrl_modcod_id_out  <= 0;
				out_outputValid     <= '1';
				scrambler_CRC_input <= "11";
				data_send           <= '1';
				MPEG_counter        <= '0';
				accept_data         <= '0';
				CRC_rst				<= '1';
				scrambler_rst	    <= '0';
				serializer_rst      <= '0';
				MPEG_counter_rst    <= '0';
				scrambler_enable    <= '0';
				header_send 		<= '0';
				CRC_enable 			<= '0';
				CRC_send 			<= '0';
				header_rst			<= '0';	
				state_counter_4		<= 1496;
				DS2_enable		<= '1';				
					
			when state_6 =>             -- padding
				state_counter_6 <= state_counter_6 - 1;
				if state_counter_6 > 1 then
					state                   <= state_6; 
					ctrl_bbFrameEnd     <= '0';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					scrambler_CRC_input <= "01";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '0';
					scrambler_rst	    <= '0';
					serializer_rst      <= '0';
					MPEG_counter_rst    <= '0';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';					
					header_rst			<= '0';
				elsif state_counter_6 = 1 then
					state                   <= state_1; 
					ctrl_bbFrameEnd     <= '1';
					ctrl_bbFrameStart   <= '0';
					ctrl_modcod_id_out  <= 0;
					out_outputValid     <= '1';
					
					scrambler_CRC_input <= "01";
					data_send           <= '0';
					MPEG_counter        <= '0';
					accept_data         <= '0';
					CRC_rst				<= '1';
					scrambler_rst	    <= '0';
					serializer_rst      <= '1';
					MPEG_counter_rst    <= '1';
					scrambler_enable    <= '1';
					header_send 		<= '0';
					CRC_enable 			<= '0';
					CRC_send 			<= '0';
					header_rst			<= '1';	
					state_counter_2		<= 72;
					state_counter_3		<= 8;
					state_counter_4		<= 1496;
					state_counter_5		<= 8;
					DS_counter		<= 8;
							
				end if;
			end case;
			end if;
		end process state_tracking;
	end inputProcessing_arch;






