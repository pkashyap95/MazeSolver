
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_arith.ALL;
use IEEE.std_logic_unsigned.ALL;


entity vga_sync is
    Port ( 
           clk : in  std_logic;--! 100 MHz clock on the Basys3 board
           rst: in std_logic;-- to VGA ports
           hsync : out  std_logic;--! Connect to the HSync pin in the top level.
           vsync : out  std_logic;--! Connect to the VSync pin in the top level.
           -- to Graphics Engine
		   onDisplay: out std_logic;--! '1' when displaying a visible pixel.
		   endOfFrame: out std_logic; --! '1' for one cycle when the visible 
									   --! frame is completed.
           current_x: out std_logic_vector(9 downto 0);--! the x coordinate of the pixel currently being displayed 
           current_y: out std_logic_vector(9 downto 0);--! the y coordinate of the pixel currently being displayed 
           clk_vga: out std_logic --! Clock (25 MHz) for the VGA components.
           );
end vga_sync;

architecture behavioral of vga_sync is

signal clk_vga_int: std_logic;
signal clk_divider: std_logic;
signal hscan: std_logic_vector(9 downto 0);
signal vscan: std_logic_vector(9 downto 0);
signal on_display_int: std_logic;

-- Display Range
constant HBEGIN: std_logic_vector(9 downto 0):= "00" & x"90"; -- 144 
constant HEND: std_logic_vector(9 downto 0):= "11" & x"0F"; -- 783
-- Note HBEGIN - HEND + 1 = 640
constant VBEGIN: std_logic_vector(9 downto 0):= "00" & x"23"; -- 35 
constant VEND: std_logic_vector(9 downto 0):=  "10" & x"03"; -- 515
-- Note HBEGIN - HEND + 1 = 480
-- End of scans
constant HSCANEND: std_logic_vector(9 downto 0):= "11" & x"20"; -- 800 
constant VSCANEND: std_logic_vector(9 downto 0):= "10" & x"0D"; -- 525
-- Sync Pulse Limit
constant HSYNCEND: std_logic_vector(9 downto 0):= "00" & x"60"; -- 96 
constant VSYNCEND: std_logic_vector(9 downto 0):= "0000000010"; -- 2

begin

clk_vga <= clk_vga_int;
current_x <= hscan - HBEGIN when on_display_int = '1'
             else (others => '0');
current_y <= vscan - VBEGIN when on_display_int = '1'
                          else (others => '0');
onDisplay <= on_display_int;                          
on_display_int <= '1' when hscan > HBEGIN and hscan < HEND and vscan > VBEGIN and vscan < VEND
             else '0';
endOfFrame <= '1' when hscan = HEND + "10" and vscan = VEND + "10"
             else '0';
--! @brief  Clock divider process
--!	
--! Divides the master clock - clk (100 MHz) by 1/4 to
--! generate the vga_clk (25 Mhz)
CLKDIVIDER:process(clk, rst)
  begin
    if(rst = '1') then
      clk_vga_int <= '0';
      clk_divider <= '0';
    elsif (clk = '1' and clk'event) then	   
	   clk_divider <= not clk_divider;
	   if(clk_divider = '0') then
	       clk_vga_int <= not clk_vga_int;
	    end if;   
	end if;
  end process;

--! @brief Scan Counter Generation Process
--!
--! This process generates the main scan counters vscan and hscan
Scan_Counter:process(clk_vga_int, rst)
  begin
    if(rst = '1') then
      hscan <= (others => '0');
      vscan <= (others => '0');
    elsif (clk_vga_int'event and clk_vga_int = '1') then
	   if (hscan = HSCANEND) then
		  hscan <= (others => '0');
	      if (vscan= VSCANEND) then
		    vscan<=(others => '0');	
	      else
		    vscan<=vscan+'1';
	      end if;
	   else
		  hscan <= hscan + '1';
	   end if;			
	 end if;
  end process;

  -- horizontal sync for 96 horizontal clocks (96 pixels) (Till HSYNCEND)
  hsync <= '0' when hscan < HSYNCEND else '1';
  -- vertical sync for 2 scan lines
  vsync <= '0' when vscan< VSYNCEND else '1';

end behavioral;
