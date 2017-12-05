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
        iaddr:      out   std_logic_vector(11 downto 0);
        inst:       in    std_logic_vector(13 downto 0);
        intr:       in    std_logic
    );
end entity minipic;

architecture a of minipic is
type tipoestado is (BUSCAR,EXECUTAR);
signal estado: tipoestado;
type banco is array(0 to 511) of unsigned(7 downto 0);
signal f:  banco;
signal w:  unsigned(7 downto 0);
signal ir: std_logic_vector(13 downto 0);
signal pc: unsigned(10 downto 0);
--
type tipopilha is array(0 to 7) of unsigned(10 downto 0);
signal pilha: tipopilha;
signal sp: integer range 0 to 7;
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
constant OP_MOVWF:      std_logic_vector(3 downto 0) := "0000";
constant OP_JUMP:       std_logic := '1';
constant OP_BCF:        std_logic_vector(1 downto 0) := "00";
constant OP_BSF:        std_logic_vector(1 downto 0) := "01";
constant OP_BTFSC:      std_logic_vector(1 downto 0) := "10";
constant OP_BTFSS:      std_logic_vector(1 downto 0) := "11";
constant OP_ADDLW:      std_logic_vector(3 downto 0) := "1111";
constant OP_SUBLW:      std_logic_vector(3 downto 0) := "1100";
constant OP_MOVLW:      std_logic_vector(3 downto 0) := "0000";
constant OP_ANDLW:      std_logic_vector(3 downto 0) := "1001";
constant OP_IORLW:      std_logic_vector(3 downto 0) := "1000";
constant OP_XORLW:      std_logic_vector(3 downto 0) := "1010";
constant OP_RETURN:     std_logic_vector(3 downto 0) := "1000";
constant OP_RETLW:      std_logic_vector(3 downto 0) := "0100";
-- campos de ir
alias IR_OPTYPE:        std_logic_vector(1 downto 0) is ir(13 downto 12);
alias IR_REG:           std_logic_vector(6 downto 0) is ir(6 downto 0);
alias IR_OPREG:         std_logic_vector(3 downto 0) is ir(11 downto 8);
alias IR_OPLIT:         std_logic_vector(3 downto 0) is ir(11 downto 8);
alias IR_OPJUMP:        std_logic is ir(11);
alias IR_OPBIT:         std_logic_vector(1 downto 0) is ir(11 downto 10);
alias IR_BITN:          std_logic_vector(2 downto 0) is ir(9 downto 7);
alias IR_DIR:           std_logic is ir(7);
alias IR_VAL:           std_logic_vector(7 downto 0) is ir(7 downto 0);
alias IR_SUBOP:         std_logic_vector(3 downto 0) is ir(3 downto 0);
alias IR_ADDR:          std_logic_vector(10 downto 0) is ir(10 downto 0);
-- campos do sr
alias sr:               unsigned(7 downto 0) is f(3);
alias irp:              std_logic is sr(7);
alias rp:               unsigned(1 downto 0) is sr(6 downto 5);
alias flag_c:           std_logic is sr(0);
alias flag_z:           std_logic is sr(2);
alias intcon:           unsigned(7 downto 0) is f(11);
alias gie:              std_logic is intcon(7);
begin

    iaddr <= std_logic_vector(irp&pc);


    process(clk,rst)
    variable opnd: unsigned(8 downto 0);
    variable rega: integer range 0 to 511;
    variable result: unsigned(8 downto 0);
    variable atualizaw,atualizaf: boolean;
    variable bitn: integer range 0 to 7;
    variable skip: boolean;
    variable incpc: boolean;
    begin
        if rst = '1' then
            estado <= BUSCAR;
            pc <= (others=>'0');
            sp <= 0;
            gie <= '0';
            sr <= "00000000";
        elsif rising_edge(clk) then
            case estado is
            when BUSCAR =>
                if gie = '1' and intr = '1' then
                    gie <= '0';
                    pilha(sp) <= pc;
                    sp <= sp + 1;
                    pc <= to_unsigned(4,pc'length);
                else
                    ir <= inst;
                    pc <= pc + 1;
                    estado <= EXECUTAR;
                end if;
            when EXECUTAR =>
                case IR_OPTYPE is
                when OP_REG_TYPE => -- Instruções com registradores
                    rega := to_integer(unsigned(std_logic_vector(rp)&ir_reg));
                    opnd := '0'&f(rega);
                    result := '0'&f(rega);
                    incpc := True;
                    if ir_dir = '0' then
                        atualizaw := True;
                        atualizaf := False;
                    else
                        atualizaw := False;
                        atualizaf := True;
                    end if;
                    case IR_OPREG is
                    when OP_ADDWF => -- ADDWF REG,W : W <- F(REG) + W
                        result := w + opnd;
                        flag_c <= result(8);
                    when OP_SUBWF => -- SUBWF REG,W : W <- F(REG) - W
                        result := opnd - w;
                        flag_c <= result(8);
                    when OP_ANDWF => -- ANDWF REG,W : W <- F(REG) AND W
                        result := w and opnd;
                    when OP_MOVF =>  -- MOVF  REG   : W <- F(REG)
                        result := opnd;
                        atualizaw := True;
                        atualizaf := False;
                    when OP_MOVWF => -- MOVWF REG   : F(REG) <= W
                        if ir_dir = '1' then
                            result := opnd;
                            atualizaw := False;
                            atualizaf := True;
                        else
                            atualizaw := False;
                            atualizaf := False;
                            case ir_subop is
                            when OP_RETURN =>
                                pc <= pilha(sp-1);
                                sp <= sp - 1;
                                incpc := False;
                            when others =>
                                null;
                            end case;
                        end if;
                    when others =>
                        null;
                    end case;
                    if atualizaw then
                        w <= result(7 downto 0);
                    end if;
                    if atualizaf then
                        f(rega) <= result(7 downto 0);
                    end if;
                    if atualizaw or atualizaf then
                        if result(7 downto 0) = "00000000" then
                            flag_z <= '1';
                        end if;
                    end if;
                    if incpc then
                        if gie = '1' and intr = '1' then
                            gie <= '0';
                            pilha(sp) <= pc;
                            sp <= sp + 1;
                            pc <= to_unsigned(4,pc'length);
                            estado <= BUSCAR;
                        else
                            ir <= inst;
                            pc <= pc + 1;
                        end if;
                    else
                        estado <= BUSCAR;
                    end if;
                when OP_LIT_TYPE => -- Instruções com valores
                    opnd := unsigned('0'&ir_val);
                    incpc := True;
                    case IR_OPLIT is
                    when OP_ADDLW =>
                        result := unsigned('0'&w) + opnd;
                        flag_c <= result(8);
                    when OP_SUBLW =>
                        result := unsigned('0'&w) - opnd;
                        flag_c <= result(8);
                    when OP_MOVLW =>
                        result := opnd;
                    when OP_ANDLW =>
                        result := unsigned('0'&w) and opnd;
                    when OP_IORLW =>
                        result := unsigned('0'&w) or opnd;
                    when OP_XORLW =>
                        result := unsigned('0'&w) xor opnd;
                    when OP_RETLW =>
                        pc <= pilha(sp-1);
                        sp <= sp - 1;
                        incpc := True;
                    when others =>
                        null;
                    end case;
                    w <= result(7 downto 0);
                    if result(7 downto 0) = "00000000" then
                        flag_z <= '1';
                    else
                        flag_z <= '0';
                    end if;
                    if incpc then
                        if gie = '1' and intr = '1' then
                            gie <= '0';
                            pilha(sp) <= pc;
                            sp <= sp + 1;
                            pc <= to_unsigned(4,pc'length);
                            estado <= BUSCAR;
                        else
                            ir <= inst;
                            pc <= pc + 1;
                        end if;
                    else
                        estado <= BUSCAR;
                    end if;
                when OP_BIT_TYPE => -- Instruções para manipulação de bits
                    rega := to_integer(unsigned(std_logic_vector(rp)&ir_reg));
                    bitn := to_integer(unsigned(ir_bitn));
                    skip := False;
                    case IR_OPBIT is
                    when OP_BCF =>
                        f(rega)(bitn) <= '0';
                    when OP_BSF =>
                        f(rega)(bitn) <= '1';
                    when OP_BTFSC =>
                        if f(rega)(bitn) = '0' then
                            skip := True;
                        end if;
                    when OP_BTFSS =>
                        if f(rega)(bitn) = '1' then
                            skip := True;
                        end if;
                    when others =>
                        null;
                    end case;
                    if skip then
                        pc <= pc + 2;
                        estado <= BUSCAR;
                    else
                        if gie = '1' and intr = '1' then
                            gie <= '0';
                            pilha(sp) <= pc;
                            sp <= sp + 1;
                            pc <= to_unsigned(4,pc'length);
                            estado <= BUSCAR;
                        else
                            ir <= inst;
                            pc <= pc + 1;
                         end if;
                    end if;
                when OP_JMP_TYPE => -- Instrução de salto
                    if IR_OPJUMP = OP_JUMP then
                        pc <= unsigned(ir_addr);
                    else
                        pilha(sp) <= pc;
                        sp <= sp + 1;
                        pc <= unsigned(ir_addr);
                    end if;
                    estado <= BUSCAR;
                when others =>
                    null;
                end case;
            end case;
        end if;
    end process;



end architecture a;
