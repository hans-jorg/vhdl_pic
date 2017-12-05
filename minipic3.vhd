--
-- implementação de um PIC
--
-- Arquitetura Harvard de 8 bits
--
-- Somente instruções com registradores e a instrução de salto.
--

-- Formato das instruções
-- 00CCCC-RRRRRRR      CCCC: OPCODE, RRRRRRR:  Registrador
-- 111AAAAAAAAAAA      AAAAAAAAAAAA: Endereco
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity minipic is
    port (
        clk:        in    std_logic;
        rst:        in    std_logic;
        iaddr:      out   std_logic_vector(10 downto 0);
        inst:       in    std_logic_vector(13 downto 0)
    );
end entity minipic;

architecture a of minipic is
type tipoestado is (BUSCAR,EXECUTAR);
signal estado: tipoestado;
type banco is array(0 to 127) of unsigned(7 downto 0);
signal f:  banco;
signal w:  unsigned(7 downto 0);
signal ir: std_logic_vector(13 downto 0);
signal pc: unsigned(10 downto 0);
-- tipos de instruções
constant OP_REG_TYPE:   std_logic_vector(1 downto 0) := "00";
constant OP_BIT_TYPE:   std_logic_vector(1 downto 0) := "01";
constant OP_LIT_TYPE:   std_logic_vector(1 downto 0) := "10";
constant OP_JMP_TYPE:   std_logic_vector(1 downto 0) := "11";
-- codigos das instruções
constant OP_ADDWF:      std_logic_vector(3 downto 0) := "0111";
constant OP_SUBWF:      std_logic_vector(3 downto 0) := "0010";
constant OP_ANDWF:      std_logic_vector(3 downto 0) := "0101";
constant OP_MOVF:       std_logic_vector(3 downto 0) := "1000";
constant OP_JUMP:       std_logic := '1';
-- campos de ir
alias IR_OPTYPE:        std_logic_vector(1 downto 0) is ir(13 downto 12);
alias IR_REG:           std_logic_vector(6 downto 0) is ir(6 downto 0);
alias IR_OPREG:         std_logic_vector(3 downto 0) is ir(11 downto 8);
alias IR_OPJUMP:        std_logic is ir(11);
begin

    iaddr <= std_logic_vector(pc);


    process(clk,rst)
    variable opnd: unsigned(7 downto 0);
    begin
        if rst = '1' then
            estado <= BUSCAR;
            pc <= (others=>'0');
        elsif rising_edge(clk) then
            case estado is
            when BUSCAR =>
                ir <= inst;
                pc <= pc + 1;
                estado <= EXECUTAR;
            when EXECUTAR =>
                case IR_OPTYPE is
                when OP_REG_TYPE => -- Instruções com registradores
                    opnd := f(to_integer(unsigned(ir_reg)));
                    case IR_OPREG is
                    when OP_ADDWF => -- ADDWF REG,W : W <- F(REG) + W
                        w <= w + opnd;
                    when OP_SUBWF => -- SUBWF REG,W : W <- F(REG) - W
                        w <= opnd - w;
                    when OP_ANDWF => -- ANDWF REG,W : W <- F(REG) AND W
                        w <= w and opnd;
                    when OP_MOVF =>  -- MOVF  REG   : W <- F(REG)
                        w <= opnd;
                    when others =>
                        null;
                    end case;
                    ir <= inst;
                    pc <= pc + 1;
                when OP_LIT_TYPE => -- Instruções com valores
                    -- ignorar instrução
                    ir <= inst;
                    pc <= pc + 1;
                when OP_BIT_TYPE => -- Instruções para manipulação de bits
                    -- ignorar instrução
                    ir <= inst;
                    pc <= pc + 1;
                when OP_JMP_TYPE => -- Instrução de salto
                    if IR_OPJUMP = OP_JUMP then
                        pc <= unsigned(ir(10 downto 0));
                    else
                        null;
                    end if;
                    estado <= BUSCAR;
                when others =>
                    null;
                end case;
            end case;
        end if;
    end process;



end architecture a;
