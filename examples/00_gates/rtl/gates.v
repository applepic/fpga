module gates(
    input a,
    input b,
    output y_and,
    output y_or,
    output y_not,
    output y_xor
);
assign y_and = a & b; 
assign y_or = a | b;
assign y_xor = a ^ b;
assign y_not = ~ a;
endmodule
