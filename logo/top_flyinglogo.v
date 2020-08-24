`timescale 1 ns / 1 ns


module top_flyinglogo(clk, rst, hsync, vsync,rom_addr,h_cnt,v_cnt,speed_cnt,speed_ctrl,flag_edge,flag_add_sub, logo_x,logo_y,logo_area,vga_r, vga_g, vga_b,pclk,valid,vga_sync_n);
   input           clk;
   input           rst;
   
   output          hsync;
   output          vsync;
	output          vga_sync_n;
   output [7:0]    vga_r;
   output [7:0]    vga_g;
   output [7:0]    vga_b;
   
   
   output            pclk;
   output           valid;
   output wire [9:0]      h_cnt;
   output wire [9:0]      v_cnt;
   reg [11:0]       vga_data;
   
   output reg [13:0]      rom_addr=14'b0000000000000000;
   wire [11:0]      douta;
   
   output wire            logo_area;
   output reg [9:0]       logo_x=10'b00000000001;
   output reg [9:0]       logo_y=10'b00000000001;
   parameter [9:0] logo_length =10'b0001100100;
   parameter [9:0] logo_hight  = 10'b0001100100;
   
   output reg [7:0]       speed_cnt;
   output wire            speed_ctrl;
   
   output reg [3:0]       flag_edge;
   output reg [1:0]       flag_add_sub;
	  /*dcm_25m u0
         (
         // Clock in ports
          .clk_in1(clk),      // input clk_in1
          // Clock out ports
          .clk_out1(pclk),     // output clk_out1
          // Status and control signals
          .reset(rst));   */
			 clkgen #(25000000) u0(
			        .clkin(clk),
					  .rst(rst),
					  .clkout(pclk),
					  .clken(1'b1));
	       
	logo_rom u1 (
          .clka(pclk),    // input wire clka
          .addra(rom_addr),  // input wire [13 : 0] addra
          .douta(douta)  // output wire [11 : 0] douta
        );
 
	vga_ctrl u2 (
		.pclk(pclk), 
		.reset(rst), 
		.hsync(hsync), 
		.vsync(vsync), 
		.valid(valid), 
		.h_addr(h_cnt), 
		.v_addr(v_cnt)
		);
 
   assign logo_area = ((v_cnt >= logo_y) & (v_cnt <= logo_y + logo_hight - 1) & (h_cnt >= logo_x) & (h_cnt <= logo_x + logo_length - 1)) ? 1'b1 : 
                      1'b0;
   
   assign vga_sync_n=1'b0;
   always @(posedge pclk)
   begin
      if (rst == 1'b1)
         vga_data <= 12'b000000000000;
      else 
      begin
         if (valid == 1'b1)
         begin
            if (logo_area == 1'b1)
            begin
              rom_addr <= rom_addr + 14'b00000000000001;
               vga_data <= douta;
            end
            else
            begin
               rom_addr <= rom_addr;
               vga_data <= 12'b000000000000;
            end
         end
         else
         begin
            vga_data <= 12'b111111111111;
            if (v_cnt == 0)
               rom_addr <= 14'b00000000000000;
         end
      end
   end
   
   assign vga_r[7:4] = vga_data[11:8];
   assign vga_g[7:4] = vga_data[7:4];
   assign vga_b[7:4] = vga_data[3:0];
	assign vga_r[3:0]=4'b0000;
	assign vga_g[3:0]=4'b0000;
   assign vga_b[3:0]=4'b0000;
   
   
   always @(posedge pclk)
   begin
      if (rst == 1'b1)
         speed_cnt <= 8'h00;
      else 
      begin
         if ((v_cnt[5] == 1'b1) & (h_cnt == 1))
            speed_cnt <= speed_cnt + 8'h01;
      end
   end
   
   
   debounce u3(.sig_in(speed_cnt[5]), .clk(pclk), .sig_out(speed_ctrl));
   
   
   always @(posedge pclk)
   begin  
      if (rst == 1'b1)
      begin
         flag_add_sub = 2'b01;
         
         logo_x <= 10'b0001100100;
         logo_y <= 10'b0001100100;
      end
      else 
      begin
         
         if (speed_ctrl == 1'b1)
         begin
            if (logo_x == 1)
            begin
               if (logo_y == 1)
               begin
                  flag_edge <= 4'h1;
                  flag_add_sub = 2'b00;
               end
               else if (logo_y == 480 - logo_hight)
               begin
                  flag_edge <= 4'h2;
                  flag_add_sub = 2'b01;
               end
               else
               begin
                  flag_edge <= 4'h3;
                  flag_add_sub[1] = (~flag_add_sub[1]);
               end
            end
            
            else if (logo_x == 640 - logo_length)
            begin
               if (logo_y == 1)
               begin
                  flag_edge <= 4'h4;
                  flag_add_sub = 2'b10;
               end
               else if (logo_y == 480 - logo_hight)
               begin
                  flag_edge <= 4'h5;
                  flag_add_sub = 2'b11;
               end
               else
               begin
                  flag_edge <= 4'h6;
                  flag_add_sub[1] = (~flag_add_sub[1]);
               end
            end
            
            else if (logo_y == 1)
            begin
               flag_edge <= 4'h7;
               flag_add_sub[0] = (~flag_add_sub[0]);
            end
            else if (logo_y == 480 - logo_hight)
            begin
               flag_edge <= 4'h8;
               flag_add_sub[0] = (~flag_add_sub[0]);
            end
            else
            begin
               flag_edge <= 4'h9;
               flag_add_sub = flag_add_sub;
            end
            
            case (flag_add_sub)
               2'b00 :
                  begin
                     logo_x <= logo_x + 10'b0000000001;
                     logo_y <= logo_y + 10'b0000000001;
                  end
               2'b01 :
                  begin
                     logo_x <= logo_x + 10'b0000000001;
                     logo_y <= logo_y - 10'b0000000001;
                  end
               2'b10 :
                  begin
                     logo_x <= logo_x - 10'b0000000001;
                     logo_y <= logo_y + 10'b0000000001;
                  end
               2'b11 :
                  begin
                     logo_x <= logo_x - 10'b0000000001;
                     logo_y <= logo_y - 10'b0000000001;
                  end
               default :
                  begin
                     logo_x <= logo_x + 10'b0000000001;
                     logo_y <= logo_y + 10'b0000000001;
                  end
            endcase
         end
         
      end
   end
	
endmodule