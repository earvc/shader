module VGA_framebuffer(
 input logic 	    clk50, reset,
 input logic [10:0]  x,  // pixel x_coordinate
 input logic [10:0]  y,  // pixel y_coordinate
 input logic [15:0]   z,  // pixel z_coordinate
 input logic [15:0]			pixel_color, 
 input logic			pixel_write,
 
 output logic [7:0] VGA_R, VGA_G, VGA_B,
 output logic 	    VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 *HCOUNT 1599 0             1279       1599 0
 *            _______________              ________
 * __________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */

   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC + HBACK_PORCH; //1600

   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC + VBACK_PORCH; //525

				 
	// Horizontal counter
   logic [10:0]		  hcount; 
   logic 			     endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;

   // Vertical counter
   logic [9:0] 			     vcount;
   logic 			     endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset) vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x57F
   // 101 0010 0000 to 101 0111 1111
   assign VGA_HS = !( (hcount[10:7] == 4'b1010) & (hcount[6] | hcount[5]));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1; // For adding sync to video signals; not used for VGA
	
	
	logic 				blank;   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480	       
   // 110 0011 1111  1599	       10 0000 1100  524        
   assign blank = ( hcount[10] & (hcount[9] | hcount[8]) ) |
						( vcount[9] | (vcount[8:5] == 4'b1111) );
			
	
	logic	[1:0] 		framebuffer [307199:0];  // 640 x 480
	logic	[18:0]		read_address, write_address;
	
	assign write_address = x + (y << 9) + (y << 7);
	assign read_address = (hcount >> 1) + (vcount << 9) + (vcount << 7);
	
	
	/************************************************************
	*
	*
	*		Pixel write code using z-buffering
	*
	*
	*************************************************************/
	
	logic zbuffer_clear, zbuffer_write;
	logic  [7:0] zbuffer_rdata;
	logic [18:0] zbuffer_address;
	logic write_fb;
	
	zbuffer zbuffer_shader (.aclr(zbuffer_clear), .address(zbuffer_address), 
				.clock(clk50), .data(z), .wren(zbuffer_write), 
				.q(zbuffer_rdata));
	
	typedef enum logic [2:0] {S0, S1, S2} state_t;
	state_t state;
	
	always_ff @ (posedge clk50) begin
		if (reset) begin
			zbuffer_clear <= 0;
			state <= S0;
		end
		
		else begin
			case (state) 
				S0: begin
					if (pixel_write) begin
						zbuffer_address <= write_address;  // check the current z value of the pixel you want to write
						state <= S1;
					end
				end
				
				S1: begin
					/*if (zbuffer_rdata <= z) begin // if current z is less than new z
						write_fb <= 1;  				// write pixel to frame buffer
						zbuffer_write <= 1;  		// write new value to z-buffer
						state <= S2;
					end */
					
					write_fb <= 1;  				// write pixel to frame buffer
					zbuffer_write <= 1;  		// write new value to z-buffer
					state <= S2;
				end
				
				S2: begin
					// cleanup signals
					write_fb <= 0;
					zbuffer_write <= 0;
					state <= S0;
				end
			endcase
		end
	end
	
	
	logic [1:0]				pixel_read;
	always_ff @(posedge clk50) begin
		if (write_fb) framebuffer[write_address] <= 2'b01;
	
		if (hcount[0]) begin
			pixel_read <= framebuffer[read_address];
			VGA_BLANK_n <= ~blank;  // sync blank with read pixel data
		end
	end
	
	assign VGA_CLK = hcount[0];  // 25MHz clock
	
	always_ff @(posedge clk50) begin
		if (pixel_read == 2'b01) begin
			{VGA_R, VGA_G, VGA_B} = {pixel_color, pixel_color, 8'hff};
		end
		else if (pixel_read == 2'b10) begin  // medium
			{VGA_R, VGA_G, VGA_B} = {pixel_color, pixel_color, 8'hff};
		end
		else if (pixel_read == 2'b11) begin  // dark
			{VGA_R, VGA_G, VGA_B} = {pixel_color, pixel_color, 8'hff};
		end
		else begin
			{VGA_R, VGA_G, VGA_B} = 24'h0;
		end
	end
	
endmodule
	
	