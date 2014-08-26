;This file does the following:
;r4=0;
;r1=1000;
;while(r1!=0){
;  r30=1000-r1;
;  r1--;
;}
;r4++;
; 
add r4,r0,r0
;r1=1000;
addi r1, r0, 1000;
; while first checks the condition
j while
start_while:
; r30=1000-r1
sub r30,r2,r1;
;r1--
subi r1,r1,1
while:
bnez r1,start_while;
addi r4, r4, 1;
nop
