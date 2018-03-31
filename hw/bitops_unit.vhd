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
    signal done : std_logic;
begin

-------------------REMOVE AFTER TASK 1-----------------
--This code is only present to prevent the
--compiler from optimizing away
--the processor.  It does not implement the
--behaviour required for this lab
    process (clk) is
    begin
        if (clk'event and clk = '1') then
            if (rst = '1') then
                done <= '0';
            elsif (new_request = '1') then
                done <= '1';
            elsif (accepted = '1') then
                done <= '0';
            end if;
        end if;
    end process;
    
    ready <= not done;
    early_done <= done and not accepted;
    
    rd <= rs1;
-----------------------------------------------------------------
end Behavioral;

    
    
    
