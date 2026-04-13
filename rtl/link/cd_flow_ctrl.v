module flow_ctrl (
    input clk,
    input rstN,
    input linkRun ,
    input rxFCT,
    input txNcharSent,
    input rxNcharRcvd,
    input rxBuffReady,

    output reg sendFCT,
    output reg txCreditOk,
    output reg creditErr,
    output reg[5:0] txCredits, 
    output reg [5:0]rxBuffCount
);
    

    

    localparam MAX_CNT = 56;
    localparam FCT_SEND_CNT_LIMIT = 8;
    // localparam integer MAX_FCT_CNT = MAX_CNT/FCT_SEND_CNT_LIMIT;

    always @(posedge clk) begin
        if (!rstN) begin
            creditErr<=1'b0;
            
            {txCredits}<=0;

        end
        else begin
            creditErr<=1'b0;
            if(rxFCT && (txCredits+FCT_SEND_CNT_LIMIT>MAX_CNT)) creditErr<=1'b1;
            else if(rxFCT) {txCredits}<={txCredits}+FCT_SEND_CNT_LIMIT;
            else if (txNcharSent && txCredits>0) {txCredits} <= {txCredits}-1;
        end
    end

    always @(posedge clk) begin
        if(!rstN) begin
            sendFCT<=0;
            rxBuffCount<=0;

        end
        else begin
            sendFCT<=1'b0;
            if(rxNcharRcvd) rxBuffCount<=rxBuffCount+1;
            if(rxBuffCount==FCT_SEND_CNT_LIMIT-1) begin
                sendFCT<=1'b1;
                {rxBuffCount}<=0;
            end
            else if(rxBuffReady && rxBuffCount==0 && linkRun) begin
                sendFCT<=1'b1;
            end
        end
    end
    always @(posedge clk) begin
        if(!rstN) txCreditOk<=1'b0;
        else txCreditOk <= (txCredits>0) && linkRun;
        
    end


endmodule