LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use ieee.std_logic_textio.all;
use std.textio.all;
 
ENTITY Tb IS
END Tb;
 
ARCHITECTURE behavior OF Tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TopModule
    PORT(
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           Output : OUT  std_logic_vector(14 downto 0);
           input : in std_logic_vector (13 downto 0)
        );
    END COMPONENT;
    
--COMPONENT DDS_Tb
--  PORT (
--    aclk : IN STD_LOGIC;
--    m_axis_data_tvalid : OUT STD_LOGIC;
--    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--    m_axis_phase_tvalid : OUT STD_LOGIC;
--    m_axis_phase_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
--  );
--END COMPONENT;


   --Inputs
   signal Clock : std_logic := '0';
   signal reset : std_logic := '0';
--   signal input : std_logic_vector (15 downto 0) := (others => '0');
   signal Input_Signal : signed(13 downto 0);
   signal Output_Signal : signed(14 downto 0);


   -- Clock period definitions
   constant Clock_period : time := 6666 ps;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TopModule PORT MAP (
          Clock => Clock,
          reset => reset,
          signed(Output) => Output_Signal,
          input => std_logic_vector(Input_Signal)
        );

--DDS_Ins : DDS_Tb
--  PORT MAP (
--    aclk => Clock,
--    m_axis_data_tvalid => open,
--    m_axis_data_tdata => input,
--    m_axis_phase_tvalid => open,
--    m_axis_phase_tdata => open
--  );







   -- Clock process definitions
   Clock_process :process
   begin
		Clock <= '0';
		wait for Clock_period/2;
		Clock <= '1';
		wait for Clock_period/2;
   end process;
 
 
 

	P1: process
	begin
	reset <='1';
	--hold reset state for 100 ns
	wait for 67ns;
	reset <='0';
	--inset stimulus here
	wait;
end process;		



	Read_Input_Vector: process(Clock)
	
		file		input_text	: text open read_mode is "C:\Users\Hasan\My_Projects\DSP\Temp2\Matlab\input_Vec.txt";
		variable LI1			: line;
		variable LI1_var		: integer;
		
	begin
	
		if rising_edge(Clock) then
		
			readline(input_text,LI1);
			read(LI1,LI1_var);
			Input_Signal				<= to_signed(LI1_var,14);
			
		end if;	
	end process;



	write_Output_Vector: process(Clock)
	
		file 		output_text	: text open write_mode is "C:\Users\Hasan\My_Projects\DSP\Temp2\Matlab\Output_Vec_VHDL.txt";
		variable LO1			: line;
		
	begin
	
		if rising_edge(Clock) then
		
			write(LO1, to_integer(Output_Signal));
			writeline(output_text , LO1);
			
		end if;
	end process;

END;
