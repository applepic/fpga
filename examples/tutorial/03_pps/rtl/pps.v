module pps(i_clk, o_led);
	// Two's complement: 2^32 is not representable in 32 bits, so ~0 + 1 == 0 and the counter below
	// counts down to zero once per CLOCK_RATE_HZ clock edges.
	//
	// The literal needs 33 bits: 0x1_0000_0000 is 2^32. Written as a 32-bit constant it is truncated to
	// 0, the subtraction still lands on 2^32 - D, and iverilog warns "Extra digits given for sized hex
	// constant" and "Numeric constant truncated to 32 bits". Measured 2026-10-30.
	parameter CLOCK_RATE_HZ = 27_000_000;
	localparam D = CLOCK_RATE_HZ / 2;
	localparam [32:0] INCREMENT = 33'h1_0000_0000 - D;

	input	wire		i_clk;
	output	wire		o_led;

	reg	[31:0]	counter;
	reg			led_reg;
	wire		interrupt = (counter == 0);

	initial	counter = 0;
	initial	led_reg = 0;

	always @(posedge i_clk)
		counter <= counter + INCREMENT[31:0];

	always @(posedge i_clk)
	if (interrupt)
		led_reg <= !led_reg;

	assign	o_led = led_reg;
endmodule
