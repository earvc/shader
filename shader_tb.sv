/* shader testbench */

module shader_tb;
	
	// input signals
	logic				clk;
	logic			 	start;
	logic				reset;
	logic [15:0]   v1x, v1y;
	logic [15:0]   v2x, v2y;
	logic [15:0]   v3x, v3y;
	
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
		// face 25
		v1x = 16'h30A9;
		v1y = 16'h1Ab2;
		v2x = 16'h315f;
		v2y = 16'h1b57;
		v3x = 16'h27fc;
		v3y = 16'h1b5f;
		
		// random face
//		v1x = 16'd100;
//		v1y = 16'd300;
//		v2x = 16'd100;
//		v2y = 16'd200;
//		v3x = 16'd100;
//		v3y = 16'd100;
	end
	
endmodule
