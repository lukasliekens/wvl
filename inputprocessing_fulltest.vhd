library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity inputProcessing_fullTest is
generic(
	bypassScrambler:			boolean := false;
	handshake_seed: 			positive := 1;
    	handshake_transaction_probability_source:	string := "0.4";
	handshake_transaction_probability_sink:	string := "1";
	input_data_file: 			string := "../testvector/InputProcessing/BeforeInputProcessing/telemic_video.txt";
    	check_data_file: 			string := "../testvector/InputProcessing/AfterScrambler/telemic_video34.txt";
	coderate_in:				integer := 16
);
end;

architecture inputProcessing_fullTest_arch of inputProcessing_fullTest is
	--Global
	signal clk:				std_logic;
	constant clk_period:			time := 10 ns;
	signal reset:				std_logic;
	signal sync:				std_logic;
	signal counter:				integer := 0;
	signal testDone:			std_logic := '0';

	--file_generator
	signal handshake_transaction_probability_real_source: real := real'value(handshake_transaction_probability_source);
	signal handshake_transaction_probability_real_sink: real := real'value(handshake_transaction_probability_sink);
	signal source_outputValid:		std_logic;
	signal in_data:				std_logic_vector(7 downto 0);
	signal source_eof:			std_logic;

	
	--inputProcessing
	signal rolloff:				std_logic_vector(1 downto 0) := "00";
	signal codeRate:			integer := coderate_in;
	signal fragmentation:			std_logic := '1';
	signal frameEnd:			std_logic;
	signal inputProcessing_data:		std_logic;
	signal inputProcessing_outputValid:	std_logic;
	signal inputProcessing_blockReady:	std_logic;
	
	--file_checker
	signal sink_eof:			std_logic;
	signal result_valid:			std_logic;
	signal sink_blockReady:			std_logic;
	signal currentValid:			std_logic;

	signal packetCounter: 			integer := 0;
	signal errorCounter: 			integer := 0;

	signal outputCounter:			integer := 0;

begin
	--Instantiation
	gen: entity work.file_generator 
		generic map(
			handshake_seed				=> handshake_seed,
                        handshake_transaction_probability 	=> handshake_transaction_probability_real_source,
                        input_data_file                   	=> input_data_file,
                        output_width                      	=> 8
                )
                port map( 
			clk                			=> clk,
                        out_outputValid    			=> source_outputValid,
                        out_nextBlockReady 			=> inputProcessing_blockReady,
                        out_data        			=> in_data,
                        end_of_file        			=> source_eof 
		);

	inputProcessing_inst: entity work.inputProcessing 
		generic map (
			bypassScrambler => bypassScrambler
		)
		port map(
			clk					=> clk,
			ctrl_reset				=> reset,
            		ctrl_modcod_id_in => 0,
			ctrl_rolloff				=> rolloff,
			ctrl_sync				=> sync,
			ctrl_LDPCCode				=> codeRate,
			ctrl_fragmentation			=> fragmentation,
			ctrl_bbFrameEnd 			=> frameEnd,
			ctrl_FECInputIdle			=> '1',
			in_inputValid				=> source_outputValid,
			in_readyForPreviousBlock		=> inputProcessing_blockReady,
			in_data					=> in_data,
			out_outputValid 			=> inputProcessing_outputValid,
			out_nextBlockReady			=> sink_blockReady,
			out_data				=> inputProcessing_data
		);

	check: entity work.file_checker 
		generic map( 
			handshake_seed                    	=> handshake_seed,
                        handshake_transaction_probability 	=> handshake_transaction_probability_real_sink,
                       	input_data_file                   	=> check_data_file,
                       	input_width                       	=> 1
                )
               port map( 
			clk                      		=> clk,
                        in_inputValid            		=> inputProcessing_outputValid,
                        in_readyForPreviousBlock 		=> sink_blockReady,
                        in_data(0)               		=> inputProcessing_data,
                        end_of_file              		=> sink_eof,
                        result_valid             		=> result_valid,
			current_valid				=> currentValid 
		);

	--clk
	clk_process:	process
	begin
		while(testDone = '0') loop
			clk <= '0';
			wait for clk_period/2;
			clk <= '1';
			wait for clk_period/2;
		end loop;
		wait;
	end process;

	--sync
	sync_process:	process(clk,testDone)
	begin
		if(testDone = '0') then
			if(rising_edge(clk) and inputProcessing_blockReady = '1' and source_outputValid = '1') then
				if(counter = 187) then
					counter <= 0;
					packetCounter <= packetCounter + 1;
					report "Processed " & Integer'Image(packetCounter) & " frames. Result valid: " & std_logic'image(result_valid) & ". Bit errors: " & Integer'image(errorCounter) & "/" & Integer'image(outputCounter) & ".";
				else
					counter <= counter + 1;
				end if;
				
			end if;
			if(rising_edge(clk) and currentValid = '0' and inputProcessing_outputValid = '1') then
				errorCounter <= errorCounter + 1;
			end if;
			if(rising_edge(clk) and inputProcessing_outputValid = '1') then
				outputCounter <= outputCounter + 1;
			end if;
		end if;
	end process;
	sync <= '1' when(counter = 0) else '0';

	--MAIN
	main_process: 	process
   	begin
        	report "Seed: " & integer'image(handshake_seed) & " "&input_data_file&"->"&check_data_file;
        	wait for clk_period*10;
        	reset <= '1';
        	wait for clk_period*10;
       		reset <= '0';
        	report "STARTING TEST: CodeRate " & integer'image(codeRate);
        	wait until source_eof='1' or sink_eof='1';  
        	wait for clk_period*10;
	       	report "FINISHED TEST: CodeRate " & integer'image(codeRate) & " Seed: " & integer'image(handshake_seed) & " "&input_data_file&"->"&check_data_file;
		report "handshake_transaction_probability_source=" & handshake_transaction_probability_source & ", handshake_transaction_probability_sink=" & handshake_transaction_probability_sink;

        	if(result_valid='1') then
            		report "TEST PASSED";
        	else
            		report "TEST FAILED" severity failure;
        	end if;
		testDone <= '1';
        	wait;
    	end process;
end inputProcessing_fullTest_arch;
