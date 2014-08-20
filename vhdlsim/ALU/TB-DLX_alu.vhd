LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use work.myTypes.ALL;
use work.txt_util.ALL;

ENTITY TB_DLX_ALU is
END TB_DLX_ALU;

ARCHITECTURE boh OF TB_DLX_ALU IS
  signal A: REGISTER_CONTENT := "10101010101010101010101010101010";
  signal B: REGISTER_CONTENT := (OTHERS => '1');
  signal Y, Y2: REGISTER_CONTENT;
  signal yu, au, bu: unsigned(REGISTER_SIZE-1 downto 0);
  signal ys, as, bs: signed(REGISTER_SIZE-1 downto 0);
  signal y2s: signed(REGISTER_SIZE*2-1 downto 0);
  signal y2u: unsigned(REGISTER_SIZE*2-1 downto 0);

  signal Cout: std_logic_vector(1 downto 0);
  signal OP: ALUOP := "000000000";
 
  function msgS(A: std_logic_vector;  B:std_logic_vector;  Y : std_logic_vector; op: string) return string is
  begin
    return integer'image(to_integer(signed(A)) ) & op & integer'image(to_integer(signed(B))) & " = " & integer'image(to_integer(signed(Y)));
  end function;
  function msgU(A: std_logic_vector;  B:std_logic_vector;  Y : std_logic_vector; op: string) return string is
  begin
    return integer'image(to_integer(unsigned(A)) ) & op & integer'image(to_integer(unsigned(B))) & " = " & integer'image(to_integer(unsigned(Y)));
  end function;
  function msgV(A: std_logic_vector;  B:std_logic_vector;  Y : std_logic_vector; op: string) return string is
  begin
    return str(A) & op & str(B) & " = " & str(Y);
  end function;
begin
  change_op: process
    variable ru: unsigned(REGISTER_SIZE-1 downto 0);
    variable rul: unsigned(REGISTER_SIZE*2-1 downto 0);
    variable rs: signed(REGISTER_SIZE-1 downto 0);
    variable rsl: signed(2*REGISTER_SIZE-1 downto 0);
    variable temp: std_logic;
    variable rand_temp: REGISTER_CONTENT;
  begin
    --Generate new values for the operands
    B <= A;
    rand_temp := A;
    temp := rand_temp(REGISTER_SIZE-1) xor rand_temp(REGISTER_SIZE-2);
    rand_temp(REGISTER_SIZE-1 downto 1) := rand_temp(REGISTER_SIZE-2 downto 0);
    rand_temp(0) := temp;
    A <= rand_temp;
 
    OP(4 downto 3) <= "00"; -- Arithmetic unit
    
    --ADD/ADDU
    OP(2 downto 0) <= "000";
    wait for 10 ns;
    Ru := Au+Bu;
    ASSERT(Yu=Ru);
    
    --SUB/SUBU
    OP(2 downto 0) <= "001";
    wait for 10 ns;
    Rs:=As-Bs;
    ASSERT(signed(Y)=Rs) REPORT msgS(A, B, Y, "-") SEVERITY FAILURE;

    --MUL
    OP(2 downto 0) <= "010";
    wait for 10 ns;
    Rsl:=(As*Bs);
    ASSERT (Y2s)= Rsl REPORT msgS(A,B,Y2 & Y,"*") SEVERITY FAILURE;
    
    --MUL(to be changed to IMUL)
    OP(2 downto 0) <= "011";
    wait for 10 ns;
    Rsl:=(As*Bs);
    ASSERT (Y2s)= Rsl REPORT msgS(A,B,Y2 & Y,"*") SEVERITY FAILURE;

   OP(4 downto 3) <= "01"; -- Logic unit
   --OR
   OP(2 downto 0) <= "000";
   wait for 10 ns;
   ASSERT(Y=(A or B)) REPORT msgV(A,B, Y, "|") SEVERITY FAILURE;
    
   --and
   OP(2 downto 0) <= "001";
   wait for 10 ns;
   ASSERT(Y=(A and B)) REPORT msgV(A,B,Y,"&") SEVERITY FAILURE;
     
   --xOR
   OP(2 downto 0) <= "010";
   wait for 10 ns;
   ASSERT(Y=(A xor B)) REPORT msgV(A,B,Y,"^") SEVERITY FAILURE;

       
   --NOT
   OP(2 downto 0) <= "011";
   wait for 10 ns;
   ASSERT(Y=not A) REPORT msgV(A,B,Y,"!") SEVERITY FAILURE;

   OP(4 downto 3) <= "10";

   --Logic shift left
   OP(2 downto 0) <= "111";
   wait for 10 ns;
   ASSERT(Ys=(As sll to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "sll") SEVERITY FAILURE;

   --Logic shift right
   OP(2 downto 0) <= "110";
   wait for 10 ns;
   ASSERT(Ys=(As srl to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "srl") SEVERITY FAILURE;
   
   --Logic rotate left
   OP(2 downto 0) <= "101";
   wait for 10 ns;
   ASSERT(Ys=(As rol to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "rol") SEVERITY FAILURE;
   
   --Logic rotate right
   OP(2 downto 0) <= "100";
   wait for 10 ns;
   ASSERT(Ys=(As ror to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "ror") SEVERITY FAILURE;
      
   --Arith shift left
   OP(2 downto 0) <= "011";
   wait for 10 ns;
   --ASSERT(Ys=(As sla to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "sla") SEVERITY FAILURE;

   --Arith shift right
   OP(2 downto 0) <= "010";
   wait for 10 ns;
   --ASSERT(Ys=(As sra to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "sra") SEVERITY FAILURE;
   
   --Arith rotate left
   OP(2 downto 0) <= "001";
   wait for 10 ns;
   ASSERT(Ys=(As rol to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "rol") SEVERITY FAILURE;
   
   --Arith rotate right
   OP(2 downto 0) <= "000";
   wait for 10 ns;
   ASSERT(Ys=(As ror to_integer(unsigned(B(4 downto 0))))) REPORT msgV(A, B, Y, "ror") SEVERITY FAILURE;
  end process;
  
  testcomp: ENTITY work.DLX_ALU
  PORT MAP(OP => OP, A => A, B => B, Y => Y, Y_extended => Y2 );

   Yu(REGISTER_SIZE-1 downto 0) <= unsigned(Y(REGISTER_SIZE-1 downto 0));
   Ys(REGISTER_SIZE-1 downto 0) <= signed(Y(REGISTER_SIZE-1 downto 0));
   Y2s <= signed(Y2 & Y);
   Y2u <= unsigned(Y2 & Y);

   Au(REGISTER_SIZE-1 downto 0) <= unsigned(A(REGISTER_SIZE-1 downto 0));
   As(REGISTER_SIZE-1 downto 0) <= signed(A(REGISTER_SIZE-1 downto 0));
   
   Bu(REGISTER_SIZE-1 downto 0) <= unsigned(B(REGISTER_SIZE-1 downto 0));
   Bs(REGISTER_SIZE-1 downto 0) <= signed(B(REGISTER_SIZE-1 downto 0));
END ARCHITECTURE;
