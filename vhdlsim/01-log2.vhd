PACKAGE log2 IS
   function log2_unsigned ( x : natural ) return natural ;
END PACKAGE;
PACKAGE BODY log2 IS

  function log2_unsigned ( x : natural ) return natural IS
           variable temp : real := real(x) *1.0;
           variable n : natural := 0 ;
       begin
           while temp > 1.0 loop
               temp := temp / 2.0 ;
               n := n + 1 ;
           end loop ;
           return n;
   end function log2_unsigned ;
END PACKAGE BODY;
