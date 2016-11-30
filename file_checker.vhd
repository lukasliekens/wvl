library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use work.txt_util.all;

entity file_checker is
generic (
	-- Random handshaking
	handshake_seed: positive := 312;
	handshake_transaction_probability: real := 0.05;
	handshake_read_after_eof: boolean := false; 

	-- File to read from
	input_data_file: string := "input.txt";

	-- Input settings
	input_width: positive := 1;
	input_drop: integer := 0 -- Number of transactions to drop before comparing against the file
);
port(
	-- Clock
	clk: in std_logic;

	-- Interface to tested modules
	in_inputValid: in std_logic;
	in_readyForPreviousBlock: out std_logic;
	in_data: in std_logic_vector(input_width-1 downto 0);

	-- Testbench interface
	end_of_file: out std_logic;
	result_valid: out std_logic;
	current_valid: out std_logic
);
end file_checker;  

architecture file_checker_arch of file_checker is
    file input_data: TEXT open read_mode is input_data_file;

	signal readyForPreviousBlock: std_logic :='0';
    signal outputEOF: std_logic := '0';
    signal outputResultValid: std_logic := '1';

	signal debug_currentValid: std_logic := '1';

	signal dropCountdown: integer range 0 to input_drop := input_drop;
begin

	--This process adds random delays to reading the data. This is done to stress-test the handshaking logic.
	inputCheck: process(clk)
		variable random_seed1: positive := handshake_seed;
		variable random_seed2: positive := 580703472;
		variable random_out: real;

		variable lineRead: line;
		variable data: string(input_width downto 1);

		variable data_vector: std_logic_vector(input_width-1 downto 0);
	begin
		if (rising_edge(clk)) then
			
			if(readyForPreviousBlock = '1' and in_inputValid='1') then
				-- Some data has been transferred.
				readyForPreviousBlock <= '0';
				
				if(dropCountdown > 0) then
					dropCountdown <= dropCountdown-1;
				elsif(not endfile(input_data)) then
					readline(input_data, lineRead);
					read(lineRead, data);
					data_vector := to_std_logic_vector(data);

					--Check it
					if(data_vector /= in_data) then
						debug_currentValid <= '0';
						outputResultValid<='0';
					else
						debug_currentValid<='1';
					end if;
				end if;

				--At the end of file now?
				if(endfile(input_data)) then
					outputEOF <= '1';	
				end if;
			end if;

			-- Take a random number and decide if we will start a transaction
			uniform(random_seed1, random_seed2, random_out);
			if(random_out <= handshake_transaction_probability) then
				if(handshake_read_after_eof = true or not endfile(input_data)) then
					readyForPreviousBlock <= '1';
				end if;
			end if;

		end if;
	end process;

	in_readyForPreviousBlock <= readyForPreviousBlock;
	result_valid <= outputResultValid;
	end_of_file <= outputEOF;
	current_valid <= debug_currentValid;

end file_checker_arch;

