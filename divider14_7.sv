module divider14_7(input clk,
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
	logic [31:0] temp_result;
	
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
					temp_result = (temp_num << 16) / (temp_den << 2);
					result = temp_result[15:0];
					done <= 1;
					
					if (~start) begin
					done <= 0;
						state <= S0;
					end
				end
				
				
				S2: begin  // result is negative
					temp_result = (temp_num << 16) / (temp_den << 2);
					result = ~(temp_result[15:0]) + 1; // maintains Qx.14 format
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