----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    port (
        i_clk   : in  std_logic;
        i_reset : in  std_logic;
        i_adv   : in  std_logic;
        o_cycle : out std_logic_vector(3 downto 0)
    );
end controller_fsm;

architecture FSM of controller_fsm is

    signal fsm_state      : std_logic_vector(3 downto 0) := "1000";
    signal adv_prev_state : std_logic := '0';

begin

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                fsm_state <= "1000";  -- Reset to initial state
            else
                -- Detect rising edge on i_adv
                if i_adv = '1' and adv_prev_state = '0' then
                    case fsm_state is
                        when "1000" => fsm_state <= "0001";
                        when "0001" => fsm_state <= "0010";
                        when "0010" => fsm_state <= "0100";
                        when "0100" => fsm_state <= "1000";
                        when others => fsm_state <= "1000";
                    end case;
                end if;
            end if;

            -- Store previous adv state for edge detection
            adv_prev_state <= i_adv;
        end if;
    end process;

    -- Output current FSM state
    o_cycle <= fsm_state;

end FSM;