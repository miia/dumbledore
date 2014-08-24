;This file does the following:
;r4=0;
;r1=10;
;r2=30;
;r4=r1+r2;
;r30=R4+r1;
;r30--;
; 
thastart:
add r4,r0,r0
addi r1, r0, 10;
addi r2, r0, 30;
add r4, r2, r1;
add r30, r4, r1;
subi r30, r30, 1;
j thastart
