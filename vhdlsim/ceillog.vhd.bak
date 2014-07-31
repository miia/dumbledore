library IEEE;
use IEEE.std_logic_1164.all;

package ceillog is
    function ceil_log2 (i : natural) return integer;
end ceillog;


package body ceillog is

--NOT synthesizable, but we won't need to synthesize it...
--A function returning the minimum number of bits needed to represent the given argument.
function ceil_log2( i : natural) return integer is
    variable temp    : integer := i;
    variable ret_val : integer := 1; --log2 of 0 should equal 1 because you still need 1 bit to represent 0
    begin                 
        while temp > 1 loop
            ret_val := ret_val + 1;
            temp    := temp / 2;     
        end loop;
        if (2**(ret_val-1)=i) then
            ret_val := ret_val -1;
        end if; 
        ASSERT FALSE REPORT "Log" & integer'image(i) & "=" & integer'image(ret_val) SEVERITY WARNING;
   return ret_val;
end function;

end ceillog;  --end of the package body 
