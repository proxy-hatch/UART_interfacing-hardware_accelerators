library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity bitops_unit is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        --decode/issue
        new_request_dec : in std_logic;
        new_request : in std_logic;
        ready : out std_logic;
        
        --writeback
        early_done : out std_logic;
        accepted : in std_logic;
        rd : out std_logic_vector(31 downto 0);
        
        --inputs
        rs1 : in std_logic_vector(31 downto 0);
        fn3 : in std_logic_vector(2 downto 0);
        fn3_dec : in std_logic_vector(2 downto 0)
    );
end bitops_unit;
    
architecture Behavioral of bitops_unit is
	-- latch result in the event of waiting for 'accepted'
	signal latched_rd : std_logic_vector(31 downto 0);
	-- -- LUT for state_POPC
	-- type bitsSetTable is array (0 to 255) of integer range 0 to 8;
	-- signal POPCTable : bitsSetTable;
	-- signal doneGenPOPCLUT : std_logic := '0';
begin

	-- -- generate LUT for use in state_POPC
	-- process (all)
		-- if doneGenPOPCLUT = '0' then
			-- for I in 0 to 255 loop
				-- POPCTable(I) = to_integer(unsigned(I, 1) and '1') + POPCTable(unsigned(I, 8)>>2);
			-- end loop;
			-- doneGenPOPCLUT <= '1';
		-- end if;
	-- end process;
		
    process (clk) is
		-- states
		type state_type is ( state_idle, state_CLZ, state_POPC, state_waitACK );
		variable curr_state : state_type := state_type'left;
		
		-- temporarily store rd before ouput
		variable output : unsigned(31 downto 0);

    begin
        if rising_edge(clk) then
			-- make sure rst is not set when its first initializing in state_init!
            if (rst = '1') then
                ready <= '1';
				early_done <= '0';
				rd <= (rd'range => '0');

				curr_state := state_idle;
			end if;
			case curr_state is
			-- when state_init =>
				-- -- outputs
				-- ready <= '0';
				-- early_done <= '0';
				-- rd <= (rd'range => '0');
				-- -- wait for generating of LUT for state_POPC
				-- if doneGenPOPCLUT = '1' then
					-- curr_state := state_idle;
				-- else
					-- curr_state := state_init;
				-- end if;
				
			when state_idle =>
				if new_request_dec = '1' then
					case fn3_dec is
--						when "000" =>
--							curr_state := state_CLZ;
--						when "001" =>
--							curr_state := state_POPC;
--						when "010" =>
--							curr_state := state_SWAPB;
						when others =>
--							curr_state := state_SQRT;
							curr_state := state_CLZ;
					end case;
					early_done <= '1';
				else
					early_done <= '0';
					curr_state := state_idle;
				end if;
				-- other outputs
				ready <= '1';
				rd <= (rd'range => '0');
			
			when state_CLZ =>	-- count leading zero
				-- since we are not concerned with area efficiency, the fastest way to implement this is thru a LUT
				if rs1 = 0 then
					-- apparently output is represented by 2's complement (signed)
					output := (30 downto 0=>'1', 31=>'0');
				elsif rs1(31 downto 1) = 0 then
					output := to_unsigned(31, 32);
				elsif rs1(31 downto 2) = 0 then
					output := to_unsigned(30, 32);
				elsif rs1(31 downto 3) = 0 then
					output := to_unsigned(29, 32);
				elsif rs1(31 downto 4) = 0 then
					output := to_unsigned(28, 32);
				elsif rs1(31 downto 5) = 0 then
					output := to_unsigned(27, 32);
				elsif rs1(31 downto 6) = 0 then
					output := to_unsigned(26, 32);
				elsif rs1(31 downto 7) = 0 then
					output := to_unsigned(25, 32);
				elsif rs1(31 downto 8) = 0 then
					output := to_unsigned(24, 32);
				elsif rs1(31 downto 9) = 0 then
					output := to_unsigned(23, 32);
				elsif rs1(31 downto 10) = 0 then
					output := to_unsigned(22, 32);
				elsif rs1(31 downto 11) = 0 then
					output := to_unsigned(21, 32);
				elsif rs1(31 downto 12) = 0 then
					output := to_unsigned(20, 32);
				elsif rs1(31 downto 13) = 0 then
					output := to_unsigned(19, 32);
				elsif rs1(31 downto 14) = 0 then
					output := to_unsigned(18, 32);
				elsif rs1(31 downto 15) = 0 then
					output := to_unsigned(17, 32);
				elsif rs1(31 downto 16) = 0 then
					output := to_unsigned(16, 32);
				elsif rs1(31 downto 17) = 0 then
					output := to_unsigned(15, 32);
				elsif rs1(31 downto 18) = 0 then
					output := to_unsigned(14, 32);
				elsif rs1(31 downto 19) = 0 then
					output := to_unsigned(13, 32);
				elsif rs1(31 downto 20) = 0 then
					output := to_unsigned(12, 32);
				elsif rs1(31 downto 21) = 0 then
					output := to_unsigned(11, 32);
				elsif rs1(31 downto 22) = 0 then
					output := to_unsigned(10, 32);
				elsif rs1(31 downto 23) = 0 then
					output := to_unsigned(9, 32);
				elsif rs1(31 downto 24) = 0 then
					output := to_unsigned(8, 32);
				elsif rs1(31 downto 25) = 0 then
					output := to_unsigned(7, 32);
				elsif rs1(31 downto 26) = 0 then
					output := to_unsigned(6, 32);
				elsif rs1(31 downto 27) = 0 then
					output := to_unsigned(5, 32);
				elsif rs1(31 downto 28) = 0 then
					output := to_unsigned(4, 32);
				elsif rs1(31 downto 29) = 0 then
					output := to_unsigned(3, 32);
				elsif rs1(31 downto 30) = 0 then
					output := to_unsigned(2, 32);
				elsif rs1(31) = '0' then
					output(0) := '1';
				else
					output := (31 downto 0=>'0');
				end if;
				latched_rd <= std_logic_vector(output);

				-- outputs
				ready <= accepted;
				rd <= std_logic_vector(output);
				-- other outputs and where to go
				if accepted = '0' then
					early_done <= '1';
					
					curr_state := state_waitACK;
				else
					if new_request_dec = '1' then
						early_done <= '1';
						case fn3_dec is
--						when "000" =>
--							curr_state := state_CLZ;
--						when "001" =>
--							curr_state := state_POPC;
--						when "010" =>
--							curr_state := state_SWAPB;
						when others =>
--							curr_state := state_SQRT;
							curr_state := state_CLZ;
						end case;
					else
						early_done <= '0';
						
						curr_state := state_idle;
					end if;
 				end if;
				
			-- when state_POPC =>	-- population count
				-- output := POPCTable(unsigned(rs1(31 downto 24))) + POPCTable(unsigned(rs1(23 downto 16))) + POPCTable(unsigned(rs1(15 downto 8))) + POPCTable(unsigned(rs1(7 downto 0))); 
			

			when state_waitACK =>
				-- outputs
				ready <= accepted;
				rd <= latched_rd;
				-- other outputs and where to go
				if accepted = '0' then
					early_done <= '1';
					
					curr_state := state_waitACK;
				else
					if new_request_dec = '1' then
						early_done <= '1';
						case fn3_dec is
--						when "000" =>
--							curr_state := state_CLZ;
--						when "001" =>
--							curr_state := state_POPC;
--						when "010" =>
--							curr_state := state_SWAPB;
						when others =>
--							curr_state := state_SQRT;
							curr_state := state_CLZ;
						end case;
					else
						early_done <= '0';
						
						curr_state := state_idle;
					end if;

					curr_state := state_idle;
 				end if;
				
			when others =>
                ready <= '1';
				early_done <= '0';
				rd <= (rd'range => '0');
				curr_state := state_idle;

			end case;
			
        end if;
    end process;
    

end Behavioral;