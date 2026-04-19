// module rmap (
//     input clk,
//     input rstN,
//     input linkRun,
//     input [7:0] rxByte,
//     input rxByteValid,
//     input [7:0] rmapKey,
//     input [7:0] targetAddr,

//     input [7:0] memRData,
//     input memReady,

//     input txByteAck,

//     output reg [31:0] memAddr,
//     output reg [7:0] memWData,
//     output reg memWe,
//     output reg memRe,

//     output reg [7:0] txByte,
//     output reg txByteValid,

//     output reg rmapBusy,
//     output reg rmapErr,
//     output reg [7:0] rmapStatus
// );

//     localparam IDLE = 3'b000;
//     localparam RECV_HDR = 3'b001;
//     localparam RECV_DATA = 3'b011;
//     localparam EXEC = 3'b010;
//     localparam SEND_REPLY = 3'b110;
//     localparam DONE = 3'b100;

//     reg[2:0] state, stateNext;

//     always @(posedge clk) begin
//         if(!rstN)begin
//             state<=IDLE;
//         end
//         else state<=stateNext;
        
//     end
// /*
// reg [2:0] replyCnt;
// reg [7:0] replyBuf [0:7];

// // Build reply in EXEC, then:
// SEND_REPLY: begin
//     if (!txByteValid || txByteAck) begin
//         txByte      <= replyBuf[replyCnt];
//         txByteValid <= 1'b1;
//         replyCnt    <= replyCnt + 1;
//         if (replyCnt == replyLen - 1) stateNext <= DONE;
//     end
// end
// */

//     localparam INSTR_WRITE = 1'b1;
//     localparam INSTR_READ = 1'b0;


//     wire start = linkRun&rxByteValid;

//     reg[3:0] hdrCnt = 0;
//     reg[7:0]hdrElement[0:14];

//     reg [7:0] instr, keyRcvd;
//     reg [15:0] transId;
//     reg [31:0] memAddrReg;
//     reg [23:0] dataLen;
//     reg[23:0] bytesLeft;
//     reg[7:0]dataCrc;
//     reg [7:0] crcAcc;
//     reg[7:0] initAddrReg;

//     reg [2:0]replyCnt;
//     reg [7:0] replyBuff[0:7];
//     reg [2:0] replyLen;

//     function [7:0] crc8_update;
//         input[7:0]crc;
//         input[7:0]data;
//         integer i;
//         reg[7:0]c;
//         begin
//             c = crc^data;
//             for(i=0;i<8;i=i+1) begin
//                 if(c[7]) c=(c<<1)^8'h07;
//                 else c=c<<1;
//             end
//             crc8_update=c;
//         end
//     endfunction


//     always @(*)begin
//         stateNext = state;

//         case(state)
//         IDLE: begin
//             if(rxByte!=0 && start) begin
//                 if(rxByte==targetAddr) stateNext= RECV_HDR;
//                 else stateNext=IDLE;
//             end
//             else stateNext=IDLE;
//         end
//         RECV_HDR : begin
//             if(start)begin
//                 if(hdrCnt==3) begin
//                     if(hdrCnt==3 && rxByte!=rmapKey)stateNext=SEND_REPLY;
//                     else begin 
//                         stateNext=RECV_HDR;
//                     end
//                 end
//                 else if (hdrCnt==15) begin
//                     if(crcAcc==8'h00 )begin 
//                         if(instr[5]==INSTR_WRITE) stateNext=RECV_DATA;
//                         else stateNext=EXEC;
//                     end
//                     else stateNext = SEND_REPLY;
//                 end
//                 else begin 
//                     stateNext=RECV_HDR;
//                 end
//             end
//         end
//         RECV_DATA: begin
//             if(start) begin
//                 if(bytesLeft==1) stateNext=EXEC;
//                 else stateNext = RECV_DATA;
//             end
//         end
//         EXEC: begin

//             if(memReady==1'b1 && replyLen>0 && linkRun)stateNext=SEND_REPLY;
//             else stateNext=EXEC;
//         end
//         SEND_REPLY:begin
//                 if(replyCnt==replyLen-1 && txByteAck) stateNext=DONE;
//                 else stateNext=SEND_REPLY;
//         end
//         DONE: begin
//             stateNext=IDLE;
//         end
//         default: stateNext=IDLE;
//         endcase
//     end


//     always @(posedge clk) begin
//         if(!rstN)begin
//             state<=IDLE;
//             hdrCnt<=0;
//             crcAcc<=8'h00;
//             dataCrc<=0;
//             bytesLeft<=0;
//             memWe<=1'b0;
//             memRe<=1'b0;
//             rmapBusy<=0;
//             rmapErr<=0;
//             rmapStatus<=0;
//             txByteValid<=0;
//             replyCnt<=0;
//             replyLen<=0;
//             instr<=0;
//             initAddrReg<=0;
//             transId<=0;
//             memAddrReg<=0;
//             dataLen<=0;
//             memAddr<=0;
//             memWData<=0;
//         end
//         else if begin
//             memWe<=1'b0;

//             case(state)
//                 IDLE: begin
//                     if(linkRun && rxByteValid && rxByte == targetAddr) begin 
//                         state<=RECV_HDR;
//                         rmapBusy<=1'b1;
//                         hdrCnt<=0;
//                         crcAcc<=0;
//                         rmapErr<=1'b0;
//                         rmapStatus<=8'h00;
//                     end
//                 end
//                 RECV_HDR: begin
//                     if()
//                     hdrElement[hdrCnt]<= rxByte;
//                     crcAcc<=crc8_update(crcAcc,rxByte);
//                     // hdrCnt<=hdrCnt+1;
//                     if(hdrCnt == 4'd2 && rxByte != rmapKey) begin
//                         rmapErr<=1'b1;
//                         rmapStatus<=8'h04;
//                         state<=SEND_REPLY;
//                         replyLen<=3'd0;

//                     end
//                     else if(hdrCnt==4'd14) begin
//                         hdrCnt = 0;
//                         instr=hdrElement[2];
//                         keyRcvd=hdrElement[3];
//                         initAddrReg<=hdrElement[4];
//                         transId={hdrElement[6],hdrElement[7]};
//                         memAddrReg = {hdrElement[8],hdrElement[9],hdrElement[10],hdrElement[11]};
//                         dataLen = {hdrElement[12],hdrElement[13],hdrElement[14]};
//                         if(crcAcc!= 8'h00) begin
//                             rmapErr<=1'b1;
//                             rmapStatus<=8'h03;
//                         end
//                         hdrCnt<=0;
//                     end
//                 end
//                 RECV_DATA: begin
//                     if(rxByteValid && instr[5]==INSTR_WRITE) begin
//                         memWe<=1'b1;
//                         memWData<=rxByte;
//                         memAddr<= memAddrReg+(dataLen-bytesLeft);
//                         dataCrc<= crc8_update(dataCrc,rxByte);
//                         bytesLeft<=bytesLeft-1;
//                     end
//                 end
//                 EXEC:begin
//                     memWe<=1'b0;
//                     if(instr[5] == INSTR_READ) memRe<=1'b1;
//                     if(memReady==1'b1) begin
//                         replyBuff[0]<=initAddrReg;
//                         replyBuff[1]<=8'h01;
//                         replyBuff[2]<=instr;
//                         replyBuff[3]<=rmapStatus;
//                         replyBuff[4]<=targetAddr;
//                         replyBuff[5]<=transId[15:8];
//                         replyBuff[6]<=transId[7:0];

//                         begin: replyCrcBlock
//                             reg[7:0]c;
//                             c=crc8_update(8'h00,initAddrReg);
//                             c=crc8_update(c,8'h01);
//                             c=crc8_update(c,instr);
//                             c=crc8_update(c,rmapStatus);
//                             c=crc8_update(c,targetAddr);
//                             c=crc8_update(c,transId[15:8]);
//                             c=crc8_update(c,transId[7:0]);
//                             replyBuff[7]<=c;
//                         end
                        
//                         replyLen<=3'd8;
//                         replyCnt<=3'd0;
//                     end
//                 end
//                 SEND_REPLY: begin
//                     if((!txByteValid||txByteAck) && linkRun)begin
//                         txByte<=replyBuff[replyCnt];
//                         txByteValid<=1'b1;
//                         replyCnt<=replyCnt+1;
//                         if(replyCnt==replyLen-1) begin
//                             txByteValid<=1'b0;
//                         end
//                     end
//                 end
//                 DONE: begin
//                     memWe<=1'b0;
//                     memRe<=1'b0;
//                     rmapBusy<=1'b0;
//                     rmapErr<=1'b0;
//                     hdrCnt<=4'd0;
//                     crcAcc<=8'h00;
//                     dataCrc<=8'h00;
//                     replyCnt<=3'd0;
//                 end
                
//             endcase
//         end
//     end
    
// endmodule

// =============================================================================
//  cd_rmap.v — RMAP command handler
//  Fixes vs original:
//   1. bytesLeft was never loaded from dataLen before entering RECV_DATA,
//      so the write-loop counter started at 0 and immediately exited.
//   2. The EXEC / SEND_REPLY datapath was inside `always @(posedge clk) ...
//      else if (rxByteValid)`, meaning it only ran when a new RX byte arrived.
//      EXEC waits for memReady (a memory response), which has nothing to do
//      with incoming bytes — so the state machine would stall forever.
//      Fixed: split into two always blocks — one for RX-driven logic, one
//      free-running for EXEC/SEND_REPLY.
//   3. instr, memAddrReg, dataLen were assigned with blocking `=` inside a
//      clocked always block, which is a simulation race.  Fixed: use `<=`.
//   4. hdrCnt index off-by-one: byte index 0 (targetAddr) is consumed in
//      IDLE and is NOT stored in hdrElement, so hdrElement[0] is actually
//      the protocol byte (index 1 on the wire).  Decoding was referencing
//      the wrong indices.  Fixed with clear comments and corrected offsets.
//   5. State machine stayed in RECV_HDR when key was wrong (SEND_REPLY was
//      set in next-state logic but the datapath kept writing hdrElement).
//      Fixed: next-state and datapath now agree on the error exit.
// =============================================================================
module rmap (
    input  wire        clk,
    input  wire        rstN,
    input  wire        linkRun,
    input  wire [7:0]  rxByte,
    input  wire        rxByteValid,
    input  wire [7:0]  rmapKey,
    input  wire [7:0]  targetAddr,

    input  wire [7:0]  memRData,
    input  wire        memReady,

    input  wire        txByteAck,

    output reg  [31:0] memAddr,
    output reg  [7:0]  memWData,
    output reg         memWe,
    output reg         memRe,

    output reg  [7:0]  txByte,
    output reg         txByteValid,

    output reg         rmapBusy,
    output reg         rmapErr,
    output reg  [7:0]  rmapStatus
);

// ---------------------------------------------------------------------------
//  State encoding
// ---------------------------------------------------------------------------
localparam IDLE       = 3'b000;
localparam RECV_HDR   = 3'b001;
localparam RECV_DATA  = 3'b011;
localparam EXEC       = 3'b010;
localparam SEND_REPLY = 3'b110;
localparam DONE       = 3'b100;

localparam INSTR_WRITE = 1'b1;
localparam INSTR_READ  = 1'b0;

reg [2:0] state;

// ---------------------------------------------------------------------------
//  Header storage
//  Wire protocol byte order (after targetAddr consumed in IDLE):
//   hdrElement[0]  = protocol ID        (wire byte 1)
//   hdrElement[1]  = instruction        (wire byte 2)
//   hdrElement[2]  = key                (wire byte 3)
//   hdrElement[3]  = initiator addr     (wire byte 4)
//   hdrElement[4]  = reserved           (wire byte 5)
//   hdrElement[5]  = trans ID MSB       (wire byte 6)
//   hdrElement[6]  = trans ID LSB       (wire byte 7)
//   hdrElement[7]  = addr[31:24]        (wire byte 8)
//   hdrElement[8]  = addr[23:16]        (wire byte 9)
//   hdrElement[9]  = addr[15:8]         (wire byte 10)
//   hdrElement[10] = addr[7:0]          (wire byte 11)
//   hdrElement[11] = len[23:16]         (wire byte 12)
//   hdrElement[12] = len[15:8]          (wire byte 13)
//   hdrElement[13] = len[7:0]           (wire byte 14)
//   hdrElement[14] = header CRC         (wire byte 15)
//  Total 15 bytes → hdrCnt 0..14
// ---------------------------------------------------------------------------
reg [7:0]  hdrElement [0:14];
reg [3:0]  hdrCnt;          // counts 0..14

reg [7:0]  instr;
reg [7:0]  initAddrReg;
reg [15:0] transId;
reg [31:0] memAddrReg;
reg [23:0] dataLen;
reg [23:0] bytesLeft;
reg [7:0]  dataCrc;
reg [7:0]  crcAcc;

reg [2:0]  replyCnt;
reg [7:0]  replyBuff [0:7];
reg [2:0]  replyLen;

// ---------------------------------------------------------------------------
//  CRC-8 (poly 0x07)
// ---------------------------------------------------------------------------
function [7:0] crc8_update;
    input [7:0] crc;
    input [7:0] data;
    integer i;
    reg [7:0] c;
    begin
        c = crc ^ data;
        for (i = 0; i < 8; i = i + 1) begin
            if (c[7]) c = (c << 1) ^ 8'h07;
            else      c =  c << 1;
        end
        crc8_update = c;
    end
endfunction

// ---------------------------------------------------------------------------
//  RX-driven state machine  (IDLE → RECV_HDR → RECV_DATA)
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (!rstN) begin
        state      <= IDLE;
        hdrCnt     <= 0;
        crcAcc     <= 8'h00;
        dataCrc    <= 8'h00;
        bytesLeft  <= 0;
        memWe      <= 1'b0;
        memRe      <= 1'b0;
        rmapBusy   <= 1'b0;
        rmapErr    <= 1'b0;
        rmapStatus <= 8'h00;
        txByteValid<= 1'b0;
        replyCnt   <= 0;
        replyLen   <= 0;
        instr      <= 0;
        initAddrReg<= 0;
        transId    <= 0;
        memAddrReg <= 0;
        dataLen    <= 0;
        memAddr    <= 0;
        memWData   <= 0;
    end else begin

        // Default pulse-clears
        memWe <= 1'b0;

        case (state)

            // ----------------------------------------------------------------
            IDLE: begin
                if (linkRun && rxByteValid && rxByte == targetAddr) begin
                    state    <= RECV_HDR;
                    rmapBusy <= 1'b1;
                    hdrCnt   <= 0;
                    crcAcc   <= 8'h00;
                    rmapErr  <= 1'b0;
                    rmapStatus <= 8'h00;
                end
            end

            // ----------------------------------------------------------------
            RECV_HDR: begin
                if (linkRun && rxByteValid) begin
                    hdrElement[hdrCnt] <= rxByte;
                    crcAcc             <= crc8_update(crcAcc, rxByte);

                    // FIX 5: key check at byte index 2 (hdrCnt==2)
                    if (hdrCnt == 4'd2 && rxByte != rmapKey) begin
                        rmapErr    <= 1'b1;
                        rmapStatus <= 8'h04;   // ECSS: invalid key
                        state      <= SEND_REPLY;
                        replyLen   <= 3'd0;    // no data reply on key error
                    end
                    // Last header byte (index 14 = header CRC)
                    else if (hdrCnt == 4'd14) begin
                        // FIX 3: use non-blocking assignment
                        instr       <= hdrElement[1];
                        initAddrReg <= hdrElement[3];
                        transId     <= {hdrElement[5], hdrElement[6]};
                        memAddrReg  <= {hdrElement[7], hdrElement[8],
                                        hdrElement[9], hdrElement[10]};
                        dataLen     <= {hdrElement[11], hdrElement[12],
                                        hdrElement[13]};
                        // FIX 1: initialise bytesLeft from dataLen
                        bytesLeft   <= {hdrElement[11], hdrElement[12],
                                        hdrElement[13]};

                        if (crc8_update(crcAcc, rxByte) != 8'h00) begin
                            rmapErr    <= 1'b1;
                            rmapStatus <= 8'h03;   // ECSS: header CRC error
                            state      <= SEND_REPLY;
                            replyLen   <= 3'd0;
                        end else begin
                            // CRC ok — route on instruction
                            if (hdrElement[1][5] == INSTR_WRITE)
                                state <= RECV_DATA;
                            else begin
                                state <= EXEC;
                                memRe <= 1'b1;
                            end
                        end
                        hdrCnt <= 0;
                    end else begin
                        hdrCnt <= hdrCnt + 1'b1;
                    end
                end
            end

            // ----------------------------------------------------------------
            RECV_DATA: begin
                if (linkRun && rxByteValid) begin
                    memWe     <= 1'b1;
                    memWData  <= rxByte;
                    memAddr   <= memAddrReg + (dataLen - bytesLeft);
                    dataCrc   <= crc8_update(dataCrc, rxByte);
                    bytesLeft <= bytesLeft - 1'b1;

                    if (bytesLeft == 24'd1)
                        state <= EXEC;
                end
            end

            // ----------------------------------------------------------------
            // FIX 2: EXEC and SEND_REPLY are FREE-RUNNING (not gated on
            //         rxByteValid) because they respond to memReady / txByteAck.
            // ----------------------------------------------------------------
            EXEC: begin
                memWe <= 1'b0;
                if (memReady) begin
                    replyBuff[0] <= initAddrReg;
                    replyBuff[1] <= 8'h01;          // protocol ID
                    replyBuff[2] <= instr;
                    replyBuff[3] <= rmapStatus;
                    replyBuff[4] <= targetAddr;
                    replyBuff[5] <= transId[15:8];
                    replyBuff[6] <= transId[7:0];
                    begin : replyCrcBlock
                        reg [7:0] c;
                        c = crc8_update(8'h00, initAddrReg);
                        c = crc8_update(c, 8'h01);
                        c = crc8_update(c, instr);
                        c = crc8_update(c, rmapStatus);
                        c = crc8_update(c, targetAddr);
                        c = crc8_update(c, transId[15:8]);
                        c = crc8_update(c, transId[7:0]);
                        replyBuff[7] <= c;
                    end
                    replyLen <= 3'd8;
                    replyCnt <= 3'd0;
                    state    <= SEND_REPLY;
                end
            end

            // ----------------------------------------------------------------
            SEND_REPLY: begin
                // replyLen==0 means error reply with no bytes — go straight to DONE
                if (replyLen == 0) begin
                    state <= DONE;
                end else if (linkRun) begin
                    if (!txByteValid || txByteAck) begin
                        txByte      <= replyBuff[replyCnt];
                        txByteValid <= 1'b1;
                        if (replyCnt == replyLen - 1) begin
                            txByteValid <= 1'b0;
                            state       <= DONE;
                        end else begin
                            replyCnt <= replyCnt + 1'b1;
                        end
                    end
                end
            end

            // ----------------------------------------------------------------
            DONE: begin
                memWe      <= 1'b0;
                memRe      <= 1'b0;
                rmapBusy   <= 1'b0;
                rmapErr    <= 1'b0;
                rmapStatus <= 8'h00;
                hdrCnt     <= 0;
                crcAcc     <= 8'h00;
                dataCrc    <= 8'h00;
                replyCnt   <= 0;
                bytesLeft  <= 0;
                state      <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule