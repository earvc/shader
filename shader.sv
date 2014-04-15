/* testing arithmetic */

module shader	  (input logic			 	clk,
						input logic			 	start,
						input logic [15:0]   p1x, p1y,
						input logic [15:0]   p2x, p2y,
						input logic [15:0]   p3x, p3y,
		 
						output logic write_pixel,
						output logic done,
						output logic [9:0] x_pixel,
						output logic [9:0] y_pixel,
						output logic [7:0] R, G, B
						);
						
	////////////////////////////
	//
	//  internal signals
	//
	////////////////////////////

						
	logic [15:0] dp1p2, dp1p2num, dp1p2den;
	logic [15:0] dp1p3, dp1p3num, dp1p3den;
	logic [31:0] temp1, temp2, temp3;
	logic rst_div;  	// reset signal for divider
	logic start_div;  // start divides
	logic done_div1;  // done dividing
	logic done_div2;
	
	logic [15:0] start_y, end_y;

	// divider modules i need for this section
	divider inv_slope1 (clk, rst_div, start_div, dp1p2num, dp1p2den, dp1p2, done_div1);
	divider inv_slope2 (clk, rst_div, start_div, dp1p3num, dp1p3den, dp1p3, done_div2);
	
	typedef enum logic [7:0] {S0, S1, S2, S3, S4, S5, S6} state_t;
	state_t state;

	
	///////////////////////////
	//
	// Shader FSM
	//
	///////////////////////////
	
	
	
	always_ff @(posedge clk) begin
		if (start) begin
			state <= S0;
		end
		
		else begin
			case (state)
				S0: begin  // calculate numerators and denominators for inverse slopes
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
				
				
				
				S1: begin
					rst_div <= 0; // bring reset back to 0
					start_div <= 1; // start the divide process
					
					if (done_div1 & done_div2) begin  // wait until the divides are done
						state <= S2; 
						start_div <= 0;
					end
				end
				
				
				S2: begin
					// at this point inverse slopes dp1p2 and dp1p3 are ready
					start_y = p1y >> 5;
					end_y = (p3y >> 5) + 1;
				
					state <= S3;
				end
				
				
				
				S3: begin
				
				
				
					state <= S4;
				end
				
				
				
				S4: begin
				
				
				
					state <= S5;
				end
				
				
				
				S5: begin
				
				
				
					state <= S6;
				end
				
				
				
				S6: begin
				
				
				
					state <= S0;
				end
			endcase
		end
	end
endmodule

module draw_line(input logic clk,
					  input logic reset,
					  input logic start,
					  input logic [15:0] y_coord,
					  input logic [15:0] pax, pay,
					  input logic [15:0] pbx, pby,
					  input logic [15:0] pcx, pcy,
					  input logic [15:0] pdx, pdy,
					  
					  output logic done,
					  output logic [15:0] pixel_x, pixel_y
					  );
	
	typedef enum logic [7:0] {S0, S1, S2, S3, S4, S5, S6, S7} state_t;
	state_t state;
	
	
	// internal signals
	logic [15:0] gradient1, gradient1num, gradient1den;
	logic [15:0] gradient2, gradient2num, gradient2den;
	logic [15:0] temp_y;
	
	// signals requred for the dividers
	logic rst_div;  	// reset signal for divider
	logic start_div;  // start divides
	logic done_div1;  // done dividing
	logic done_div2;
	
	// two dividers required
	divider div1(clk, rst_div, start_div, gradient1num, gradient1den, gradient1, done_div1);
	divider div2(clk, rst_div, start_div, gradient2num, gradient2den, gradient2, done_div2);
	
	
	always_ff @(posedge clk) begin
		temp_y = y_coord << 5;
		if (reset) begin
			state <= S0;
		end
		
		else begin
			case (state)
			
				S0: begin  // calculate gradients
					if (start) begin
						
						if (pay != pby) begin
							gradient1num = y_coord - pay;
							gradient1den = pby - pay;
						end
						else
							gradient1num = 1;
							gradient1den = 1;
						end
						
						if (pcy != pdy) begin
							gradient2num = (y - pcy);
							gradient2den = (pdy - pcy);
						end
						else
							gradient2num = 1;
							gradient2den = 1;
						end
						
						rst_div <= 1; // reset the dividers to get them ready
						state <= S1;
					end
					
				end
				
				S1: begin  // divide to get the gradients
					rst_div <= 0;  	// bring reset back to 0
					start_div <= 1;   // start the dividers
					
					if (done_div1 & done_div2) begin
						start_div <= 0;
						state <= S1;
					end
				end
				
				S2: begin
					state <= S1;
				end
				
				S3: begin
					state <= S1;
				end
				
				S4: begin
					state <= S1;
				end
				
				S5: begin
					state <= S1;
				end
				
				S6: begin
					state <= S1;
				end
				
				S7: begin
					state <= S1;
				end
				
			endcase
		end
	end
			
endmodule


module divider(input clk,
					input reset,
					input start,
					input logic [15:0] num,
				   input logic [15:0] den,
					
					output logic [15:0] result,
					output logic done);
					
	typedef enum logic [3:0] {S0, S1, S2, S3} state_t;
	state_t state;
	
	logic [15:0] temp_num;
	logic [15:0] temp_den;
	logic [15:0] temp_result;
	
	always_ff @(posedge clk) begin
		done <= 0;
		if (reset) begin
			state <= S0;
		end
			
		else begin
			case (state)
				S0: begin
					if (start) begin
						if (num[15] & den[15]) begin  // if both the num and den are negative
							// divide only the magnitudes
							temp_num = ~(num - 1);
							temp_den = ~(den - 1);
							state <= S1;
						end
						
						// following two conditions make sure the result is negative
						
						else if (num[15] & ~den[15]) begin  // if only num is negative
							temp_num = ~(num - 1);  // get magnitude of the numerator
							temp_den = den;
							state <= S2;
						end
						
						else if (~num[15] & den[15]) begin // if only den is negative
							temp_num = num;
							temp_den = ~(den - 1); 
							state <= S2;
						end
						
						else begin  // both numbers are positive
							temp_num = num;
							temp_den = den;
							state <= S1;
						end
					end
				end
				
				S1: begin  // result is positive
					result = temp_num / temp_den;
					done <= 1;
					
					if (~start) begin
					done <= 0;
						state <= S0;
					end
				end
				
				
				S2: begin  // result is negative
					temp_result = temp_num / temp_den;
					result = ~(temp_result) + 1; // maintains Qx.5 format
					done <= 1;
					
					if (~start) begin
						done <= 0;
						state <= S0;
					end
				end
				
			endcase
		end
		
	end
	
endmodule
