`include "spw_params.vh"

module phy_top (
    input  wire clk,
    input  wire rst_n,

    input  wire Din,         
    input  wire Sin,
    output wire Dout,        
    output wire Sout,
    
    input  wire [9:0]tx_char,      
    input  wire tx_valid,
    output wire tx_ready,
    output wire tx_done,

    output wire [9:0]rx_char,
    output wire rx_valid,
    output wire parity_err,
    input  wire rx_en,

    input  wire arm_errwait,
    input  wire arm_disc,
    output wire errwait_done,
    output wire disc_done,
    output wire tick
);

wire Din_sync;
wire Sin_sync;

phy_cdc_sync #(.WIDTH(1)) u_cdc_din (
    .clk   (clk),
    .rst_n (rst_n),
    .din   (Din),
    .dout  (Din_sync)
);

phy_cdc_sync #(.WIDTH(1)) u_cdc_sin (
    .clk   (clk),
    .rst_n (rst_n),
    .din   (Sin),
    .dout  (Sin_sync)
);
wire [9:0] ds_rx_char;
wire ds_rx_valid;
wire disc_refresh;


cd_ds u_cd_ds (
    .clk         (clk),
    .rst_n       (rst_n),
    .rx_en       (rx_en),
    .din         (Din_sync),
    .sin         (Sin_sync),
    .rx_char     (ds_rx_char),
    .rx_valid    (ds_rx_valid),
    .disc_refresh(disc_refresh)
);
wire [9:0] par_rx_char_out;
wire par_tx_valid_out;
wire par_rx_valid_out;
wire par_parity_err;

wire [9:0] par_tx_char_out;


cd_parity u_parity_rx (
    .clk        (clk),
    .rst_n      (rst_n),
    .mode       (1'b1), 
    .char_in    (ds_rx_char),
    .valid_in   (ds_rx_valid),
    .char_out   (par_rx_char_out),
    .valid_out  (par_rx_valid_out),
    .parity_err (par_parity_err)
);

cd_parity u_parity_tx (
    .clk        (clk),
    .rst_n      (rst_n),
    .mode       (1'b0),
    .char_in    (tx_char),
    .valid_in   (tx_valid),
    .char_out   (par_tx_char_out),
    .valid_out  (par_tx_valid_out), // unused
    .parity_err ()  // unused 
);



cd_tx u_cd_tx (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_char  (par_tx_char_out),
    .tx_valid (par_tx_valid_out),
    .tx_ready (tx_ready),
    .tx_done  (tx_done),
    .Dout     (Dout),
    .Sout     (Sout)
);

phy_timer u_phy_timer (
    .clk          (clk),
    .rst_n        (rst_n),
    .arm_errwait  (arm_errwait),
    .arm_disc     (arm_disc),
    .disc_refresh (disc_refresh),
    .tick         (tick),
    .errwait_done (errwait_done),
    .disc_done    (disc_done)
);

assign rx_valid   = par_rx_valid_out;
assign parity_err = par_parity_err;
assign rx_char    = par_rx_char_out;

endmodule
