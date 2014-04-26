module interpolate ( input logic clk,
							input logic start,
							input logic reset,
							input logic [15:0] min_val,
							input logic [15:0] max_val,
							input logic [15:0] gradient,
							
							output logic done,
							output logic [15:0] val );

	//////////////////////////
	//
	//  internal signals
	//
	//////////////////////////
	
	logic [31:0] temp_product;  // Q.19 format
	logic [31:0] product;  // Q.19 format

	typedef enum logic [8:0] {S0, S1, S2, S3, S4, S5, S6, S7, S8} state_t;
	state_t state;
	
	always_ff @(posedge clk) begin
		if (reset) begin
			done <= 0;
			state <= S0;
		end
		else begin
			case (state)
			
			
				S0: begin  // calculate the product term
					done <= 0;
					if (start) begin
						temp_product = (max_val - min_val) * gradient;
						state <= S1;
					end
				end
			
			
			
				S1: begin  // get magnitude of product term
					if (temp_product[31]) begin 
						product = ~(temp_product - 1);
					end
					else begin
						product = temp_product;
					end
					state <= S2;
				end
		
		
		
				S2: begin  // shift to get Q.5
					if (temp_product[31]) begin
						product = ~(product >> 14) + 1;
					end
					else begin
						product = product >> 14;
					end
					state <= S3;
				end
				
				
				
				S3: begin
			
					if (gradient[15]) begin  // gradient < 0
						val = min_val;  // gradient = 0;
					end
					
					else if ( (gradient >> 14) >= 1) begin
						val = min_val + (max_val - min_val); // gradient = 1;
					end
					
					else begin
						val = min_val + product;
					end
					
					done <= 1;  // we're done!
					
					if (~start) begin
						state <= S0;
					end
				end
				
				
			endcase	
		end
	end
	
endmodule
