;Initialization
addi R1, R0, 38; -- X
slli R1, R1, 16; -- X << 16 (fixed point)
srli R2, R1, 8; -- N
xor R3, R3, R3; -- OLDN
addi R16, R1, 0  ;--Prepare parameters
j check_n ;First checks the condition
while:
; -- Compute mean value: R15=central
add R15, R2, R3;
srli R15, R15, 1;
jal error; -- Compute error in R17
beqz R17, go_out;
slti R10, R17, 0 ; --If error < 0, then..
beqz R10, err_greater_zero;
addi R2, R15, 0;
j check_n;
err_greater_zero:; -- if(error>0){
addi R3, R15, 0;
;}
check_n: ; (while (n-oldn) >1);
sub R10, R2, R3;
sgtui R10, R10, 1;
bnez R10, while;
go_out:
addi R30, R15, 0 ;--Saves result
stall:
j stall;
;
;This procedure accepts central and x in R15 and R16, and returns error in R17.
error:
  ;Saves R20 in memory (push equivalent?)
  sw 0(r0), R20;

  ;Saves R31 to return, and calls square
  sw 4(r0), R31;
  jal square;
  lw R31, 4(r0);

  sub R17, R16, R20;
  lw R20, 0(r0);
  jr R31; RET equivalent

;This procedure computes the square of R15 into R20
square:
  ;R1=counter (0-31)
  ;R2=mask (0111..111);
  ;Backup R1, R17 and R16
  sw 8(r0), R1;
  sw 12(r0), R16;
  sw 16(r0), R17;
  sw 20(r0), R2;
  ;-- It seems that this assembler only supports decimal numbers -.-"
  lhi R2, 32768 ;
  addi R1, R0, 32;
  add R16, R15, R0;
  xor R20, R20, R20;

sq_for:
  subi R1, R1, 1;
  slli R20, R20, 1;
  ;Takes the MSB of R16 into R17 
  and R17, R16, R2;
  srai R17, R17, 31 ; -- So we obtain a mask of 111..11 or 000..00
  and R17, R17, R15 ; -- Decide wether to add 0 or A
  add R20, R20, R17 ;
  slli R16, R16, 1;


  bnez R1, sq_for;

  ;Restore values
  lw R1, 8(r0);
  lw R16, 12(r0);
  lw R17, 16(r0);
  lw R2, 20(r0);
  jr R31; --Return.

