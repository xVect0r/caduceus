// module timecode_generator(
//     input clk,
//     input rstN,
//     input linkRun,
//     input tcSend,
//     input [7:0] tcTxValue,
//     input isTimecode,
//     input [7:0] timeData,
//     input tcCharAck,

//     output reg tcTxReady,
//     output reg tcRxValid,
//     output reg [7:0] tcRxValue,
//     output reg[9:0] tcChar,
//     output reg tcCharValid
    

// );

// localparam ESC = 10'b0_00000011_1 ;
// localparam IDLE= 2'b00;
// localparam SEND_ESC=2'b01;
// localparam SEND_TC = 2'b11;

// reg [1:0] state, stateNext;

// reg [7:0] valueCopyReg;
// always@(posedge clk) begin
//     if(!rstN) begin
//         tcTxReady<=0;
//         tcRxValid<=0;
//         tcChar<=0;
//         tcCharValid<=0;
//         state<=IDLE;
//         stateNext<=IDLE;
//     end
//     else begin
//         state<=stateNext;
//         case(state)
//         IDLE: begin
//             tcTxReady<=1'b1;
//             tcCharValid<=0;
//             if(tcSend) begin 
//                 stateNext<=SEND_ESC;
//                 valueCopyReg<=tcTxValue;
//             end
//             else stateNext<=IDLE;

//         end
//         SEND_ESC: begin
//             tcChar<=ESC;
//             tcCharValid<=1'b1;
//             if(tcCharAck) stateNext<=SEND_TC;
//             else stateNext<=SEND_ESC;

//         end
//         SEND_TC: begin
//             tcCharValid<=1'b1;
//             tcChar<= {1'b0, valueCopyReg,1'b1};
//             if(tcCharAck) stateNext<= IDLE;
//             else stateNext<=SEND_TC;
//         end 
//         default: stateNext<=IDLE;
//         endcase
//     end
// end
// always @(posedge clk) begin
//     if(!rstN) begin
//         tcRxValid<=0;
//         tcRxValue<=0;
//     end
//     else begin
//         tcRxValid<=isTimecode && linkRun;
//         if(isTimecode && linkRun) tcRxValue<=timeData;
//     end
// end
// endmodule

// =============================================================================
//  cd_timecode.v — Timecode TX/RX
//  Fix vs original:
//   1. tcTxReady was not cleared when leaving IDLE, so it remained high
//      while ESC and TC characters were being sent, allowing the user to
//      queue another timecode mid-transmission.
// =============================================================================
module timecode_generator (
    input  wire        clk,
    input  wire        rstN,
    input  wire        linkRun,
    input  wire        tcSend,
    input  wire [7:0]  tcTxValue,
    input  wire        isTimecode,
    input  wire [7:0]  timeData,
    input  wire        tcCharAck,

    output reg         tcTxReady,
    output reg         tcRxValid,
    output reg  [7:0]  tcRxValue,
    output reg  [9:0]  tcChar,
    output reg         tcCharValid
);

localparam ESC      = 10'b0_00000011_1;
localparam IDLE     = 2'b00;
localparam SEND_ESC = 2'b01;
localparam SEND_TC  = 2'b11;

reg [1:0] state;
reg [7:0] valueCopyReg;

// ---------------------------------------------------------------------------
//  TX state machine
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (!rstN) begin
        tcTxReady   <= 1'b0;
        tcChar      <= 10'b0;
        tcCharValid <= 1'b0;
        state       <= IDLE;
        valueCopyReg<= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                tcTxReady   <= 1'b1;   // ready to accept a new timecode
                tcCharValid <= 1'b0;
                if (tcSend && linkRun) begin
                    valueCopyReg <= tcTxValue;
                    tcTxReady    <= 1'b0;   // FIX 1: deassert immediately
                    state        <= SEND_ESC;
                end
            end

            SEND_ESC: begin
                tcTxReady   <= 1'b0;   // FIX 1: keep deasserted
                tcChar      <= ESC;
                tcCharValid <= 1'b1;
                if (tcCharAck)
                    state <= SEND_TC;
            end

            SEND_TC: begin
                tcTxReady   <= 1'b0;   // FIX 1: keep deasserted
                tcChar      <= {1'b0, valueCopyReg, 1'b1};
                tcCharValid <= 1'b1;
                if (tcCharAck) begin
                    tcCharValid <= 1'b0;
                    state       <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

// ---------------------------------------------------------------------------
//  RX path — latch incoming timecode when link is running
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (!rstN) begin
        tcRxValid <= 1'b0;
        tcRxValue <= 8'h00;
    end else begin
        tcRxValid <= isTimecode && linkRun;
        if (isTimecode && linkRun)
            tcRxValue <= timeData;
    end
end

endmodule