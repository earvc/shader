/* testing arithmetic */

module shader	  (
						input logic			 	clk,
						input logic 			reset,
						input logic			 	start,
					
						input logic [15:0]   v1x, v1y, v1z,
						input logic [15:0]   v2x, v2y, v2z, 
						input logic [15:0]   v3x, v3y, v3z,
				
						output logic [7:0] VGA_R, VGA_G, VGA_B,
						output logic 	    VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n,
						output logic		 done
						
						);
						
	/////////////////////////////////
	//
	//  for sorting input vertices
	//
	/////////////////////////////////
	

	logic [15:0]   p1x, p1y, p1z;
	logic [15:0]   p2x, p2y, p2z;
	logic [15:0]   p3x, p3y, p3z;
						
	/////////////////////////////////
	//
	//  divider signals and modules
	//
	/////////////////////////////////

						
	logic [15:0] dp1p2, dp1p2num, dp1p2den;
	logic [15:0] dp1p3, dp1p3num, dp1p3den;
	
	// divider signals
	logic start_div;  // start divides
	logic done_div1;  // done dividing
	logic done_div2;
	
	// divider modules i need for this section
	divider inv_slope1 (clk, reset, start_div, dp1p2num, dp1p2den, dp1p2, done_div1);
	divider inv_slope2 (clk, reset, start_div, dp1p3num, dp1p3den, dp1p3, done_div2);
	
	
	/////////////////////////////////
	//
	//  draw signals and modules
	//
	/////////////////////////////////
	
	
	// draw line signals
	logic rst_draw, start_draw, done_draw;
	logic [15:0] sx1, ex1;
	logic [15:0] pax, pay, paz; 
	logic [15:0] pbx, pby, pbz; 
	logic [15:0] pcx, pcy, pcz; 
	logic [15:0] pdx, pdy, pdz;
	logic [15:0] y_coord;
	logic [15:0] start_y, end_y;
	logic [10:0] sx, ex;
	logic draw_line_done;
	
	
	// wires
	logic line_done;
	logic bresenham_start;
	logic bresenham_done;
	logic pixel_write;
	logic pixel_color;
	logic [10:0] pixel_x, pixel_y;
	logic [10:0] z_coord;
	
		draw_line draw( 
								 .clk(clk), .reset(reset), .start(start_draw),
								 .bresenham_done(bresenham_done), .y_coord(y_coord), 
								 .pax(pax), .pay(pay), .paz(paz), .pbx(pbx), .pby(pby), .pbz(pbz),
								 .pcx(pcx), .pcy(pcy), .pcz(pcz), .pdx(pdx), .pdy(pdy), .pdz(pdz),
								 .done(draw_line_done), .draw(bresenham_start), .start_x(sx), .end_x(ex), .z_coord(z_coord)  
							);
	
		
//		bresenham bresenham_inst( 
//										  .clk(clk), .reset(reset), .start(bresenham_start),
//										  .x0(sx), .y0(y_coord), .x1(ex), .y1(y_coord),
//										  .plot(pixel_write), .x(pixel_x), .y(pixel_y), .done(bresenham_done) 
//										);

		put_pixel put_pixel_inst(
										  .clk(clk), .reset(reset), .start(bresenham_start),
										  .x0(sx), .y0(y_coord), .x1(ex), .y1(y_coord), .z_coord(z_coord),
										  .plot(pixel_write), .x(pixel_x), .y(pixel_y), .done(bresenham_done)
										);
	
		VGA_framebuffer screen(
										.clk50(clk), .reset(reset), .x(pixel_x), .y(pixel_y),
										.pixel_color(pixel_color), .pixel_write(pixel_write),
										.VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
										.VGA_CLK(VGA_CLK), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_n(VGA_BLANK_n), .VGA_SYNC_n(VGA_SYNC_n)
									
								  );
	
	
	/////////////////////////////////
	//
	//  state defs
	//
	/////////////////////////////////
	
	typedef enum logic [6:0] {S0, S1, S2, S3, S4, S5, S6} state_t;
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
			done <= 0;
			pixel_color <= 1;
		end
		
		else begin
			case (state)
			
				S0: begin
					done <= 0;
					if (start) begin
						
						// sort incoming vertices
						if ((v1y < v2y) & (v1y < v3y)) begin  // if V1 is the smallest vertex
							p1x = v1x;  // first vertex is V1
							p1y = v1y;
							p1z = v1z;
							
							if (v2y > v3y) begin  // if V2 is bigger than V3,
								p2x = v3x;  // second vertex is V3
								p2y = v3y;
								p2z = v3z;
								
								p3x = v2x;  // third vertex is V2
								p3y = v2y;
								p3z = v2z;
							end
							
							else begin  // if V3 is bigger than V2,
								p2x = v2x;  // second vertex is V2
								p2y = v2y;
								p2z = v2z;
								
								p3x = v3x;  // third vertex is V3
								p3y = v3y;
								p3z = v3z;
							end
						end
						
						else if ((v2y < v1y) & (v2y < v3y)) begin  // if V2 is the largest vertex
							p1x = v2x;  // first vertex is V2
							p1y = v2y;
							p1z = v2z;
							
							if (v1y > v3y) begin  // if V1 is bigger than V3,
								p2x = v3x;  // second vertex is V1
								p2y = v3y;
								p2z = v3z;
								
								p3x = v1x;  // third vertex is V3
								p3y = v1y;
								p3z = v1z;
							end
							
							else begin  // if V2 is bigger than V1,
								p2x = v1x;  // second vertex is V3
								p2y = v1y;
								p2z = v1z;
								
								p3x = v3x;  // third vertex is V2
								p3y = v3y;
								p3z = v3z;
							end
						end
						
						else begin
							p1x = v3x;  // first vertex is V2
							p1y = v3y;
							p1z = v3z;
							
							if (v1y > v2y) begin  // if V1 is bigger than V3,
								p2x = v2x;  // second vertex is V1
								p2y = v2y;
								p2z = v2z;
								
								p3x = v1x;  // third vertex is V3
								p3y = v1y;
								p3z = v1z;
							end
							
							else begin  // if V2 is bigger than V1,
								p2x = v1x;  // second vertex is V3
								p2y = v1y;
								p2z = v1z;
								
								p3x = v2x;  // third vertex is V2
								p3y = v2y;
								p3z = v2z;
							end
						end
						state <= S1;
					end
				end
				
				S1: begin  // calculate numerators and denominators for inverse slopes
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
				
					state <= S2;
				end
				
				
				S2: begin
					start_div <= 1; // start the divide process
					
					if (done_div1 & done_div2) begin  // wait until the divides are done
						state <= S3; 
						start_div <= 0;
					end
				end
				
				
				S3: begin
					// at this point inverse slopes dp1p2 and dp1p3 are ready
					start_y = p1y >> 5;
					end_y = (p3y >> 5) + 1;
					y_coord = start_y;
					
					state <= S4;
				end 			
				
				
				S4: begin  // sort vertices to be drawn for given y_coord
					if ( (dp1p2num * dp1p3den) > (dp1p3num * dp1p2den) ) begin
						if ( (y_coord << 5) < p2y) begin
							pax = p1x;
							pay = p1y;
							paz = p1z;
							
							pbx = p3x;
							pby = p3y;
							pbz = p3z;
							
							pcx = p1x;
							pcy = p1y;
							pcz = p1z;
							
							pdx = p2x;
							pdy = p2y;
							pdz = p2z;
						end
						
						else begin
							pax = p1x;
							pay = p1y;
							paz = p1z;
							
							pbx = p3x;
							pby = p3y;
							pbz = p3z;
							
							pcx = p2x;
							pcy = p2y;
							pcz = p2z;
							
							pdx = p3x;
							pdy = p3y;
							pdz = p3z;
						end
					end
					
					else begin
						if ( (y_coord << 5) < p2y) begin
							pax = p1x;
							pay = p1y;
							paz = p1z;
							
							pbx = p2x;
							pby = p2y;
							pbz = p2z;
							
							pcx = p1x;
							pcy = p1y;
							pcz = p1z;
							
							pdx = p3x;
							pdy = p3y;
							pdz = p3z;
						end
						
						else begin
							pax = p2x;
							pay = p2y;
							paz = p2z;
							
							pbx = p3x;
							pby = p3y;
							pbz = p3z;
							
							pcx = p1x;
							pcy = p1y;
							pcz = p1z;
							
							pdx = p3x;
							pdy = p3y;
							pdz = p3z;
						end
					end
					state <= S5;
				end
				
				
				
				S5: begin
					start_draw <= 1; // draw current line
					
					if (draw_line_done) begin  		// wait until the draw is done before we change states
						y_coord = y_coord + 1;  		// increment the y coordinate for next line to draw
						start_draw <= 0;  				// make sure to set start_draw back to 0 when we're done
						state <= S6;	
					end
				end 
				
			
				S6: begin
					
					if (y_coord < end_y) begin
						state <= S4;  			// jump back to S3 to draw the next line for new y_coord
					end
					
					else begin  // here we've finished shading the current triangle
						done <= 1;
						state <= S0;  		 // go back to reset state
					end
				end  // end state S5
				
			endcase
		end
	end
endmodule
