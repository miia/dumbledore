;Initialization
addi R1, R0, 1000; -- X
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
bnez R10, err_greater_zero;
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
addi R30, R3, 0 ;--Saves result
stall:
j stall;
;
;This procedure accepts central and x in R15 and R16, and returns error in R17.
error:
;Saves R14 in memory (push equivalent?)
  sw 0(r0), R15;
  mult R15, R15, R15;
  sub R17, R16, R15;
  lw R15, 0(r0);
  jr R31; RET equivalent
