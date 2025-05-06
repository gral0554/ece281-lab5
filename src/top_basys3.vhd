--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_basys3 is
    port(
        -- Inputs
        clk     : in std_logic;  -- 100 MHz FPGA clock
        sw      : in std_logic_vector(7 downto 0);  -- operands + opcode
        btnU    : in std_logic;  -- sync reset
        btnC    : in std_logic;  -- step FSM
        btnL    : in std_logic;  -- async reset for clock divider
        
        -- Outputs
        led     : out std_logic_vector(15 downto 0);
        seg     : out std_logic_vector(6 downto 0);  -- 7-seg cathodes
        an      : out std_logic_vector(3 downto 0)   -- 7-seg anodes
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- Component Declarations
    component clock_divider
        generic (k_DIV : natural := 2);
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            o_clk   : out std_logic
        );
    end component;

    component controller_fsm
        port (
            i_clk    : in std_logic;
            i_reset  : in std_logic;
            i_adv    : in std_logic;
            o_cycle  : out std_logic_vector(3 downto 0)
        );
    end component;

    component ALU
        port (
            i_A      : in std_logic_vector(7 downto 0);
            i_B      : in std_logic_vector(7 downto 0);
            i_op     : in std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags  : out std_logic_vector(3 downto 0)
        );
    end component;

    component TDM4
        generic (k_WIDTH : natural := 4);
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            i_D3    : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D2    : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D1    : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D0    : in std_logic_vector(k_WIDTH - 1 downto 0);
            o_data  : out std_logic_vector(k_WIDTH - 1 downto 0);
            o_sel   : out std_logic_vector(3 downto 0)
        );
    end component;

    component twos_comp
        port (
            i_bin   : in std_logic_vector(7 downto 0);
            o_sign  : out std_logic;
            o_hund  : out std_logic_vector(3 downto 0);
            o_tens  : out std_logic_vector(3 downto 0);
            o_ones  : out std_logic_vector(3 downto 0)
        );
    end component;

    component sevenseg_decoder
        port (
            i_Hex   : in std_logic_vector(3 downto 0);
            o_seg_n : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Internal Signals
    signal clk_div_out    : std_logic := '0';
    signal reg_A, reg_B   : std_logic_vector(7 downto 0) := (others => '0');
    signal alu_result     : std_logic_vector(7 downto 0) := (others => '0');
    signal alu_flags      : std_logic_vector(3 downto 0) := (others => '0');

    signal disp_bin       : std_logic_vector(7 downto 0) := (others => '0');
    signal disp_sign      : std_logic;
    signal disp_hund      : std_logic_vector(3 downto 0);
    signal disp_tens      : std_logic_vector(3 downto 0);
    signal disp_ones      : std_logic_vector(3 downto 0);
    signal disp_hex       : std_logic_vector(3 downto 0);
    signal disp_seg       : std_logic_vector(6 downto 0);
    signal disp_sel       : std_logic_vector(3 downto 0);

    signal fsm_state      : std_logic_vector(3 downto 0) := (others => '0');
    signal fsm_adv        : std_logic := '0';
    signal sync_reset     : std_logic := '0';

    signal btnC_prev      : std_logic := '0';

begin

    -----------------------------

    u_controller_fsm: controller_fsm
        port map (
            i_clk    => clk_div_out,
            i_reset  => sync_reset,
            i_adv    => fsm_adv,
            o_cycle  => fsm_state
        );

    u_ALU: ALU
        port map (
            i_A      => reg_A,
            i_B      => reg_B,
            i_op     => sw(2 downto 0),
            o_result => alu_result,
            o_flags  => alu_flags
        );

    u_twos_comp: twos_comp
        port map (
            i_bin   => disp_bin,
            o_sign  => disp_sign,
            o_hund  => disp_hund,
            o_tens  => disp_tens,
            o_ones  => disp_ones
        );

    u_TDM4: TDM4
        port map (
            i_clk   => clk_div_out,
            i_reset => sync_reset,
            i_D0    => disp_ones,
            i_D1    => disp_tens,
            i_D2    => disp_hund,
            i_D3    => x"0",
            o_data  => disp_hex,
            o_sel   => disp_sel
        );

    u_clk_div: clock_divider
        generic map (k_DIV => 100000)
        port map (
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => clk_div_out
        );

    u_seg_decoder: sevenseg_decoder
        port map (
            i_Hex   => disp_hex,
            o_seg_n => disp_seg
        );

    -----------------------------

    disp_bin <= reg_A      when fsm_state = "0001" else
                 reg_B     when fsm_state = "0010" else
                 alu_result when fsm_state = "0100" else
                 (others => '0');

    seg <= disp_seg when (disp_sel = "1110" or disp_sel = "1101" or disp_sel = "1011") else
           "1111111" when disp_sign = '0' else
           "0111111";  -- minus sign

    an <= "1111" when fsm_state(3) = '1' else disp_sel;

    -----------------------------
    led(3 downto 0)    <= fsm_state;
    led(15 downto 12)  <= alu_flags;
    led(11 downto 4)   <= (others => '0');

    -- Reset logic
    sync_reset <= btnU;

    -----------------------------
    process(clk_div_out)
    begin
        if rising_edge(clk_div_out) then
            if btnC = '1' and btnC_prev = '0' then
                fsm_adv <= '1';
            else
                fsm_adv <= '0';
            end if;
            btnC_prev <= btnC;
        end if;
    end process;

    -- REGISTER A LOAD
    process(clk_div_out)
    begin
        if rising_edge(clk_div_out) then
            if sync_reset = '1' then
                reg_A <= (others => '0');
            elsif fsm_state(0) = '1' then
                reg_A <= sw(7 downto 0);
            end if;
        end if;
    end process;

    -- REGISTER B LOAD
    process(clk_div_out)
    begin
        if rising_edge(clk_div_out) then
            if sync_reset = '1' then
                reg_B <= (others => '0');
            elsif fsm_state(1) = '1' then
                reg_B <= sw(7 downto 0);
            end if;
        end if;
    end process;

end top_basys3_arch;