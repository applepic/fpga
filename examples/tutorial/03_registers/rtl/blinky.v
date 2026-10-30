module blinky(i_clk, o_led);
	parameter WIDTH = 27;
	input wire i_clk;
	output wire o_led;

	reg [WIDTH-1:0] counter;
	initial counter = 0;
	always @(posedge i_clk)
		counter <= counter + 1'b1;
	assign o_led = counter[WIDTH-1];
endmodule
