/* testing arithmetic */

module shader	  (input logic			 	clk,
						input logic 			reset,
						input logic			 	start,
						input logic [15:0]   p1x, p1y,
						input logic [15:0]   p2x, p2y,
						input logic [15:0]   p3x, p3y,
		 
						output logic write_pixel,
						output logic done,
						output logic [15:0] x_pixel,
						output logic [15:0] y_pixel,
						output logic [7:0] R, G, B
						);
						
	/////////////////////////////////
	//
	//  divider signals and modules
	//
	/////////////////////////////////

						
	logic [15:0] dp1p2, dp1p2num, dp1p2den;
	logic [15:0] dp1p3, dp1p3num, dp1p3den;
	
	// divider signals
	logic rst_div;  	// reset signal for divider
	logic start_div;  // start divides
	logic done_div1;  // done dividing
	logic done_div2;
	
	// divider modules i need for this section
	divider inv_slope1 (clk, rst_div, start_div, dp1p2num, dp1p2den, dp1p2, done_div1);
	divider inv_slope2 (clk, rst_div, start_div, dp1p3num, dp1p3den, dp1p3, done_div2);
	
	
	/////////////////////////////////
	//
	//  draw signals and modules
	//
	/////////////////////////////////
	
	
	// draw line signals
	logic rst_draw, start_draw, done_draw;
	logic [15:0] sx1, ex1;
	logic [15:0] pax, pay, pbx, pby, pcx, pcy, pdx, pdy;
	logic [15:0] y_coord;
	logic [15:0] y;
	logic [15:0] start_y, end_y;
	
	// draw line module
	draw_line draw(clk, rst_draw, start_draw, y_coord, 
						pax, pay, pbx, pby, 
						pcx, pcy, pdx, pdy, 
						done_draw, x_pixel, y_pixel);
	
	

	
	/////////////////////////////////
	//
	//  state defs
	//
	/////////////////////////////////
	
	typedef enum logic [7:0] {S0, S1, S2, S3, S4, S5, S6, S7} state_t;
	state_t state;

	
	
	// *
	// *
	///////////////////////////////////////////////////////////
	//
	// Start Shader FSM
	//
	////////////////////////////////////////////////////////////
	// *
	// *
	
	
	always_ff @(posedge clk) begin
		if (reset) begin
			state <= S0;
		end
		
		else begin
			case (state)
				S0: begin  // calculate numerators and denominators for inverse slopes
					if (start) begin
						if (p2y > p1y) begin
							dp1p2num = p2x - p1x;
							dp1p2den = p2y - p1y;
						end
						else begin	 // forces dp1p2 to 0
							dp1p2num = 0;  
							dp1p2den = 1;
						end
						
						if (p3y > p1y) begin
							dp1p3num = p3x - p1x;  
							dp1p3den = p3y - p1y;
						end
						else begin  // forces dp1p3 to 0
							dp1p3num = 0;
							dp1p3den = 1;
						end
						rst_div <= 1;  // get the dividers ready for the next state
						state <= S1;
					end
				end
				
				S1: begin
					rst_div <= 0; // bring reset back to 0
					start_div <= 1; // start the divide process
					
					if (done_div1 & done_div2) begin  // wait until the divides are done
						state <= S2; 
						start_div <= 0;
					end
					state <= S2;
				end
				
				
				S2: begin
					// at this point inverse slopes dp1p2 and dp1p3 are ready
					start_y = p1y >> 5;
					end_y = (p3y >> 5) + 1;
					y_coord = start_y;
					
					state <= S3;
				end  // end state S2				
				
				
				S3: begin
					if ( (dp1p2num * dp1p3den) > (dp1p3num * dp1p2den) ) begin
						if ( (y_coord << 5) < p2y) begin
							pax = p1x;
							pay = p1y;
							pbx = p3x;
							pby = p3y;
							pcx = p1x;
							pcy = p1y;
							pdx = p2x;
							pdy = p2y;
						end
						
						else begin
							pax = p1x;
							pay = p1y;
							pbx = p3x;
							pby = p3y;
							pcx = p2x;
							pcy = p2y;
							pdx = p3x;
							pdy = p3y;
						end
					end
					
					else begin
						if ( (y_coord << 5) < p2y) begin
							pax = p1x;
							pay = p1y;
							pbx = p2x;
							pby = p2y;
							pcx = p1x;
							pcy = p1y;
							pdx = p3x;
							pdy = p3y;
						end
						
						else begin
							pax = p2x;
							pay = p2y;
							pbx = p3x;
							pby = p3y;
							pcx = p1x;
							pcy = p1y;
							pdx = p3x;
							pdy = p3y;
						end
					end
				
					rst_draw <= 1;  // get the draw module ready to draw
					state <= S4;
				end  // end state S3
				
				
				S4: begin
					rst_draw <= 0;
					start_draw <= 1;
					
					if (done_draw) begin  		// wait until the draw is done before we change states
						y_coord = y_coord + 1;  // increment the y coordinate for next line to draw
						y = y + 1;
						
						if (y_coord < end_y) begin
							state <= S3;  			// jump back to S3 to draw the next line for new y_coord
						end
						else begin
							state <= S0;  		 // go back to reset state
						end
						
						start_draw <= 0;  // make sure to set start_draw=0 when we're done
					end
				end  // end state S4
				
				S5: begin
					state <= S5;
				end
				
				S6: begin
					state <= S6;
				end
				
				S7: begin
					state <= S0;
				end
			endcase
		end
	end
endmodule
