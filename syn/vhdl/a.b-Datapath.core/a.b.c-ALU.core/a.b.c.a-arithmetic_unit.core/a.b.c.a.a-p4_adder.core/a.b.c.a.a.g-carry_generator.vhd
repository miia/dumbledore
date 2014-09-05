library ieee;
use ieee.std_logic_1164.all;
use work.ceillog.all;

ENTITY carryGenerator IS
GENERIC(
	SIZE: integer :=32-- Works only if multiple of 4
);
PORT(
	Cin: in std_logic;
	A: in std_logic_vector(SIZE-1 downto 0);
	B: in std_logic_vector(SIZE-1 downto 0);
	OUTPUT: out std_logic_vector(SIZE/4 downto 0) -- last is cout. E.g. size=32 -> OUTPUT(0..7) are middle carry-in, OUTPUT(8) is Cout
);
END carryGenerator;
ARCHITECTURE structural of carryGenerator IS    	
	    function power(i, j: integer) return integer is
	       variable temp: integer := 1;
	       variable expon: integer := j;
       begin
           if(j<0) then
               return 0;
           else
              while expon > 0 loop
                  temp := temp * i;
                  expon := expon -1;
              end loop;
          end if;
          return temp;
       end function;
       function previousDiag(i,j: natural ) return natural is
	       variable temp: natural := 0;
       begin

	       while temp < j loop
		       temp := temp + 2**(i-1); -- move forward 1 block
	       end loop;
	       temp := temp - 2**(i-1) ;-- realign to prev block
          return temp;
       end function previousDiag;	       

	TYPE pgMatrix IS ARRAY(ceil_log2(SIZE) downto 0) of std_logic_vector(SIZE downto 1);
	SIGNAL props: pgMatrix;
	SIGNAL gens: pgMatrix;
BEGIN	
	--First row must be treated differently
	OUTPUT(0)<=Cin;
	first_row: ENTITY work.pg_network 
		GENERIC MAP(SIZE)
		PORT MAP(A => A,
			 B => B,
			 Cin => Cin,
			 Pout => props(0),
			 Gout => gens(0)
		);
	--Second row is special too, must use upper left-right outs
	second_row_zero: ENTITY work.generator
	   PORT MAP(Pik => props(0)(2),
          Gik => gens(0)(2),
          Gk1j => gens(0)(1), -- previous block to be fast-forwarded
          Gout => gens(1)(2)
          );
   second_row_other: FOR i in 4 TO (SIZE) GENERATE -- But other white blocks
      sblargaba: IF(i mod 2 =0) GENERATE
         second_row_others: ENTITY work.pg
            PORT MAP(
                Gik  => gens(0)(i),
                Pik  => props(0)(i),
                Gk1j => gens(0)(i-1),
                Pk1j => props(0)(i-1),
                Gout => gens(1)(i),
                Pout => props(1)(i)
                );
       END GENERATE;
   END GENERATE;
         
      
	layers: FOR i in 2 to (ceil_log2(SIZE)) GENERATE
		single_elements: FOR j IN 1 TO (SIZE) GENERATE
			sbararara: IF (j mod 4=0) GENERATE
				first_block: IF(j/4 <= power(2,i-2)) GENERATE -- First block, first half=empty, 2nd half=generate
					connect_1st: IF(j/4 <= power(2,i-3)) GENERATE -- 1st half 1st block
						--Simply connect wires
						props(i)(j) <= props(i-1)(j);
						gens(i)(j) <= gens(i-1)(j);
					END GENERATE;
					new_cout: IF(not(j/4 <= power(2,(i-3))))-- 1st half 2nd block ----WHY NOT ELSE????? "Goddammit, Harry!" 
						GENERATE -- we must throw out a cout
							aaa: ENTITY work.generator
								PORT MAP(Gik => gens(i-1)(j),
									 Pik => props(i-1)(j),
   									 Gk1j => gens(i-1)(previousDiag(i,j)), -- previous block to be fast-forwarded
			      						 Gout => gens(i)(j)
								);
					END GENERATE;
				END GENERATE;
				other_block: IF(not(j/4 <= (2**(i-2)))) GENERATE
            -- other blocks, must put white blocks instead of grey

				   white_block: IF((((j/4) mod (2**(i-2))) > power(2,(i-3))) or ((j/4) mod (2**(i-2))=0)) GENERATE -- other block, 2nd half
				      new_white_block: ENTITY work.pg
 						PORT MAP(
             					   Gik => gens(i-1)(j),
         						   Pik => props(i-1)(j),
         						   Pk1j => props(i-1)(previousDiag(i,j)),

      							Gk1j => gens(i-1)(previousDiag(i,j)),
      							Pout => props(i)(j),
      							Gout => gens(i)(j)
            				   );
				   END GENERATE;
				   connect_2nd: IF(not((((j/4) mod (2**(i-2))) > power(2,(i-3))) or ((j/4) mod (2**(i-2))=0))) GENERATE -- other block, 1st half 
                 props(i)(j) <= props(i-1)(j);
                 gens(i)(j) <= gens(i-1)(j);
               END GENERATE;
			   END GENERATE;
      		END GENERATE;
      END GENERATE;
   END GENERATE;
  put_carries: FOR i in 1 TO (SIZE/4) GENERATE --Carries go from 0 to SIZE (last is COut)
   --First is CIn (treated previously) 
   --Others are at multiple of 4 (i.e. 1->4, 2->8..)
   --Index start at 0, so i->3, 2->7..
      OUTPUT(i)<=gens(ceil_log2(SIZE))(i*4);
  END GENERATE;
      
END ARCHITECTURE;
