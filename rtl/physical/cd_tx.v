`timescale 1ns/1ps
`include "spw_params.vh"


module cd_tx #(
    parameter PACKET_LENGTH = 10
) (
    input wire clk,
    input wire rst_n,
    input wire[9:0] tx_char,
    input wire tx_valid,

    output wire tx_ready,
    output wire tx_done,
    output wire Dout,
    output wire Sout
);

localparam integer CLK_REG_COUNT = `SPW_CLKS_PER_BIT ;
localparam MODE_IDLE = 2'b00;
localparam MODE_TRANSMIT = 2'b01;
localparam MODE_DONE = 2'b10;

reg[1:0] stateCurr, stateNext;
reg txStart;
reg txDoneReg;
reg outReg;

reg nextBit;
reg [$clog2(CLK_REG_COUNT)-1:0] clkCount;

always @(posedge clk ) begin
    if(!rst_n) begin
        clkCount<=CLK_REG_COUNT-1;
        nextBit<=0;
    end
    else begin
        if(clkCount == 0) begin
            clkCount<=CLK_REG_COUNT-1;
            nextBit<=1'b1;
        end
        else begin
            clkCount<= {clkCount}-1'b1;
            nextBit<=0;
        end
    end
end


reg [$clog2(PACKET_LENGTH)-1:0] packetCount ;
always@(posedge clk) begin
    if(!rst_n) begin
        packetCount<=0;
    end
    else if (nextBit && stateCurr == MODE_TRANSMIT) begin
        if(packetCount == PACKET_LENGTH-1) packetCount<= 0; 
        else packetCount <= {packetCount}+1'b1;
        
    end
end



always@(posedge clk) begin
    if(!rst_n) stateCurr<= MODE_IDLE;
    else begin
        stateCurr <= stateNext;
        txStart <= 1'b0;
        txDoneReg<= 1'b0;
        case (stateCurr)
            MODE_IDLE: begin
                if(tx_valid) begin
                    stateNext<= MODE_TRANSMIT;
                    txStart <=1'b1;
                end
            end 
            MODE_TRANSMIT: begin
                if(packetCount == PACKET_LENGTH-1) begin
                    stateNext<= MODE_DONE;
                    txDoneReg<=1'b1;
                end

            end
            MODE_DONE: begin
                stateNext<= MODE_IDLE;
            end
            default: stateNext<= MODE_IDLE;
        endcase
    end
end

reg [PACKET_LENGTH-1:0] inDataReg;
reg outDataReg;
wire currBit = outDataReg;

always@(posedge clk) begin
    if(!rst_n)begin
            outDataReg <= 0;
            inDataReg <= tx_char;
        end
    else begin
        if(nextBit) begin
            
            if(stateCurr == MODE_IDLE && tx_valid) begin 
                outDataReg <= inDataReg[packetCount];
                inDataReg <= tx_char;
            end 
            else begin
                outDataReg <= inDataReg[packetCount];
            end
        
        end
    end
end

assign tx_ready = (stateCurr==MODE_IDLE);
assign tx_done = txDoneReg;

reg dOutReg, sOutReg;
always@(posedge clk) begin
    if(!rst_n) begin
        dOutReg<=1'b0;
        sOutReg<=1'b0;
    end
    else if (nextBit && stateCurr==MODE_TRANSMIT) begin
        if (currBit==1'b0) begin
            dOutReg<=~dOutReg;
        end
        else sOutReg <= ~sOutReg;
    end
end

assign Dout = dOutReg;
assign Sout = sOutReg;
endmodule