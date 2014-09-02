;((-1000+63536-(-5000)-58536)&0x10|1)^0xFE=239
;((((-1 << 16) >>a 2)<< 1) >> 5)=00000111111111111000000000000000=4095
;239==239; !(239!=239), 239 > 7; 239 <= 254; !(-32768 >= 239); !(239 < -7)
;unsigned(-32768)==4294934528==x; x != -17; !(x==-17); x > unsigned16(-1); !(x<5); (x>=17); !(x<=-7);
addi R1, R0, 64536 ; -1000/64536
addui R2, R1, 63536 ; -2000/63536
subi R3, R2, 59536 ; -5000/59536
subui R4, R3, 58536 ; -6000/58536
andi R5, R4, 16 ; 
ori R6, R5, 1 ;
xori  R7, R6, 254 ;
;Shift immediate - row 2
lhi R8, -1 ;
srai R9, R8, 2 ;
slli R10, R9, 1 ;
srli R11, R10, 5 ;
;Shift register - row 2
addi R12, R0, 2 ;
addi R13, R0, 1 ;
addi R15, R0, 5 ;
lhi R16, -1;
sra R17, R16, R12 ;
nop ;
sll R18, R17, R13 ;
srl R19, R18, R15 ;
;Signed comparisons - row 3
seqi R20, R7, 239 ;
snei R20, R7, 239 ;
sgti R20, R7, 7 ;
slti R20, R7, -7 ;
slei R20, R7, 254 ;
sgei R20, R18, 239 ;
;Unsigned comparisons - row 4
sgtui R20, R18, -1 ;
sltui R20, R18, 5 ;
sgeui R20, R18, 17 ;
sleui R20, R18, -7 ;

