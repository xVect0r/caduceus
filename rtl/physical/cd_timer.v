`include "spw_params.vh"

module phy_timer #(
    parameter integer SYS_CLK_HZ = `SPW_SYS_CLK_HZ,
    parameter integer LINK_BIT_RATE = `SPW_LINK_BIT_RATE,
    parameter integer DISC_TIMEOUT = `SPW_DISC_TIMEOUT,
    parameter integer ERRWAIT_TIMEOUT = `SPW_ERRWAIT_TIMEOUT,
    parameter integer TICK_HZ = 1_000_000
)(
    input wire clk,
    input wire rst_n,

    input wire arm_errwait,
    input wire arm_disc,
    input wire disc_refresh,

    output wire tick,
    output wire errwait_done,
    output wire disc_done
);

localparam integer PRESCALE_TC = (SYS_CLK_HZ/TICK_HZ)-1;

localparam integer ERRWAIT_TICKS = (ERRWAIT_TIMEOUT+PRESCALE_TC)/(PRESCALE_TC+1);
localparam integer DISC_TICKS = (DISC_TIMEOUT+PRESCALE_TC)/(PRESCALE_TC+1);

localparam integer MAX_TICKS = (ERRWAIT_TICKS>DISC_TICKS)?ERRWAIT_TICKS:DISC_TICKS;

localparam integer COUNT_WIDTH = $clog2(MAX_TICKS+1);
localparam integer PRESCALER_WIDTH = $clog2(PRESCALE_TC+1);

localparam IDLE_MODE = 1'b0;
localparam DISC_MODE = 1'b1;

reg mode_r;

reg [PRESCALER_WIDTH-1:0] prescale_r;
wire prescale_done = (prescale_r == {PRESCALER_WIDTH{1'b0}});

assign tick = prescale_done;

always @(posedge clk) begin
    if(!rst_n) begin
        prescale_r<=PRESCALER_WIDTH'(PRESCALE_TC);
    end
    else begin
        if(prescale_done) prescale_r<= PRESCALER_WIDTH'(PRESCALE_TC);
        else prescale_r<=prescale_r-1'b1;
    end
end

reg [COUNT_WIDTH-1:0] downcnt_r;
wire downcnt_zero = (downcnt_r=={COUNT_WIDTH{1'b0}});

reg errwait_done_r;
reg disc_done_r;

assign errwait_done = errwait_done_r;
assign disc_done = disc_done_r;

always @(posedge clk) begin
    if(!rst_n) begin
        downcnt_r<={COUNT_WIDTH{1'b0}};
        mode_r<=IDLE_MODE;
        errwait_done_r<=1'b0;
        disc_done_r<=1'b0;

    end else begin
        errwait_done_r<=1'b0;
        disc_done_r<=1'b0;
        if(arm_errwait) begin
            downcnt_r<=COUNT_WIDTH'(ERRWAIT_TICKS);
            mode_r<= IDLE_MODE;
        end else if(arm_disc) begin
            downcnt_r<= COUNT_WIDTH'(DISC_TICKS);
            mode_r<= DISC_MODE;
        end else if(prescale_done && !downcnt_zero) begin
            downcnt_r <= downcnt_r - 1'b1;
        end else if(prescale_done && downcnt_zero) begin
            case(mode_r)
                IDLE_MODE: errwait_done_r <= 1'b1;
                DISC_MODE: disc_done_r    <= 1'b1;
                default:;
            endcase
        end
    end
end


    
endmodule