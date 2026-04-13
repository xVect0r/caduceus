module rmap (
    input clk,
    input rstN,
    input linkRun,
    input [7:0] rxByte,
    input rxByteValid,
    input [7:0] rmapKey,
    input [7:0] targetAddr,

    input [7:0] memRData,
    input memReady,

    input txByteAck,

    output reg [31:0] memAddr,
    output reg [7:0] memWData,
    output reg memWe,
    output reg memRe,

    output reg [7:0] txByte,
    output reg txByteValid,

    output reg rmapBusy,
    output reg rmapErr,
    output reg [7:0] rmapStatus
);

    localparam IDLE = 3'b000;
    localparam RECV_HDR = 3'b001;
    localparam RECV_DATA = 3'b011;
    localparam EXEC = 3'b010;
    localparam SEND_REPLY = 3'b110;
    localparam DONE = 3'b100;

    reg[2:0] state, stateNext;

    always @(posedge clk) begin
        if(!rstN)begin
            state<=IDLE;
        end
        else state<=stateNext;
        
    end
/*
reg [2:0] replyCnt;
reg [7:0] replyBuf [0:7];

// Build reply in EXEC, then:
SEND_REPLY: begin
    if (!txByteValid || txByteAck) begin
        txByte      <= replyBuf[replyCnt];
        txByteValid <= 1'b1;
        replyCnt    <= replyCnt + 1;
        if (replyCnt == replyLen - 1) stateNext <= DONE;
    end
end
*/

    localparam INSTR_WRITE = 1'b1;
    localparam INSTR_READ = 1'b0;


    wire start = linkRun&rxByteValid;

    reg[3:0] hdrCnt = 0;
    reg[7:0]hdrElement[0:15];

    reg [7:0] instr, keyRcvd;
    reg [15:0] transId;
    reg [31:0] memAddrReg;
    reg [23:0] dataLen;
    reg[23:0] bytesLeft;
    reg[7:0]dataCrc;
    reg [7:0] crcAcc;
    reg[7:0] initAddrReg;

    reg [2:0]replyCnt;
    reg [7:0] replyBuff[0:7];
    reg [2:0] replyLen;

    function [7:0] crc8_update;
        input[7:0]crc;
        input[7:0]data;
        integer i;
        reg[7:0]c;
        begin
            c = crc^data;
            for(i=0;i<8;i=i+1) begin
                if(c[7]) c=(c<<1)^8'h07;
                else c=c<<1;
            end
            crc8_update=c;
        end
    endfunction


    always @(*)begin
        stateNext = state;

        case(state)
        IDLE: begin
            if(rxByte!=0 && start) begin
                if(rxByte==targetAddr) stateNext= RECV_HDR;
                else stateNext=IDLE;
            end
            else stateNext=IDLE;
        end
        RECV_HDR : begin
            if(start)begin
                if(hdrCnt==3) begin
                    if(hdrCnt==3 && rxByte!=rmapKey)stateNext=SEND_REPLY;
                    else begin 
                        stateNext=RECV_HDR;
                    end
                end
                else if (hdrCnt==15) begin
                    if(crcAcc==8'h00 )begin 
                        if(instr[5]==INSTR_WRITE) stateNext=RECV_DATA;
                        else stateNext=EXEC;
                    end
                    else stateNext = SEND_REPLY;
                end
                else begin 
                    stateNext=RECV_HDR;
                end
            end
        end
        RECV_DATA: begin
            if(start) begin
                if(bytesLeft==1) stateNext=EXEC;
                else stateNext = RECV_DATA;
            end
        end
        EXEC: begin

            if(memReady==1'b1 && replyLen>0 && linkRun)stateNext=SEND_REPLY;
            else stateNext=EXEC;
        end
        SEND_REPLY:begin
                if(replyCnt==replyLen-1 && txByteAck) stateNext=DONE;
                else stateNext=SEND_REPLY;
        end
        DONE: begin
            stateNext=IDLE;
        end
        default: stateNext=IDLE;
        endcase
    end


    always @(posedge clk) begin
        if(!rstN)begin
            hdrCnt<=0;
            crcAcc<=8'h00;
            memWe<=1'b0;
            memRe<=1'b0;
            txByteValid<=0;
            rmapBusy<=0;
            rmapStatus<=0;
            hdrCnt<=0;
            crcAcc<=0;
            dataCrc<=0;
            replyCnt<=0;
            bytesLeft<=0;
        end
        else if (rxByteValid) begin
            case(state)
                IDLE: begin
                    if(stateNext==RECV_HDR) begin 
                        rmapBusy<=1'b1;
                        hdrCnt<=0;
                        crcAcc<=0;
                    end
                end
                RECV_HDR: begin
                    hdrElement[hdrCnt]<= rxByte;
                    crcAcc<=crc8_update(crcAcc,rxByte);
                    hdrCnt<=hdrCnt+1;
                    if(hdrCnt==3 && rxByte!=rmapKey) begin
                        rmapErr<=1'b1;
                        rmapStatus<=8'h04;
                    end
                    else if(hdrCnt==15) begin
                        hdrCnt = 0;
                        instr=hdrElement[2];
                        keyRcvd=hdrElement[3];
                        initAddrReg<=hdrElement[4];
                        transId={hdrElement[6],hdrElement[7]};
                        memAddrReg = {hdrElement[8],hdrElement[9],hdrElement[10],hdrElement[11]};
                        dataLen = {hdrElement[12],hdrElement[13],hdrElement[14]};
                        if(crcAcc!= 8'h00) begin
                            rmapErr<=1'b1;
                            rmapStatus<=8'h03;
                        end
                        hdrCnt<=0;
                    end
                end
                RECV_DATA: begin
                    if(rxByteValid && instr[5]==INSTR_WRITE) begin
                        memWe<=1'b1;
                        memWData<=rxByte;
                        memAddr<= memAddrReg+(dataLen-bytesLeft);
                        dataCrc<= crc8_update(dataCrc,rxByte);
                        bytesLeft<=bytesLeft-1;
                    end
                end
                EXEC:begin
                    memWe<=1'b0;
                    if(instr[5] == INSTR_READ) memRe<=1'b1;
                    if(memReady==1'b1) begin
                        replyBuff[0]<=initAddrReg;
                        replyBuff[1]<=8'h01;
                        replyBuff[2]<=instr;
                        replyBuff[3]<=rmapStatus;
                        replyBuff[4]<=targetAddr;
                        replyBuff[5]<=transId[15:8];
                        replyBuff[6]<=transId[7:0];

                        begin: replyCrcBlock
                            reg[7:0]c;
                            c=crc8_update(8'h00,initAddrReg);
                            c=crc8_update(c,8'h01);
                            c=crc8_update(c,instr);
                            c=crc8_update(c,rmapStatus);
                            c=crc8_update(c,targetAddr);
                            c=crc8_update(c,transId[15:8]);
                            c=crc8_update(c,transId[7:0]);
                            replyBuff[7]<=c;
                        end
                        
                        replyLen<=3'd8;
                        replyCnt<=3'd0;
                    end
                end
                SEND_REPLY: begin
                    if((!txByteValid||txByteAck) && linkRun)begin
                        txByte<=replyBuff[replyCnt];
                        txByteValid<=1'b1;
                        replyCnt<=replyCnt+1;
                        if(replyCnt==replyLen-1) begin
                            txByteValid<=1'b0;
                        end
                    end
                end
                DONE: begin
                    memWe<=1'b0;
                    memRe<=1'b0;
                    rmapBusy<=1'b0;
                    rmapErr<=1'b0;
                    hdrCnt<=4'd0;
                    crcAcc<=8'h00;
                    dataCrc<=8'h00;
                    replyCnt<=3'd0;
                end
                
            endcase
        end
    end
    
endmodule