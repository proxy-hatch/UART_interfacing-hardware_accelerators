library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity avalon_master is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        --Bus ports
        addr : out std_logic_vector(31 downto 0);
        avread : out std_logic;
        avwrite : out std_logic;
        byteenable : out std_logic_vector(3 downto 0);
        readdata : in std_logic_vector(31 downto 0);
        writedata : out std_logic_vector(31 downto 0);
        waitrequest : in std_logic;
        readdatavalid : in std_logic;
        writeresponsevalid : in std_logic;
        
        --L/S interface
        addr_in : in std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0);
        data_valid : out std_logic;
        ready : out std_logic;
        new_request : in std_logic;
        rnw : in std_logic;
        be : in std_logic_vector(3 downto 0);
        data_ack : in std_logic
    );
end avalon_master;
    
architecture Behavioral of avalon_master is
	

begin
	process (clk)
		-- states
		type state_type is ( state_idle, state_readBUS, state_writeLS, state_writeBUS );
		variable curr_state : state_type := state_type'left;
		-- _int post-fix indicates internal (latched) signal
		variable readdata_int, addr_in_int, data_in_int : std_logic_vector(31 downto 0);
		variable be_int : std_logic_vector(3 downto 0);
	begin
		-- L/S interface handshake
		if rising_edge(clk) then
			case curr_state is
				when state_idle =>
					avread <= '0';
					avwrite <= '0';
					ready <= '1';
					
					if new_request = '1' then
						-- LS side
						ready <= '0';
						addr_in_int := addr_in;
						be_int := be;
						
						if rnw = '1' then	-- read from BUS
							-- BUS side
							avread <= '1';
							curr_state := state_readBUS;
						else				-- write to BUS
							data_in_int := data_in;
							-- BUS side
							avwrite <= '1';
							writedata <= data_in_int;

							curr_state := state_writeBUS;
						end if;
						addr <= addr_in_int;
						byteenable <= be_int;
					else
						curr_state := state_idle;
					end if;
					
				when state_readBUS =>
					if waitrequest = '0' then
						-- BUS side
						readdata_int := readdata;
						avread <= '0';
						avwrite <= '0';
						-- LS side
						data_valid <= '1';
						data_out <= readdata_int;
						
						curr_state := state_writeLS;
					else
						curr_state := state_readBUS;	-- loop
					end if;
					
				when state_writeLS =>
					ready <= '1';
					if data_ack = '1' then
						data_valid <= '0';

						curr_state := state_idle;	-- done
					else
						curr_state := state_writeLS;	-- loop
					end if;	
					
				when state_writeBUS =>
					if waitrequest = '0' then
						-- BUS side
						ready <= '1';
						avwrite <= '0';
						-- writeWaitTime = 0, therefore turn off input after a cycle
						curr_state := state_idle;
					else
						curr_state := state_writeBUS;
					end if;

			end case;
		end if;
	end process;



end Behavioral;


    
    
