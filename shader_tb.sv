/* shader testbench */

module shader_tb;
	
	// input signals
	logic				clk;
	logic			 	start;
	logic				reset;
	logic [15:0]   p1x, p1y;
	logic [15:0]   p2x, p2y;
	logic [15:0]   p3x, p3y;
	
	// output signals
	logic done;
	logic [7:0] VGA_R, VGA_G, VGA_B;
	logic 	   VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n;
	
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
		reset = 0;
		start = 0;
		
		repeat (2);
			@(posedge clk);
			
		reset = 1;
		
		repeat(2);
			@(posedge clk);
			
		reset = 0;
		
		repeat (2);
			@(posedge clk);
		
		start = 1;
		
		repeat (2);
			@(posedge clk);
		
		start = 0;
	end
	
	// input signals
	initial begin
//		// face 25
//		p1x = 16'h30A9;
//		p1y = 16'h1Ab2;
//		p2x = 16'h315f;
//		p2y = 16'h1b57;
//		p3x = 16'h27fc;
//		p3y = 16'h1b5f;
		
		// face 45
		p1x = 16'h37cc;
		p1y = 16'h1b52;
		p2x = 16'h37c8;
		p2y = 16'h1c81;
		p3x = 16'h3b58;
		p3y = 16'h1df0;
	end
	
endmodule
