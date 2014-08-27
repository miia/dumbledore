;r1=1000; 
;;r2=2000;
;r5=11;
;r6=5;
;r3=r1+r2;
;r4=r1+r3;
;do{
;  0[r5]=r6;
;  r30=0[r5];
;  r25=r30+r1+r4;
;  r5-=4;
;} while(r5);

;This will not be forwarded
addi r1, r0, 1000
;This will not be forwarded
addi r2, r0, 2000
;This will not be forwarded
addi r5, r0, 12;
addi r6, r0, 5;
;Forward from MEM and from ALU
add r3, r1, r2;
;Forward from ALU
add r4, r1, r3;
;We store 5 at address 3 (a byte), later we'll take the whole word
while:
sw 0(r5), r6;
lw r30, 0(r5);
add r25, r30, r1;
add r25, r25, r4;
subi r5, r5, 4;
bnez r5, while;
; This instructions can show the correct flush of the pipeline
addi r30, r0, 1;
addi r30, r0, 2;
addi r30, r0, 3;
addi r30, r0, 4;
