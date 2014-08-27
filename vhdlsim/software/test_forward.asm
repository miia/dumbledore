;r1=1000; 
;;r2=2000;
;r5=11;
;r6=5;
;r3=r1+r2;
;r4=r1+r3;
;do{
;  r6--;
;  0[r5]=r6;
;  r30=0[r5];
;  r25=r30+r1+r4;
;  r5-=4;
;} while(r5);

;This will not be forwarded
addi r1, r0, 1000; 0
;This will not be forwarded
addi r2, r0, 2000; 1
;This will not be forwarded
addi r5, r0, 12; 2
addi r6, r0, 5; 3
;Forward from MEM and from ALU
add r3, r1, r2; 4
;Forward from ALU
add r4, r1, r3; 5
;We store 5 at address 3 (a byte), later we'll take the whole word
while:
subi r6, r6, 1; 6
sw 0(r5), r6; 7
lw r30, 0(r5); 8
add r25, r30, r1; 9
add r25, r25, r4; 10
subi r5, r5, 4; 11
bnez r5, while; 12
; This instructions can show the correct flush of the pipeline
addi r30, r0, 1; 13
addi r30, r0, 2; 14
subi r30, r0, 3; 15
subi r30, r0, 4; 16
