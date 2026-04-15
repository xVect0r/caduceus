module flow_ctrl (
    input clk,
    input rstN,
    input linkRun,
    input rxFCT,
    input txNcharSent,
    input rxNcharRcvd,
    input rxBuffReady,

    output reg sendFCT,
    output reg txCreditOk,
    output reg creditErr,
    output reg [5:0] txCredits,
    output reg [5:0] rxBuffCount
);

    localparam MAX_CNT = 56;
    localparam FCT_SEND_CNT_LIMIT = 8;

    reg initial_fct_sent;

    always @(posedge clk) begin
        if (!rstN) begin
            creditErr <= 1'b0;
            txCredits <= 6'd0;
        end else begin
            creditErr <= 1'b0;
            if (rxFCT && linkRun) begin
                if ((txCredits + FCT_SEND_CNT_LIMIT) > MAX_CNT)
                    creditErr <= 1'b1;
                else
                    txCredits <= txCredits + FCT_SEND_CNT_LIMIT;
            end else if (txNcharSent && txCredits > 0 && linkRun) begin
                txCredits <= txCredits - 1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstN) begin
            sendFCT <= 1'b0;
            rxBuffCount <= 6'd0;
            initial_fct_sent <= 1'b0;
        end else begin
            sendFCT <= 1'b0;

            if (!initial_fct_sent && rxBuffReady && linkRun) begin
                sendFCT <= 1'b1;
                initial_fct_sent <= 1'b1;
            end

            if (rxNcharRcvd && linkRun) begin
                if (rxBuffCount == FCT_SEND_CNT_LIMIT - 1) begin
                    sendFCT <= 1'b1;
                    rxBuffCount <= 6'd0;
                end else begin
                    rxBuffCount <= rxBuffCount + 1;
                end
            end
        end
    end
    always @(posedge clk) begin
        if (!rstN)
            txCreditOk <= 1'b0;
        else
            txCreditOk <= (txCredits > 0) && linkRun;
    end

endmodule