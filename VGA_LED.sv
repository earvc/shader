/*
 * Avalon memory-mapped peripheral for the VGA LED Emulator
 *
 * Stephen A. Edwards
 * Columbia University
 */
 
  /*
 
 Earvin Caceres
 ec2946
 
 Garvit Signh
 gs2731
 
 */

module VGA_LED(input logic      clk,
	       input logic 	  		  reset,
	       input logic [15:0]    writedata,
	       input logic 	  		  write,
	       input logic		     chipselect,
	       input logic [7:0]  	  address,  // two bits needed for x,y coordinates

	       output logic [7:0] VGA_R, VGA_G, VGA_B,
	       output logic 	  VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	       output logic 	  VGA_SYNC_n);

 
 typedef enum logic [11:0] {S0, S1} state_t;
 state_t state;
 
logic			 	start, done;
logic [15:0]   v1x, v1y, v1z;
logic [15:0]   v2x, v2y, v2z;
logic [15:0]   v3x, v3y, v3z;
logic [15:0]   pixel_color;

shader shader_inst(.*);




   always_ff @(posedge clk)
	  if (reset) begin
			v1x <= 16'h0;
			v1y <= 16'h0;
			
			v2x <= 16'h0;
			v2y <= 16'h0;
			
			v3x <= 16'h0;
			v3y <= 16'h0;
			
			state <= S0;
			start <= 1;
		end
     else if (chipselect && write) begin
       case (address)
//			8'd0 : v1x <= 16'h904;
//			8'd1 : v1y <= 16'h904;
//			8'd2 : v2x <= 16'h19ce;
//			8'd3 : v2y <= 16'hf9c;
//			8'd4 : v3x <= 16'h6e9;
//			8'd5 : v3y <= 16'h238f;
			
			
			8'd0 : v1x <= writedata;
			8'd1 : v1y <= writedata;
			8'd2 : v2x <= writedata;
			8'd3 : v2y <= writedata;
			8'd4 : v3x <= writedata;
			8'd5 : v3y <= writedata;
			8'd6 : begin 
					pixel_color <= writedata;
					state <= S0;
					start<= 1;
			
			
//			8'd0 : v1x <= writedata;
//			8'd1 : v1y <= writedata;
//			8'd2 : v2x <= writedata;
//			8'd3 : v2y <= writedata;
//			8'd4 : v3x <= writedata;
//			8'd5 : begin 
//					v3y <= writedata;
//					state <= S0;
//					start<= 1;
			end
       endcase
	 end
	
	  else begin
			 case (state)
				S0: begin
					if (start) begin
						if (done) begin
							state <= S1;
						end
					end
				end
				
				S1: begin
					start <= 0;
					state <= S0; 
				end
			endcase
	  end
endmodule

