// `include "spw_params.vh"

// module cd_parity (
//     input wire clk,
//     input wire rst_n,
//     input wire mode, // TX = 0, RX = 1
//     input wire [9:0] char_in,
//     input wire valid_in,

//     output reg [9:0] char_out,
//     output reg valid_out,
//     output reg parity_err
// );

// wire parity_bit_generation= ~(^char_in[8:0]);
// wire[9:0] characters_with_parity= {parity_bit_generation, char_in[8:0]};
// wire parity_ok = ^char_in[9:0];
// wire parity_bad=~parity_ok;



// always @(posedge clk) begin
//     if(!rst_n) begin
//         char_out<=10'b0;
//         valid_out<=1'b0;
//         parity_err<=1'b0;
//     end else begin
//         valid_out <= 1'b0;
//         parity_err <=1'b0;
//         if(!mode) begin
//             if(valid_in) begin
//                 char_out <= characters_with_parity;
//                 valid_out<=1'b1;
//             end
//         end 
//         else begin
//             if(valid_in) begin
//                 char_out <=char_in;
//                 valid_out<=1'b1;
//                 parity_err<=parity_bad;
//             end
//         end
//     end
    
// end

    
// endmodule
`include "spw_params.vh"

// =============================================================================
//  cd_parity.v — SpaceWire parity insert (TX) and check (RX)
//
//  Fix vs original:
//   TX mode was registered (1-cycle pipeline delay). This caused cd_tx to
//   already be in MODE_TRANSMIT by the time par_tx_valid_out arrived, so
//   cd_tx ignored the valid pulse and transmitted zeros (inDataReg=0).
//   Fixed: TX mode is now fully combinational — zero pipeline delay.
//   RX mode stays registered.
//
//  Parity convention:
//   bit[9] = odd parity over bits[8:0]  (~XOR of bits[8:0])
//   RX check: ^char_in[9:0] must equal 1.
// =============================================================================
module cd_parity (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mode,       // 0=TX (combinational), 1=RX (registered)
    input  wire [9:0]  char_in,
    input  wire        valid_in,

    output wire [9:0]  char_out,
    output wire        valid_out,
    output wire        parity_err
);

// ---------------------------------------------------------------------------
//  TX path — fully combinational, zero latency
// ---------------------------------------------------------------------------
wire        tx_parity   = ~(^char_in[8:0]);
wire [9:0]  tx_char_out = {tx_parity, char_in[8:0]};

// ---------------------------------------------------------------------------
//  RX path — registered for timing
// ---------------------------------------------------------------------------
wire rx_parity_bad = ~(^char_in[9:0]);   // odd parity: all 10 bits XOR should = 1

reg [9:0]  rx_char_r;
reg        rx_valid_r;
reg        rx_parity_err_r;

always @(posedge clk) begin
    if (!rst_n) begin
        rx_char_r       <= 10'b0;
        rx_valid_r      <= 1'b0;
        rx_parity_err_r <= 1'b0;
    end else begin
        rx_valid_r      <= 1'b0;
        rx_parity_err_r <= 1'b0;
        if (valid_in) begin
            rx_char_r       <= char_in;
            rx_valid_r      <= 1'b1;
            rx_parity_err_r <= rx_parity_bad;
        end
    end
end

// ---------------------------------------------------------------------------
//  Output mux
//  TX (mode=0): combinational — char and valid pass through immediately.
//  RX (mode=1): registered   — char and valid come from flip-flops.
// ---------------------------------------------------------------------------
assign char_out   = mode ? rx_char_r       : tx_char_out;
assign valid_out  = mode ? rx_valid_r      : valid_in;
assign parity_err = mode ? rx_parity_err_r : 1'b0;

endmodule