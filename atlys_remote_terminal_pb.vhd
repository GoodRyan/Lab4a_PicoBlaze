----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:44:20 03/13/2014 
-- Design Name: 
-- Module Name:    atlys_remote_terminal_pb - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity atlys_remote_terminal_pb is
    port (
             clk        : in  std_logic;
             reset      : in  std_logic;
             serial_in  : in  std_logic;
             serial_out : out std_logic;
             switch     : in  std_logic_vector(7 downto 0);
             led        : out std_logic_vector(7 downto 0)
         );
end atlys_remote_terminal_pb;

architecture remote_arch of atlys_remote_terminal_pb is

signal baud_16x_en_sig		: std_logic;

component clk_to_baud
	port (
		clk         : in std_logic;  -- 100 MHz
      reset       : in std_logic;
      baud_16x_en : out std_logic -- 16*9.6 kHz (use a counter)
	);
end component;

component uart_rx6
	port(
		serial_in : in std_logic;
      en_16_x_baud : in std_logic;
      data_out : out std_logic_vector(7 downto 0);
      buffer_read : in std_logic;
      buffer_data_present : out std_logic;
      buffer_half_full : out std_logic;
      buffer_full : out std_logic;
      buffer_reset : in std_logic;
      clk : in std_logic
	);
end component;

component uart_tx6
	port(
		data_in : in std_logic_vector(7 downto 0);
      en_16_x_baud : in std_logic;
      serial_out : out std_logic;
      buffer_write : in std_logic;
      buffer_data_present : out std_logic;
      buffer_half_full : out std_logic;
      buffer_full : out std_logic;
      buffer_reset : in std_logic;
      clk : in std_logic
	);
end component;

component kcpsm6 
    generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                    interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
             scratch_pad_memory_size : integer := 64);
    port (                   address : out std_logic_vector(11 downto 0);
                         instruction : in std_logic_vector(17 downto 0);
                         bram_enable : out std_logic;
                             in_port : in std_logic_vector(7 downto 0);
                            out_port : out std_logic_vector(7 downto 0);
                             port_id : out std_logic_vector(7 downto 0);
                        write_strobe : out std_logic;
                      k_write_strobe : out std_logic;
                         read_strobe : out std_logic;
                           interrupt : in std_logic;
                       interrupt_ack : out std_logic;
                               sleep : in std_logic;
                               reset : in std_logic;
                                 clk : in std_logic);
end component;

signal         address : std_logic_vector(11 downto 0);
signal     instruction : std_logic_vector(17 downto 0);
signal     bram_enable : std_logic;
signal   kcpsm6_in_port : std_logic_vector(7 downto 0);
signal  kcpsm6_out_port : std_logic_vector(7 downto 0);
signal         port_id : std_logic_vector(7 downto 0);
signal    write_strobe : std_logic;
signal  k_write_strobe : std_logic;
signal     read_strobe : std_logic;
signal       interrupt : std_logic;
signal   interrupt_ack : std_logic;
signal    kcpsm6_sleep : std_logic;
signal    kcpsm6_reset : std_logic;

--
-- Some additional signals are required if your system also needs to reset KCPSM6. 
--

signal       cpu_reset : std_logic;
signal             rdl : std_logic;

signal		 data_route : std_logic_vector(7 downto 0);
signal		 read_data_present : std_logic;
signal		 write_data_present : std_logic;

begin

clk_to_baud_init: clk_to_baud
	port map(
		clk => clk,
		reset => reset,
		baud_16x_en => baud_16x_en_sig
	);

--LED output
LED <= kcpsm6_out_port;

processor: kcpsm6
    generic map (                 hwbuild => X"00", 
                         interrupt_vector => X"3FF",
                  scratch_pad_memory_size => 64)
    port map(      address => address,
               instruction => instruction,
               bram_enable => bram_enable,
                   port_id => port_id,
              write_strobe => write_strobe,
            k_write_strobe => k_write_strobe,
                  out_port => kcpsm6_out_port,
               read_strobe => read_strobe,
                   in_port => kcpsm6_in_port,
                 interrupt => interrupt,
             interrupt_ack => interrupt_ack,
                     sleep => kcpsm6_sleep,
                     reset => kcpsm6_reset,
                       clk => clk);
	
rx: uart_rx6 
  port map (            serial_in => serial_in,
                     en_16_x_baud => baud_16x_en_sig,
                         data_out => data_route,
                      buffer_read => read_data_present,
              buffer_data_present => write_data_present,
                 buffer_half_full => open,
                      buffer_full => open,
                     buffer_reset => '0',              
                              clk => clk
);

  tx: uart_tx6 
  port map (              data_in => data_route,
                     en_16_x_baud => baud_16x_en_sig,
                       serial_out => serial_out,
                     buffer_write => write_data_present,
              buffer_data_present => read_data_present,
                 buffer_half_full => open,
                      buffer_full => open,
                     buffer_reset => '0',              
                              clk => clk
);

	


end remote_arch;
