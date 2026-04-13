module tx_mux (
    input clk,
    input rstN,
    input linkRun,
    input linkConnecting,
    input sendNULL,
    input sendFCT,
    input sendEOP,
    input sendEEP,
    input [7:0]ncharIn,
    input nCharValid,
    input txReady,
    input txCreditOk,
    input [9:0] tcChar,
    input tcCharValid,

    output reg [9:0] txChar,
    output reg txValid,
    output reg ncharAck,
    output reg tcCharAck

);

localparam ESC = 10'b0_00000011_1 ;
localparam FCT = 10'b0_00000000_1;
localparam EOP = 10'b0_00000001_1;
localparam EEP = 10'b0_00000010_1;

wire [9:0] Nchar;
reg NULLPhase;

assign Nchar={1'b0,ncharIn,1'b0};

always @(posedge clk) begin
    if(!rstN) begin
        txChar<=0;
        txValid<=1'b0;
        ncharAck<=1'b0;
        NULLPhase<=1'b0;
        tcCharAck<= 1'b0;

    end
    else begin
        txValid<=1'b0;
        ncharAck<=1'b0;
        tcCharAck<= 1'b0;
        if (txReady) begin
            if((sendNULL || NULLPhase) && !linkRun) begin
                txValid<=1'b1;

                if(NULLPhase==1'b0) begin
                    txChar<=ESC;
                    NULLPhase<=1'b1;
                end
                else begin
                    txChar<=FCT;
                    NULLPhase<=1'b0;
                end
            end
            else if (sendFCT) begin txChar<=FCT; txValid<=1'b1; end
            else if (tcCharValid && linkRun) begin
                txChar<= tcChar;
                txValid<= 1'b1;
                tcCharAck<= 1'b1;
            end        
            else if (sendEEP && (linkRun||linkConnecting)) begin txChar<=EEP; txValid<=1'b1; end
            else if (sendEOP && (linkRun||linkConnecting))  begin txChar<=EOP; txValid<=1'b1; end
            else if (linkRun && nCharValid && txCreditOk) begin
                txValid<=1'b1;
                txChar<=Nchar;
                ncharAck<=1'b1;
            end
            else txValid<=1'b0;
        end
        
    end
end
    
endmodule