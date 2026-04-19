`include "spw_params.vh"

module cd_ds (
    input wire clk,
    input wire rst_n,
    input wire rx_en,
    input wire din,
    input wire sin,
    
    output reg[9:0] rx_char,
    output reg rx_valid,
    output reg disc_refresh

);

function [3:0] gray_increment;
    input [3:0]g;
    reg [3:0] b, b_next;
    begin
        b[3] = g[3];
        b[2] = b[3]^g[2];
        b[1] = b[2]^g[1];
        b[0] = b[1]^g[0];

        b_next = b+4'd1;
        gray_increment[3] = b_next[3];
        gray_increment[2] = b_next[3]^b_next[2];
        gray_increment[1] = b_next[2]^b_next[1];
        gray_increment[0] = b_next[1]^b_next[0];

    end
    
endfunction

function [3:0] gray_to_bin;
    input[3:0] g;
    reg [3:0] b;
    begin
        b[3]=g[3];
        b[2]=b[3]^g[2];
        b[1]=b[2]^g[1];
        b[0]=b[1]^g[0];
        gray_to_bin=b;
    end
endfunction
    

reg xor_prev;
reg sin_prev;

reg[3:0] bit_cnt_g;
reg[9:0] rx_buf;
reg rx_en_prev;

wire xor_cur = din^sin;
wire dsEdge = xor_cur^xor_prev;
wire[3:0] bit_index = gray_to_bin(bit_cnt_g);
wire last_bit=(bit_index==4'd9);

wire decoded_bit = sin^sin_prev;

always @(posedge clk) begin
    if (!rst_n) begin
        xor_prev     <= 1'b0;
        sin_prev<=0;
        bit_cnt_g    <= 4'b0000;
        rx_buf       <= 10'b0;
        rx_char      <= 10'b0;
        rx_valid     <= 1'b0;
        disc_refresh <= 1'b0;
    end else begin
        rx_valid     <= 1'b0;
        disc_refresh <= 1'b0;
        xor_prev <= xor_cur;
        sin_prev<=sin;
        // if (rx_en && dsEdge) begin
        //     rx_buf[bit_index] <= din;
        //     disc_refresh <= 1'b1;
        //     if (last_bit) begin
        //         rx_char   <= {din, rx_buf[8:0]};   
        //         rx_valid  <= 1'b1;
        //         bit_cnt_g <= 4'b0000;               
        //     end else begin
        //         bit_cnt_g <= gray_increment(bit_cnt_g);
        //     end
        // end
        
        if (!rx_en) begin
            bit_cnt_g <= 4'b0000;
            rx_buf<=10'b0;

        end
        else if (dsEdge) begin
            rx_buf[bit_index]<=decoded_bit;
            disc_refresh<=1'b1;
            if(last_bit) begin
                rx_char<={decoded_bit,rx_buf[8:0]};
                rx_valid<=1'b1;
                bit_cnt_g<=4'b0000;
                rx_buf<=10'b0;

            end
            else begin
                bit_cnt_g <= gray_increment(bit_cnt_g);
            end
        end
    end
end

// always@(posedge clk) begin 
//     rx_en_prev<= rx_en;
//     if(!rst_n|| (!rx_en_prev && rx_en)) begin
//         xor_prev<=xor_cur;
//         bit_cnt_g<= 4'b0000;
//         rx_buf<=10'd0;
//     end
//end

endmodule