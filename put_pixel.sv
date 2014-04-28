module put_pixel(input logic clk, reset,
					  input logic start,
					  input logic [10:0] x0, y0, x1, y1,
					  input logic [10:0] z_coord,
					  
					  output logic plot,
					  output logic [10:0] x, y,
					  output logic done);
	
	typedef enum logic [6:0] {S0, S1, S2, S3, S4, S5, S6} state_t;
	state_t state;
	
	logic [10:0] x_coord;
	logic [10:0] y_coord;
	
	always_ff @(posedge clk) begin
		if (reset) begin
			done <= 0;
			state <= S0;
		end
		
		else begin
			case (state) 
			
				S0: begin
					if (start) begin
						x_coord = x0;
						y_coord = y0;
						x = x_coord;
						y = y0;
						state <= S1;
					end
				end
				
				S1: begin
					plot <= 1;
					state <= S2;
				end
				
				S2: begin
					plot = 0;
					x_coord = x_coord + 1;
					state <= S3;
				end
				
				S3: begin
					if (x_coord > x1) begin
						done <= 1;
						state <= S4;
					end
					else begin
						x = x_coord;
						state <= S5;
					end
				end
				
				S4: begin
					done <= 0;
					state <= S0;
				end
				
				S5: begin
					state <= S1;
				end		
			endcase
		end
	end
endmodule
