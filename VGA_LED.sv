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
logic [15:0]   v1x, v1y;
logic [15:0]   v2x, v2y;
logic [15:0]   v3x, v3y;

shader shader_inst(.*);




   always_ff @(posedge clk)
	  if (reset) begin
//			p1x <= 16'h904;
//			p1y <= 16'hb77;
//			
//			p2x <= 16'h19ce;
//			p2y <= 16'hf9c;
//			
//			p3x <= 16'h6e9;
//			p3y <= 16'h238f;
			
			state <= S0;
			start <= 1;
		end
     else if (chipselect && write)
       case (address)
			8'd0 : v1x <= writedata;
			8'd1 : v1y <= writedata;
			8'd2 : v2x <= writedata;
			8'd3 : v2y <= writedata;
			8'd4 : v3x <= writedata;
			8'd5 : v3y <= writedata;
       endcase
	
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

