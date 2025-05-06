----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    port (
        i_A      : in  std_logic_vector(7 downto 0);
        i_B      : in  std_logic_vector(7 downto 0);
        i_op     : in  std_logic_vector(2 downto 0);  -- Opcode
        o_result : out std_logic_vector(7 downto 0);
        o_flags  : out std_logic_vector(3 downto 0)   -- NZCV
    );
end ALU;

architecture behavioral of ALU is

    -- Ripple adder component
    component ripple_adder
        port (
            A    : in  std_logic_vector(3 downto 0);
            B    : in  std_logic_vector(3 downto 0);
            Cin  : in  std_logic;
            S    : out std_logic_vector(3 downto 0);
            Cout : out std_logic
        );
    end component;

    -- Internal signals
    signal alu_result      : std_logic_vector(7 downto 0) := (others => '0');
    signal add_sub_sum     : std_logic_vector(7 downto 0) := (others => '0');
    signal carry_out_low   : std_logic;
    signal carry_out_high  : std_logic;
    signal B_muxed         : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- First 4-bit ripple adder
    u_ripple_adder_low: ripple_adder
        port map (
            A    => i_A(3 downto 0),
            B    => B_muxed(3 downto 0),
            Cin  => i_op(0),
            S    => add_sub_sum(3 downto 0),
            Cout => carry_out_low
        );

    -- Second 4-bit ripple adder
    u_ripple_adder_high: ripple_adder
        port map (
            A    => i_A(7 downto 4),
            B    => B_muxed(7 downto 4),
            Cin  => carry_out_low,
            S    => add_sub_sum(7 downto 4),
            Cout => carry_out_high
        );

    -- Select between add or subtract
    with i_op(0) select
        B_muxed <= i_B        when '0',  -- Add
                   not i_B    when others;  -- Subtract

    -- ALU result MUX based on opcode
    with i_op select
        alu_result <= add_sub_sum     when "000",  -- ADD
                      add_sub_sum     when "001",  -- SUB
                      i_A and i_B     when "010",  -- AND
                      i_A or i_B      when "011",  -- OR
                      (others => '0') when others; -- Default 0

    -- Output assignment
    o_result <= alu_result;

    -- Flags N Z C V
    o_flags(3) <= alu_result(7); -- Negative flag N
    
    o_flags(2) <= not(alu_result(0) or alu_result(1) or alu_result(2) or alu_result(3) or 
                      alu_result(4) or alu_result(5) or alu_result(6) or alu_result(7)); -- Zero Z

    o_flags(1) <= not i_op(1) and carry_out_high; -- Carry C only for ADD/SUB

    o_flags(0) <= (not (i_op(0) xor (i_A(7) xor i_B(7)))) and
                  (i_A(7) xor add_sub_sum(7)) and
                  (not i_op(1)); -- Overflow V

end behavioral;
