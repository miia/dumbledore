;Collatz conjecture:
;Take any natural number n.
;If n is even, divide it by 2 to get n / 2.
;If n is odd, multiply it by 3 and add 1 to obtain 3n + 1.
;Repeat the process indefinitely: you should always end up with 1, independently from the initial value of n.

;Sample run using n=6:
;Start with 6
;6 is Even => divide by 2, obtain 3
;3 is Odd => 3*n+1 = 10
;Even => 5
;Odd => 16
;Even => 8
;Even => 4
;Even => 2
;Even => 1
;Stop

addi r1, r0, 49  ;initial value for n

add r30, r1, r0 ;output current value of n
j check_exit_condition ;check for corner case: we might start with n already ==1

top:

;is n even or odd?
andi r2, r1, 1 ;r2 contains only LSB of n
bnez r2, n_is_odd ;LSB(n)==1 means that n is currently odd

n_is_even:
srli r1, r1, 1 ; divide n by 2, and get n/2. NOTE: this is only executed is n is even => shifting left is enough to divide by 2, because result will always be integer anyway.
j check_exit_condition

;else, n is odd: get 3*n+1
n_is_odd:
;compute 3*n+1 as "n<<2 + n +1"
add r4, r1, r0  ;save value of n in r4
slli r1, r1, 1      ; n*3 can be computed by just shifting it left and adding n one more time
add r1, r1, r4
addi r1, r1, 1

check_exit_condition:
subi r3, r1, 1 ;put in r3 the difference between n and 1 (will be 0 if n==1)
add r30, r1, r0 ;output current value of n
beqz r3, end    ;if n is currently 1, time to stop
j top   ;else, go back to top for one more iteration

end:
j end
