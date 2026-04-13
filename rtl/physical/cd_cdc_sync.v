`include "spw_params.vh"

module phy_cdc_sync #(
    parameter integer WIDTH = 1
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

// 3 FlipFlop chain to keep metastability at bay
// Just formed a joke: " An extra flipflop in your design forces the metastability to resign... Sorry :'( "

(*keep = "true"*)
reg [WIDTH-1:0] ff1_r;

(*keep = "true"*)
reg [WIDTH-1:0] ff2_r;

(*keep = "true"*)
reg [WIDTH-1:0] ff3_r;

always @(posedge clk) begin
    if(!rst_n) begin
        ff1_r<={WIDTH{1'b0}};
        ff2_r <= {WIDTH{1'b0}};
        ff3_r <= {WIDTH{1'b0}};
    end
    else begin
        ff1_r <= din;
        ff2_r <= ff1_r;
        ff3_r<=ff2_r;
    end
end

assign dout = ff3_r;



    
endmodule

