; Computes the square of 10 (100)
addi R15, R0, 10;
jal square;
addi R30, R20, 0;
end:
j end;

;This procedure computes the square of R15 into R20
square:
  ;R1=counter (0-31)
  ;R2=mask (0111..111);
  ;Backup R1, R17 and R16
  sw 8(r0), R1;
  sw 12(r0), R16;
  sw 16(r0), R17;
  sw 20(r0), R2;

  lhi R2, 32768 ;
  addi R1, R0, 32;
  add R16, R15, R0;
  xor R20, R20, R20;

sq_for:
  subi R1, R1, 1;
  ;Takes the MSB of R16 into R17 -- It seems that this assembler only supports decimal numbers -.-"
  and R17, R16, R2;
  srai R17, R17, 31 ; -- So we obtain a mask of 111..11 or 000..00
  and R17, R17, R15 ; -- Decide wether to add 0 or A
  add R20, R20, R17 ;
  slli R20, R20, 1;
  slli R16, R16, 1;


  bnez R1, sq_for;

  ;Restore values
  lw R1, 8(r0);
  lw R16, 12(r0);
  lw R17, 16(r0);
  lw R2, 20(r0);
  jr R31; --Return.

