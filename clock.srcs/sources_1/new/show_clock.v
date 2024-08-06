`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2024 11:49:26 AM
// Design Name: 
// Module Name: show_clock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module show_clock(
    input CLK_100MHZ,
    input [15:0] SW,
    input [3:0] BTN,
    output reg [2:0] RGB1,
    output reg [2:0] RGB0,
    output [15:0] LED,
    output [7:0] D0_SEG,
    output reg [3:0] D0_AN,
    output [7:0] D1_SEG,
    output reg [3:0] D1_AN
    );
    
    
    reg [20:0] cnt; // Cycle counter goes up to 2 million
    reg ms_cnt; // Counts every 500000 cycles (500000 cycles = 1 / 200 sec with 100MHz clock)
    reg [6:0] sec_cnt;
    reg [3:0] split1;
    reg [3:0] split0;
    reg on_off;
    reg [3:0] top_hr;
    reg [3:0] bottom_hr;
    reg [3:0] top_min;
    reg [3:0] bottom_min;
    reg [3:0] top_sec;
    reg [3:0] bottom_sec;
    reg [3:0] top_ms;
    reg [3:0] bottom_ms;
    reg hr_btn_buffer;
    reg min_btn_buffer;
    reg dec0;
    reg dec1;
    
    assign LED = SW;
        
    always @(posedge CLK_100MHZ) begin
        cnt <= cnt + 1;
        if (cnt < 499999) begin
            split0 <= bottom_min;
            split1 <= bottom_ms;
            dec0 <= 0;
            dec1 <= 1;
            D0_AN <= 4'b0111;
            D1_AN <= 4'b0111;
        end else if (cnt < 999999) begin
            split0 <= top_min;
            split1 <= top_ms;
            dec0 <= 1;
            dec1 <= 1;
            D0_AN <= 4'b1011;
            D1_AN <= 4'b1011;
        end else if (cnt < 1499999) begin
            split0 <= bottom_hr;
            split1 <= bottom_sec;
            dec0 <= 1;
            dec1 <= 0;
            D0_AN <= 4'b1101;
            D1_AN <= 4'b1101;
        end else if (cnt < 1999999) begin 
            split0 <= top_hr;
            split1 <= top_sec;
            dec0 <= 1;
            dec1 <= 1;
            D0_AN <= 4'b1110;
            D1_AN <= 4'b1110;
        end else if (cnt == 1999999)begin
            cnt <= 0;
        end
        
        if (cnt == 999999 || cnt == 1999999) begin 
            sec_cnt <= sec_cnt + 1;
            
            if (sec_cnt == 99) begin
                sec_cnt <= 0;
                on_off <= ~on_off; // Turn RGB lights on/off every second
            end
            
            if (bottom_ms == 9) begin
                bottom_ms <= 0;
                if (top_ms == 9) begin
                    top_ms <= 0;
                    if (bottom_sec == 9) begin 
                        bottom_sec <= 0;
                        if (top_sec == 5) begin 
                            top_sec <= 0;
                            if (bottom_min == 9) begin
                                bottom_min <= 0;
                                if (top_min == 5) begin 
                                    top_min <= 0;
                                    if (bottom_hr == 9) begin
                                        bottom_hr <= 0;
                                        top_hr <= top_hr + 1;
                                    end else if (bottom_hr == 3 && top_hr == 2) begin
                                        bottom_hr <= 0;
                                        top_hr <= 0;
                                    end else bottom_hr <= bottom_hr + 1;
                                end else top_min <= top_min + 1;
                            end else bottom_min <= bottom_min + 1;
                        end else top_sec <= top_sec + 1;
                    end else bottom_sec <= bottom_sec + 1;
                end else top_ms <= top_ms + 1;
            end else bottom_ms <= bottom_ms + 1;
        end 
        
        if (min_btn_buffer && !(BTN[1] || BTN[0])) begin
            min_btn_buffer <= 0;
        end else if (!min_btn_buffer && BTN[1] && SW[0]) begin
            bottom_ms <= 0;
            top_ms <= 0;
            bottom_sec <= 0;
            top_sec <= 0;
            if (bottom_min == 9) begin
                bottom_min <= 0;
                if (top_min == 5) begin
                    top_min <= 0;
                end else top_min <= top_min + 1;
            end else bottom_min <= bottom_min + 1;
            min_btn_buffer <= 1;
        end else if (!min_btn_buffer && BTN[0] && SW[0]) begin 
            bottom_ms <= 0;
            top_ms <= 0;
            bottom_sec <= 0;
            top_sec <= 0;
            if (bottom_min == 0) begin 
                bottom_min <= 9;
                if (top_min == 0) begin
                    top_min <= 5;
                end else top_min <= top_min - 1;
            end else bottom_min <= bottom_min - 1;
            min_btn_buffer <= 1;
        end
        
        if (hr_btn_buffer && !(BTN[3] || BTN[2])) begin
            hr_btn_buffer <= 0;
        end else if (!hr_btn_buffer && BTN[3] && SW[0]) begin
            if (bottom_hr == 9) begin
                bottom_hr <= 0;
                top_hr <= top_hr + 1;
            end else if (bottom_hr == 3 && top_hr == 2) begin
                bottom_hr <= 0;
                top_hr <= 0;
            end else bottom_hr <= bottom_hr + 1;
            hr_btn_buffer <= 1;
        end else if (!hr_btn_buffer && BTN[2] && SW[0]) begin
            if (bottom_hr == 0) begin 
                if (top_hr == 0) begin
                    top_hr <= 2;
                    bottom_hr <= 3;
                end else begin
                    top_hr <= top_hr - 1;
                    bottom_hr <= 9;
                end
            end else bottom_hr <= bottom_hr - 1;
            hr_btn_buffer <= 1;
        end 
        
        
        RGB1 <= (on_off)? SW[2:0] : 0;
        RGB0 <= (on_off)? SW[5:3] : 0;
    end
    
    bto7s top_display (.x_in(split0), .dec(dec0), .s_out(D0_SEG));
    bto7s bottom_display (.x_in(split1), .dec(dec1), .s_out(D1_SEG));
    
endmodule

module bto7s (
    input [3:0] x_in,
    input dec, // 0 if should put decimal point else 1
    output [7:0] s_out
);
    assign s_out[0] = (x_in[3] & x_in[2] & ~x_in[1] & x_in[0]) | 
                      (x_in[3] & ~x_in[2] & x_in[1] & x_in[0]) |
                      (~x_in[3] & x_in[2] & ~x_in[1] & ~x_in[0]) |
                      (~x_in[3] & ~x_in[2] & ~x_in[1] & x_in[0]);
                   
   // 5, 6, B, C, E, F                    
   assign s_out[1] = (~x_in[3] & x_in[2] & ~x_in[1] & x_in[0]) | 
                     (~x_in[3] & x_in[2] & x_in[1] & ~x_in[0]) |
                     (x_in[3] & ~x_in[2] & x_in[1] & x_in[0]) |
                     (x_in[3] & x_in[2] & ~x_in[1] & ~x_in[0]) |
                     (x_in[3] & x_in[2] & x_in[1]);
   
   // 2, C, E, F
   assign s_out[2] = (x_in == 8'h2 | x_in == 8'hC)? 1 : (x_in[3] & x_in[2] & x_in[1]);
   assign s_out[3] = (x_in == 8'h1 | x_in == 8'h4 | x_in == 8'h7 | x_in == 8'hA | x_in == 8'hF)? 1 : 0;
   assign s_out[4] = (x_in == 8'h1 | x_in == 8'h3 | x_in == 8'h4 | x_in == 8'h5 | x_in == 8'h7 | x_in == 8'h9)? 1 : 0;
   assign s_out[5] = (x_in == 8'h1 | x_in == 8'h2 | x_in == 8'h3 | x_in == 8'h7 | x_in == 8'hD)? 1 : 0;
   assign s_out[6] = (x_in == 8'h0 | x_in == 8'h1 | x_in == 8'h7 | x_in == 8'hC)? 1 : 0;
   assign s_out[7] = dec;
endmodule

