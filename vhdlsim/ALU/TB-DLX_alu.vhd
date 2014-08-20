LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use work.myTypes.ALL;

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
begin

  
  change_op: process
    variable ru: unsigned(REGISTER_SIZE-1 downto 0);
    variable rul: unsigned(REGISTER_SIZE*2-1 downto 0);
    variable rs: signed(REGISTER_SIZE-1 downto 0);
    variable rsl: signed(2*REGISTER_SIZE-1 downto 0);
    variable temp: std_logic;
    variable rand_temp: REGISTER_CONTENT;
  begin
      B <= A;
      rand_temp := A;
      temp := rand_temp(REGISTER_SIZE-1) xor rand_temp(REGISTER_SIZE-2);
rand_temp(REGISTER_SIZE-1 downto 1) := rand_temp(REGISTER_SIZE-2 downto 0);
rand_temp(0) := temp;
   A <= rand_temp;
 
    OP <= "000000000";
    --ADD/ADDU
    wait for 10 ns;
    Ru := Au+Bu;
    ASSERT(Yu=Ru);
    
    --SUB/SUBU
    OP <= std_logic_vector(unsigned(OP)+1);
    wait for 10 ns;
    Rs:=As-Bs;
    ASSERT(signed(Y)=Rs) REPORT integer'image(to_integer(signed(A)) ) & "+" & integer'image(to_integer(signed(B))) & " = " & integer'image(to_integer(signed(Y))) SEVERITY FAILURE;

    --MUL
    OP <= std_logic_vector(unsigned(OP)+1);
    wait for 10 ns;
    Rsl:=(As*Bs);
    ASSERT (Y2s)= Rsl REPORT integer'image(to_integer(Au))  & "*" &  integer'image(to_integer(Bu)) &  " = " & integer'image(to_integer(Y2u)) SEVERITY FAILURE;
    
    --MUL(to be changed to IMUL)
    OP <= std_logic_vector(unsigned(OP)+1);
    wait for 10 ns;
    Rsl:=(As*Bs);
    ASSERT (Y2s)= Rsl REPORT integer'image(to_integer(Au))  & "*" &  integer'image(to_integer(Bu)) &  " = " & integer'image(to_integer(Y2u)) SEVERITY FAILURE;

   --OR
   OP <= std_logic_vector(unsigned(OP)+1);
   wait for 10 ns;
   ASSERT(Y=(A or B)) SEVERITY FAILURE;
    
   --and
   OP <= std_logic_vector(unsigned(OP)+1);
   wait for 10 ns;
   ASSERT(Y=(A and B)) SEVERITY FAILURE;
     
   --xOR
   OP <= std_logic_vector(unsigned(OP)+1);
   wait for 10 ns;
   ASSERT(Y=(A xor B)) SEVERITY FAILURE;

       
   --NOT
   OP <= std_logic_vector(unsigned(OP)+1);
   wait for 10 ns;
   ASSERT(Y=not A) SEVERITY FAILURE;
   
   
   
   ---RESTART WITH IMMEDIATE BIT SET TO 1
   
   OP <= "000010000";    
      --ADD/ADDU
      wait for 10 ns;
      Ru := Au+Bu;
      ASSERT(Yu=Ru);
      
      --SUB/SUBU
      OP <= std_logic_vector(unsigned(OP)+1);
      wait for 10 ns;
      Rs:=As-Bs;
      ASSERT(signed(Y)=Rs) REPORT integer'image(to_integer(signed(A)) ) & "+" & integer'image(to_integer(signed(B))) & " = " & integer'image(to_integer(signed(Y))) SEVERITY FAILURE;
  
      --MUL
      OP <= std_logic_vector(unsigned(OP)+1);
      wait for 10 ns;
      Rsl:=(As*Bs);
      ASSERT (Y2s)= Rsl REPORT integer'image(to_integer(Au))  & "*" &  integer'image(to_integer(Bu)) &  " = " & integer'image(to_integer(Y2u)) SEVERITY FAILURE;
      
      --MUL(to be changed to IMUL)
      OP <= std_logic_vector(unsigned(OP)+1);
      wait for 10 ns;
      Rsl:=(As*Bs);
      ASSERT (Y2s)= Rsl REPORT integer'image(to_integer(Au))  & "*" &  integer'image(to_integer(Bu)) &  " = " & integer'image(to_integer(Y2u)) SEVERITY FAILURE;
  
     --OR
     OP <= std_logic_vector(unsigned(OP)+1);
     wait for 10 ns;
     ASSERT(Y=(A or B)) SEVERITY FAILURE;
      
     --and
     OP <= std_logic_vector(unsigned(OP)+1);
     wait for 10 ns;
     ASSERT(Y=(A and B)) SEVERITY FAILURE;
       
     --xOR
     OP <= std_logic_vector(unsigned(OP)+1);
     wait for 10 ns;
     ASSERT(Y=(A xor B)) SEVERITY FAILURE;
  
     --LHI
     OP <= std_logic_vector(unsigned(OP)+1);
     OP(5) <= '1'; --this time we need to pre-select output of LH block (instead of Logic Unit).
     wait for 10 ns;
     ASSERT(Y=(B(15 downto 0) & "0000000000000000")) SEVERITY FAILURE;
      
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
