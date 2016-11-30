library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity padding is
port(
	-- Clock
	clk: in std_logic;
	--24 code rates mogelijk 
	ctrl_LDPCCode : in integer range 0 to 23;
	padding_length : out integer range 0 to 1504
);
end padding;

architecture padding_arch of padding is
	
begin
	padding_pros : process (ctrl_LDPCCode)
	begin	
	    case ctrl_LDPCCode is
	       when 0 => padding_length <= 1489;
	       when 1 => padding_length <= 937;
	       when 2 => padding_length <= 217;
	       when 3 => padding_length <= 641;
	       when 4 => padding_length <= 449;
	       when 5 => padding_length <= 25;
	       when 6 => padding_length <= 1105;
	       when 7 => padding_length <= 321;
	       when 8 => padding_length <= 1041;
	       when 9 => padding_length <= 617;
	       when 10 => padding_length <= 889;
	       when 11 => padding_length <= 545;
	       when 12 => padding_length <= 81;
	       when 13 => padding_length <= 273;
	       when 14 => padding_length <= 1009;
	       when 15 => padding_length <= 849;
		   when 16 => padding_length <= 201;
		   when 17 => padding_length <= 433;
		   when 18 => padding_length <= 1121;
		   when 19 => padding_length <= 241;
		   when 20 => padding_length <= 961;
		   when others  => padding_length <= 0;
		end case;
	end process padding_pros;

end padding_arch;
