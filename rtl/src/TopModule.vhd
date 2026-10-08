----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2026 11:28:23 AM
-- Design Name: 
-- Module Name: TopModule - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TopModule is
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           input : in std_logic_vector (13 downto 0);   
           output : out std_logic_vector (14 downto 0)
           );
end TopModule;

architecture Behavioral of TopModule is

----------------------------------Components--------------------------------------
COMPONENT DDS
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_phase_tvalid : OUT STD_LOGIC;
    m_axis_phase_tdata : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;

COMPONENT CIC_Filter
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT CORDIC
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_cartesian_tvalid : IN STD_LOGIC;
    s_axis_cartesian_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
  );
END COMPONENT;
--------------------------------------------------------------------------------
constant number_1 : signed (13 downto 0) := to_signed(4295, 14); -- +1.048576 with 12 fractional bits (s.1.12)
--signal input_buf : signed (13 downto 0) := (others =>'0');
signal notReset : std_logic;
signal output_buf : signed (45 downto 0) := (others =>'0');
signal delay200Clock : unsigned (7 downto 0) := (others =>'0');
signal sinand_cos_DDS : std_logic_vector (31 downto 0) := (others =>'0');
signal cos_DDS : signed (13 downto 0) := (others =>'0');
signal sin_DDS : signed (13 downto 0) := (others =>'0');
signal DDS_Output_Valid : std_logic;
signal DDS_Output_Valid_OneClock_Delay : std_logic;
signal mixer_i : signed (27 downto 0) := (others =>'0');
signal mixer_q : signed (27 downto 0) := (others =>'0');
signal mixer_i_Scaled : signed (13 downto 0) := (others =>'0');
signal mixer_q_Scaled : signed (13 downto 0) := (others =>'0');

signal cic_i_input  : std_logic_vector (15 downto 0) := (others =>'0');
signal cic_q_input  : std_logic_vector (15 downto 0) := (others =>'0');
signal cic_i_output : std_logic_vector (31 downto 0) := (others =>'0');
signal cic_q_output : std_logic_vector (31 downto 0) := (others =>'0');
signal cic_i_Valid : std_logic;
signal cic_q_Valid : std_logic;
signal cordicinput : std_logic_vector (63 downto 0) := (others =>'0');
signal cordicOutput : std_logic_vector (63 downto 0) := (others =>'0');
signal cordicValid : std_logic;


signal amplitude : signed (31 downto 0) := (others =>'0');


begin

------------------------------instantiations----------------------------------------
DDS_1 : DDS
  PORT MAP (
    aclk => clock,
    aresetn => notReset,
    m_axis_data_tvalid => DDS_Output_Valid,
    m_axis_data_tdata => sinand_cos_DDS,
    m_axis_phase_tvalid => open,
    m_axis_phase_tdata => open
  );


CIC_1 : CIC_Filter
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_data_tdata => cic_i_input,
    s_axis_data_tvalid => DDS_Output_Valid_OneClock_Delay,
    s_axis_data_tready => open,
    m_axis_data_tdata => cic_i_output,
    m_axis_data_tvalid => cic_i_Valid
  );

CIC_2 : CIC_Filter
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_data_tdata => cic_q_input,
    s_axis_data_tvalid => DDS_Output_Valid_OneClock_Delay,
    s_axis_data_tready => open,
    m_axis_data_tdata => cic_q_output,
    m_axis_data_tvalid => cic_q_Valid
  );


CORDIC_1 : CORDIC
  PORT MAP (
    aclk => clock,
    aresetn =>notReset,
    s_axis_cartesian_tvalid => cic_i_Valid and cic_q_Valid,
    s_axis_cartesian_tdata => cordicinput,
    m_axis_dout_tvalid => cordicValid,
    m_axis_dout_tdata => cordicoutput
  );
--------------------------------------------------------------------------------

notReset <= not reset;
cos_DDS <= signed(sinand_cos_DDS(13 downto 0));
sin_DDS <= signed(sinand_cos_DDS(29 downto 16));
mixer_i_Scaled <= mixer_i (26 downto 13);
mixer_q_Scaled <= mixer_q (26 downto 13);
cic_i_input <= std_logic_vector(resize(mixer_i_Scaled,16));
cic_q_input <= std_logic_vector(resize(mixer_q_Scaled,16));
cordicinput <= cic_q_output & cic_i_output;
--amplitude <= signed(cordicoutput(31 downto 0));


output <= std_logic_vector(output_buf(42 downto 28));



process (clock) begin
if rising_edge (clock) then
if (reset='1') then
    amplitude<=(others =>'0');
    mixer_i<=(others =>'0');
    mixer_q<=(others =>'0');
    output_buf<=(others =>'0');
    delay200Clock<=(others =>'0');
    DDS_Output_Valid_OneClock_Delay <='0';
else
    DDS_Output_Valid_OneClock_Delay <= DDS_Output_Valid;
    mixer_i <=signed(input) * cos_DDS;
    mixer_q <=signed(input) * sin_DDS;
    if (cordicValid = '1') then
        amplitude <= signed(cordicoutput(31 downto 0));
    end if;
    
    if (delay200Clock < to_unsigned(200, delay200Clock'length)) then
        delay200Clock <= delay200Clock + 1;
    else
        output_buf <= amplitude * number_1;
    end if;

end if;
end if;
end process;
    

end Behavioral;