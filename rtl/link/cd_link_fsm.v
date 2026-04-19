`include "spw_params.vh"

module link_fsm (
    input clk,
    input rstN,
    input gotNULL,
    input gotFCT,
    input gotNchar,
    input gotEOP,
    input gotEEP,
    input parityErr,
    input disconnectErr,
    input invalidCharErr,
    input creditErr,
    input txCreditOk,
    input [5:0] txCredits,
    input [5:0] rxBuffCount,
    
    output reg sendNULL,
    output reg sendFCT,
    output reg sendEOP,
    output reg sendEEP,
    output reg linkRun,
    output reg linkConnecting,
    output reg linkError
);

localparam ERROR_RESET = 3'b000 ;
localparam ERROR_WAIT = 3'b001;
localparam READY = 3'b011;
localparam STARTED = 3'b010;
localparam CONNECTING= 3'b110;
localparam RUN = 3'b100;

reg [2:0] state;
reg [2:0] stateNext;
reg [8:0] errWaitCnt;

wire anyErr = creditErr|parityErr|disconnectErr|invalidCharErr;

//always @(posedge clk) begin
//    if(!rstN) begin
//        errWaitCnt<=`SPW_ERRWAIT_TIMEOUT;
        
//    end
//    else begin
//    state<=stateNext;
//    if(state == ERROR_RESET|| state == ERROR_WAIT) errWaitCnt<= (errWaitCnt!=0)?(errWaitCnt-1):0;
//    if (stateNext == ERROR_RESET && state != ERROR_RESET) errWaitCnt <= `SPW_ERRWAIT_TIMEOUT;
//    else errWaitCnt<= `SPW_ERRWAIT_TIMEOUT;
    
//    end
//end

always @(posedge clk) begin
    if(!rstN) begin
        state      <= ERROR_RESET;
        errWaitCnt <= `SPW_ERRWAIT_TIMEOUT;
    end
    else begin
        state <= stateNext;
        case(state)
            ERROR_RESET: errWaitCnt <= (errWaitCnt != 0) ? (errWaitCnt - 1) : 0;
            ERROR_WAIT:  begin
                if(anyErr) errWaitCnt <= `SPW_ERRWAIT_TIMEOUT;
                else       errWaitCnt <= (errWaitCnt != 0) ? (errWaitCnt - 1) : 0;
            end
            default:     errWaitCnt <= `SPW_ERRWAIT_TIMEOUT;
        endcase
    end
end
//always @(posedge clk) begin
////    stateNext<=state;
//    sendNULL<= 1'b0;
//    sendFCT<= 1'b0;
//    sendEOP<=1'b0;
//    sendEEP<= 1'b0;
//    linkRun<= 1'b0;
//    linkConnecting<= 1'b0;
//    linkError<= 1'b0;

//    case (state)
//        ERROR_RESET: begin
//            linkError<=1'b1;     
//            if(errWaitCnt==0) begin 
//                stateNext<= ERROR_WAIT;
//            end
//            else stateNext<= ERROR_RESET;
//        end
//        ERROR_WAIT: begin
//            linkError=1'b1;
//            if(anyErr) stateNext<=ERROR_RESET;
//            else begin 
//                if(errWaitCnt==0) begin 
//                    stateNext<=READY;
//                    linkError<=1'b0;
//                end 
//                else stateNext<=ERROR_WAIT;
//            end
//        end
//        READY: begin
//            if(anyErr) stateNext<=ERROR_RESET;
//            else begin
//                sendNULL<=1'b1;
//                if(gotNULL) stateNext<=STARTED;
//                else stateNext<= READY;
//            end
//        end
//        STARTED: begin
//            if(anyErr) stateNext<=ERROR_RESET;
//            else begin
//                sendNULL<=1'b1;
//                sendFCT<=1'b1;
//                if(gotFCT) stateNext<=CONNECTING;
//                else stateNext<=STARTED;
//            end
//        end
//        CONNECTING: begin
//        if(anyErr) stateNext<=ERROR_RESET;
//        else begin
//            linkConnecting<=1'b1;
//            sendFCT<=1'b1;
//            if(gotFCT || gotNULL || gotNchar || gotEOP || gotEEP)
//                stateNext <= RUN;
//            else stateNext<=CONNECTING;
//            end
//        end
//        RUN: begin
//            if(anyErr) stateNext<=ERROR_RESET;
//            else linkRun<=1'b1;
//        end
//        default:  stateNext<=ERROR_RESET;
//    endcase
//end

always @(*) begin
    // Default outputs
    sendNULL      = 1'b0;
    sendFCT       = 1'b0;
    sendEOP       = 1'b0;
    sendEEP       = 1'b0;
    linkRun       = 1'b0;
    linkConnecting = 1'b0;
    linkError     = 1'b0;
    stateNext     = state;   // default hold

    case (state)
        ERROR_RESET: begin
            linkError = 1'b1;
            if (errWaitCnt == 0)
                stateNext = ERROR_WAIT;
            else
                stateNext = ERROR_RESET;
        end
        ERROR_WAIT: begin
            linkError = 1'b1;
            if (anyErr)
                stateNext = ERROR_RESET;
            else if (errWaitCnt == 0)
                stateNext = READY;
            else
                stateNext = ERROR_WAIT;
        end
        READY: begin
            if (anyErr)
                stateNext = ERROR_RESET;
            else begin
                sendNULL = 1'b1;
                if (gotNULL)
                    stateNext = STARTED;
                else
                    stateNext = READY;
            end
        end
        STARTED: begin
            if (anyErr)
                stateNext = ERROR_RESET;
            else begin
                sendNULL = 1'b1;
                sendFCT  = 1'b1;
                if (gotFCT)
                    stateNext = CONNECTING;
                else
                    stateNext = STARTED;
            end
        end
        CONNECTING: begin
            if (anyErr)
                stateNext = ERROR_RESET;
            else begin
                linkConnecting = 1'b1;
                sendFCT        = 1'b1;
                if (gotFCT || gotNULL || gotNchar || gotEOP || gotEEP)
                    stateNext = RUN;
                else
                    stateNext = CONNECTING;
            end
        end
        RUN: begin
            if (anyErr)
                stateNext = ERROR_RESET;
            else
                linkRun = 1'b1;
        end
        default: stateNext = ERROR_RESET;
    endcase
end


    
endmodule