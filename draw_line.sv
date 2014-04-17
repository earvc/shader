module draw_line(input logic clk,
					  input logic reset,
					  input logic start,
					  input logic bresenham_done,
					  input logic [15:0] y_coord,
					  input logic [15:0] pax, pay,
					  input logic [15:0] pbx, pby,
					  input logic [15:0] pcx, pcy,
					  input logic [15:0] pdx, pdy,
					  
					  output logic done,
					  output logic draw,
					  output logic [10:0] start_x, end_x
					  );
	
	typedef enum logic [8:0] {S0, S1, S2, S3, S4, S5, S6, S7, S8} state_t;
	state_t state;
	
	
	// internal signals
	logic [15:0] gradient1num, gradient1den;
	logic [15:0] gradient2num, gradient2den;
	logic [15:0] gradient1;
	logic [15:0] gradient2;
	logic [15:0] temp_y;
	
	logic [31:0] temp_product11, temp_product12;
	logic [31:0] temp_product21, temp_product22;
	logic [15:0] sx, ex;
	logic [15:0] temp_x;
	
	// signals requred for the dividers
	logic rst_div;  	// reset signal for divider
	logic start_div;  // start divides
	logic done_div1;  // done dividing
	logic done_div2;
	
	// two dividers required
	divider14 div1(clk, reset, start_div, gradient1num, gradient1den, gradient1, done_div1);
	divider14 div2(clk, reset, start_div, gradient2num, gradient2den, gradient2, done_div2);
	
	
	always_ff @(posedge clk) begin
		temp_y = y_coord << 5;
		if (reset) begin
			state <= S0;
		end
		
		else begin
			case (state)
			
				S0: begin 
					
					///////////////////////////////////////
					//
					//  Calculate num and den
					//  of the gradients
					//
					///////////////////////////////////////
				
					if (start) begin
						
						if (pay != pby) begin
							gradient1num = temp_y - pay;
							gradient1den = pby - pay;
						end
						else begin
							gradient1num = 1;
							gradient1den = 1;
						end
						
						if (pcy != pdy) begin
							gradient2num = (temp_y - pcy);
							gradient2den = (pdy - pcy);
						end
						else begin
							gradient2num = 1;
							gradient2den = 1;
						end
						
						rst_div <= 1; // reset the dividers to get them ready
						state <= S1;
					end
					
				end
				
					
				S1: begin 
				
					//////////////////////////////////////////////////
					//
					//  Since we have num and den for each gradient,
					//  we can now divide these values to get the 
					//  actual gradients.
					//
					//////////////////////////////////////////////////
					
					rst_div <= 0;  	// bring reset back to 0
					start_div <= 1;   // start the dividers
					
					if (done_div1 & done_div2) begin
						start_div <= 0;
						state <= S2;
					end
				end
				
				
				S2: begin
				
					///////////////////////////////////////////////////
					//
					//  Precomputation for gradients
					//
					///////////////////////////////////////////////////
					
					temp_product11 = (pbx - pax) * gradient1;  // result is in Q.19 format
					temp_product21 = (pdx - pcx) * gradient2;  // result is in Q.19 format
					
					state <= S3;
				end
				
				
				S3: begin  // figure out temp_product for gradient 1
					
					if (temp_product11[31]) begin
						temp_product12 = ~(temp_product11 - 1); // get magnitude of temp_product if negative
						state <= S4;  // one last step for processing
					end
					
					else begin
						temp_product12 = temp_product11;
						state <= S4;
					end
					
				end
				
				S4: begin  // figure out temp+product for graident 2
					
					if (temp_product21[31]) begin
						temp_product22 = ~(temp_product21 - 1); // get magnitude of temp_product negative
						state <= S5;
					end
					
					else begin
						temp_product22 = temp_product21;
						state <= S5;
					end
				end
				
				S5: begin  // final step for pre-computation for sx and ex
					
					if (temp_product11[31]) begin  // if the temp_product is negative
						temp_product12 = ~(temp_product12 >> 14) + 1;  // need to convert final result to 2s complement
					end
					
					else begin
						temp_product12 = (temp_product12 >> 14);  // otherwise just shift
					end
					
					
					if (temp_product21[31]) begin
						temp_product22 = ~(temp_product22 >> 14) + 1;
					end
					
					else begin
						temp_product22 = (temp_product22 >> 14);
					end
					
					state <= S6;
				end  // send state S5
				
				
				S6: begin
				
					////////////////////////////////////////////////
					//
					//  At this point we have the gradients and have 
					//  done the necessary pre-computation for
					//  them. No we can calculate sx and ex
					//
					////////////////////////////////////////////////
					
					// gradient 1 clamp
					
					if (gradient1[15]) begin  // gradient1 < 0
						sx = pax;  // gradient1 = 0;
					end
					
					else if ( (gradient1 >> 14) >= 1) begin
						sx = pax + (pbx - pax); // gradient1 = 1;
					end
					
					else begin
						sx = pax + temp_product12;
					end
					
					
					// gradient2 clamp
					
					if (gradient2[15]) begin    // gradient2 < 0
						ex = pcx; // gradient2 = 0;
					end
					
					else if ( (gradient2 >> 14) >= 1) begin
						ex = pcx + (pdx - pcx);  // gradient2 = 1;
					end
					
					else begin
						ex = pcx + temp_product22;
					end
					
					state <= S7;
					
				end
				
				S7: begin
					if (sx > ex) begin
						temp_x = sx;
						start_x = ex >> 5;
						end_x = temp_x >> 5;
					end
					
					else begin
						start_x = sx >> 5;
						end_x = ex >> 5;
					end
					
					draw <= 1;
					state <= S8;
					
				end
				
				S8: begin
					draw <= 0;
					
					if (bresenham_done) begin  // when bresenham is done
						done <= 1;
					end
					
					if (~start) begin  // wait until start is deasserted
						done <= 0;
						state <= S0;
					end;
				end
				
			endcase
		end
	end
endmodule