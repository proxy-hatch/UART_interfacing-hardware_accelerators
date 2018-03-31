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

-------------------REMOVE AFTER TASK 1-----------------
--This code is only present to prevent the
--compiler from optimizing away
--the processor.  It does not implement the
--behaviour required for this lab

    process (clk) is
    begin
        if (clk'event and clk = '1') then
                addr <= addr_in;
                data_out <= readdata;
                writedata <= data_in;
                data_valid <= new_request and not data_ack; 
            end if;
        end if;
    end process;
-----------------------------------------------------------------
  
end Behavioral;

    
    
    
