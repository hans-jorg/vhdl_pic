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
begin

    iaddr <= std_logic_vector(pc);


    process(clk,rst)
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
                case ir(13 downto 12) is
                when "00" => -- Instruções com registradores
                    case ir(11 downto 8) is
                    when "0111" => -- ADDWF REG,W : W <- F(REG) + W
                        w <= w + f(to_integer(unsigned(ir(6 downto 0))));
                    when "0010" => -- SUBWF REG,W : W <- F(REG) - W
                        w <= f(to_integer(unsigned(ir(6 downto 0)))) - w;
                    when "0101" => -- ANDWF REG,W : W <- F(REG) AND W
                        w <= w and f(to_integer(unsigned(ir(6 downto 0))));
                    when "1000" => -- MOVF  REG   : W <- F(REG)
                        w <= f(to_integer(unsigned(ir(6 downto 0))));
                    when others =>
                        null;
                    end case;
                    estado <= BUSCAR;
                when "01" => -- Instruções para manipulação de bits
                    -- ignorar instrução
                    estado <= BUSCAR;
                when "10" => -- Instruções com valores
                    -- ignorar instrução
                    estado <= BUSCAR;
                when "11" => -- Instrução de salto
                    if ir(11) = '1' then
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
