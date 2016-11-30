library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use work.txt_util.all;

entity file_generator is
generic (
	-- Random handshaking
	handshake_seed: positive := 312;
	handshake_transaction_probability: real := 0.2;

	-- File to read from
	input_data_file: string := "input.txt";

	-- Output settings
	output_width: positive := 1;
	zero_at_eof: boolean := false
);
port(
	-- Clock
	clk: in std_logic;

	-- Interface to tested modules
	out_outputValid: out std_logic;
	out_nextBlockReady: in std_logic;
	out_data: out std_logic_vector(output_width-1 downto 0);

	-- Testbench interface
	end_of_file: out std_logic
);
end file_generator;  

architecture file_generator_arch of file_generator is
	signal outputValid: std_logic := '0';
	signal outputData: std_logic_vector(out_data'range) := (others=> '0');
	signal outputEOF: std_logic := '0';

    file input_data: TEXT open read_mode is input_data_file;
begin

	--This process adds random delays to providing the data. This is done to stress-test the handshaking logic.
	outputGen: process(clk)
		variable random_seed1: positive := handshake_seed;
		variable random_seed2: positive := 1357981086;
		variable random_out: real;

		variable outputValidWork: std_logic;

		variable lineRead: line;
		variable data: string(output_width downto 1);
	begin
		if (rising_edge(clk)) then
			outputValidWork := outputValid;

			if(outputValidWork = '1' and out_nextBlockReady='1') then
				-- Some data has been transferred.
				outputValidWork := '0';
			end if;

			if(outputValidWork = '0') then
				-- Take a random number and decide if we will start a transaction
				uniform(random_seed1, random_seed2, random_out);
				if(random_out <= handshake_transaction_probability) then

					if(endfile(input_data)) then
			            outputEOF <= '1';
						outputData <= (others=>'0');
						if(zero_at_eof) then
							outputValidWork := '1';
						end if;
					else
						readline(input_data, lineRead);
						read(lineRead, data);
						outputData <= to_std_logic_vector(data);
						outputValidWork := '1';
					end if;


				end if;
			end if;
			outputValid <= outputValidWork;
		end if;
	end process;

	out_outputValid <= outputValid;
	out_data <= outputData;
	end_of_file <= outputEOF;

end file_generator_arch;

