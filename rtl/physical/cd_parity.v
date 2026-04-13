`include "spw_params.vh"

module cd_parity (
    input wire clk,
    input wire rst_n,
    input wire mode, // TX = 0, RX = 1
    input wire [9:0] char_in,
    input wire valid_in,

    output reg [9:0] char_out,
    output reg valid_out,
    output reg parity_err
);

wire parity_bit_generation = ~(^char_in[8:0]);
wire [9:0] characters_with_parity = {parity_bit_generation, char_in[8:0]};
wire parity_ok = ^char_in[9:0];
wire parity_bad = ~parity_ok;



always @(posedge clk) begin
    if(!rst_n) begin
        char_out<=10'b0;
        valid_out<=1'b0;
        parity_err<=1'b0;
    end else begin
        valid_out <= 1'b0;
        parity_err <=1'b0;
        if(!mode) begin
            if(valid_in) begin
                char_out <= characters_with_parity;
                valid_out<=1'b1;
            end
        end 
        else begin
            if(valid_in) begin
                char_out <=char_in;
                valid_out<=1'b1;
                parity_err<=parity_bad;
            end
        end
    end
    
end

    
endmodule