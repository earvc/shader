/* shader testbench */

module shader_tb;
	
	// input signals
	logic				clk;
	logic			 	start;
	logic [15:0]   p1x, p1y;
	logic [15:0]   p2x, p2y;
	logic [15:0]   p3x, p3y;
	
	// output signals
	logic done;
	logic write_pixel;
	
	logic [9:0] x_pixel;
	logic [9:0] y_pixel;
	logic [7:0] R, G, B;

	// shader dut
	shader dut(.*);
	
	// clock generator
	initial begin
		clk = 0;
		forever
			#20ns clk = ~clk;
	end
	
	// start signal high for 2 cycles
	initial begin
		start = 0;
		
		repeat (2);
			@(posedge clk);
			
		start = 1;
		
		repeat(2);
			@(posedge clk);
			
		start = 0;
	end
	
	// input signals
	initial begin
		p1x = 16'h37cc;
		p1y = 16'h1b52;
		p2x = 16'h37c8;
		p2y = 16'h1c81;
		p3x = 16'h3b58;
		p3y = 16'h1df0;
	end
	
endmodule
