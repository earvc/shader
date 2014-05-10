module put_pixel(input logic clk, reset,
					  input logic start,
					  input logic [15:0] x0, y0, x1, y1,
					  input logic [15:0] z1, z2,
					  
					  output logic plot,
					  output logic [10:0] x, y,
					  output logic [15:0] z_out,
					  output logic done);
	
	typedef enum logic [6:0] {S0, S1, S2, S3, S4, S5, S6} state_t;
	state_t state;
	
	logic [15:0] x_coord;
	logic [15:0] y_coord;
	logic [15:0] z_coord;
	
	
	// divider stuff
	logic [15:0] gradientnum, gradientden, gradient;
	logic start_div;  // start divides
	logic done_div;
	
	// dividers required
	divider14 div1(clk, reset, start_div, gradientnum, gradientden, gradient, done_div);
	
	
	
	// signals for interpolation modules
	logic start_int; 
	logic done_int;
	
	// higher resolution interpolate block
	interpolate interpolate_inst( .clk(clk), .start(start_int), .reset(reset), 
									    .min_val(z1), .max_val(z2), .gradient(gradient), 
										 .done(done_int), .val(z_coord) );
	
	
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
					if (x1 == x0) begin // start x and end x are the same -> force gradient to 0
						gradientnum = 0;
						gradientden = 1;
					end
					
					else begin
						gradientnum = (x_coord << 5) - (x0 << 5);
						gradientden = (x1 << 5) - (x0 << 5);
					end
					
					start_div = 1;
					
					if(done_div) begin
						start_div <= 0;
						start_int <= 1; // since gradients are available, start interpolation for z-value
						state <= S2;
					end
				end
				
				S2: begin
					if(done_int) begin  // when interpolation for z is done
						z_out = z_coord;
						start_int <= 0;
						plot <= 1;
						state <= S3;
					end
				end
				
				
				S3: begin
					plot = 0;
					x_coord = x_coord + 1;
					state <= S4;
				end
				
				S4: begin
					if (x_coord > x1) begin
						done <= 1;
						state <= S5;
					end
					else begin
						x = x_coord;
						state <= S6;
					end
				end
				
				S5: begin
					done <= 0;
					state <= S0;
				end
				
				S6: begin
					state <= S1;
				end		
			endcase
		end
	end
endmodule
