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

localparam integer PRESCALE_TOTAL_COUNT = (SYS_CLK_HZ/TICK_HZ)-1;

localparam integer ERRWAIT_TICKS = (ERRWAIT_TIMEOUT+PRESCALE_TOTAL_COUNT)/(PRESCALE_TOTAL_COUNT+1);
localparam integer DISC_TICKS = (DISC_TIMEOUT+PRESCALE_TOTAL_COUNT)/(PRESCALE_TOTAL_COUNT+1);

localparam integer MAX_TICKS = (ERRWAIT_TICKS>DISC_TICKS)?ERRWAIT_TICKS:DISC_TICKS;

localparam integer COUNT_WIDTH = $clog2(MAX_TICKS+1);
localparam integer PRESCALER_WIDTH = $clog2(PRESCALE_TOTAL_COUNT+1);

localparam MODE_IDLE = 1'b0;
localparam MODE_DISC = 1'b1;


reg modeReg ;
reg [PRESCALER_WIDTH-1:0] prescaleReg;
wire prescaleDone = (prescaleReg == 0);
assign tick = prescaleDone;

always@(posedge clk) begin
    if(!rst_n) begin
        prescaleReg <= PRESCALE_TOTAL_COUNT[PRESCALER_WIDTH-1:0];
    end
    else begin
        if(prescaleDone) prescaleReg <= PRESCALE_TOTAL_COUNT[PRESCALER_WIDTH-1:0];
        else begin
            prescaleReg<= prescaleReg-1'b1;
        end
    end
end

reg [COUNT_WIDTH-1:0] downCntReg;
wire downCountZero = (downCntReg == 0);

reg errWaitDoneReg, discDoneReg;
assign errwait_done = errWaitDoneReg;
assign disc_done = discDoneReg;

always@(posedge clk) begin
    if(!rst_n) begin
        downCntReg<=0;
        errWaitDoneReg<=1'b0;
        discDoneReg<=1'b0;
        modeReg<=MODE_IDLE;
    end
    else begin
        errWaitDoneReg<=1'b0;
        discDoneReg<=1'b0;

        if(arm_errwait) begin
            downCntReg<= ERRWAIT_TICKS[COUNT_WIDTH-1:0]; 
            modeReg <= MODE_IDLE;
        end
        else if (arm_disc) begin
            downCntReg <= DISC_TICKS[COUNT_WIDTH-1:0];  
            modeReg<= MODE_DISC;
        end
        else if (disc_refresh && modeReg == MODE_DISC) begin
            downCntReg<= DISC_TICKS[COUNT_WIDTH-1:0];
        end
        else if (prescaleDone && !downCountZero) begin
            downCntReg<= downCntReg-1'b1;
        end
        else if(prescaleDone && downCountZero) begin
            case(modeReg)
                MODE_IDLE: errWaitDoneReg<=1'b1;
                MODE_DISC: discDoneReg<=1'b1;
                default:;
            endcase
        end
    end
end



    
endmodule