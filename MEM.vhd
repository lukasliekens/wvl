--MEM--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM is
	port(	 clk           : in  std_logic;
		 data_send     : in  std_logic; --ENABLE READ,should be '0' when not in use.  
		 input_valid   : in  std_logic; --ENABLE WRITE,should be '0' when not in use.  
		 in_data       : in  std_logic_vector(7 downto 0); --input data, vector 
		 data_ser      : out std_logic; --output data, not a vector anymore but 'serialized'
		 serializer_rst: in std_logic;
		 -- niet zeker of we empty en full nodig zullen hebben, voorlopig laten we dit staan
		 empty         : out std_logic; --set as '1' when the queue is empty  
		 full          : out std_logic  --set as '1' when the queue is full 
	 
	);
end MEM;

architecture MEM_arch of MEM is
	type memory_type is array (1503 downto 0) of std_logic;
	signal memory   : memory_type := (others => '0'); --memory for queue, wordt gewoon op nul gezet
	signal ReadPtr  : integer range 0 to 1600 :=0; --read pointers (pointers wijzen naar geheugenadres)
	signal WritePtr : integer range 0 to 1600 :=0; --write pointer

begin
	process(clk)
	begin
		if (serializer_rst = '1') then
			ReadPtr <= 0;
			WritePtr <= 0;
			memory <= (others => '0');
			data_ser <= 'Z';
	
			
		elsif (clk'event and clk = '1') then
			if input_valid = '1'  then
			memory(WritePtr)     <= in_data(7);
			memory(WritePtr + 1) <= in_data(6);
			memory(WritePtr + 2) <= in_data(5);
			memory(WritePtr + 3) <= in_data(4);
			memory(WritePtr + 4) <= in_data(3);
			memory(WritePtr + 5) <= in_data(2);
			memory(WritePtr + 6) <= in_data(1);
			memory(WritePtr + 7) <= in_data(0);
			WritePtr             <= WritePtr + 8; --points now 8 addresses further, because in_data is 8 bit and we assign every bit to an address
			end if;
		
			if data_send = '1' then
			data_ser <= memory(ReadPtr);
			ReadPtr  <= ReadPtr + 1;  --points to next address (not +8 because data_ser is only 1 bit)  		
			end if;
		end if;
		if (ReadPtr >= 1503) then        --resetting read pointer.  
			ReadPtr <= 0;
		end if;
		if (WritePtr >= 1503) then       --checking whether queue is full or not
			full     <= '1';
			WritePtr <= 0;
		else
			full <= '0';
		end if;
		if (WritePtr = 0) then          --checking whether queue is empty or not  
			empty <= '1';
		else
			empty <= '0';
		end if;
		

	end process;
end MEM_arch; 











