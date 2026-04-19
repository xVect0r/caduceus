`include "spw_params.vh"

module  link_top(

    output [9:0] txChar,
    output txValid,
    output ncharAck,
    output linkRun,
    output linkError,
    output linkConnecting,
    output isNchar,
    output [7:0] ncharData,
    output isEOP,
    output isEEP,
    output isTimecode,
    output[7:0] timeData,
    output tcCharAck,

    input clk,
    input rstN,
    input [9:0] rxChar,
    input rxValid,
    input [7:0] ncharIn,
    input nCharValid,
    input txReady,
    input parity_err,
    input disc_done,
    input  [9:0] tcChar,
    input tcCharValid,
    input userSendEOP,
    input userSendEEP


);

wire isNULL, isFCT, isInvalidChar;


char_decode u_char_decoder_0(
    .clk(clk),
    .rstN(rstN),
    .rxChar(rxChar),
    .rxValid(rxValid),

    .isNULL(isNULL),
    .isFCT(isFCT),
    .isEOP(isEOP),
    .isEEP(isEEP),
    .isNchar(isNchar),
    .isTimecode(isTimecode),
    .isInvalidChar(isInvalidChar),
    .ncharData(ncharData),
    .timeData(timeData)
);

wire txCreditOk, creditErr;
wire [5:0]txCredits, rxBuffCount;
wire sendNULL;
wire sendFCTFsm, sendFCTFlow;
wire sendFCT = sendFCTFlow|sendFCTFsm;
wire fsmSendEOP, fsmSendEEP;
wire sendEOP = (fsmSendEOP | userSendEOP);
wire sendEEP = (fsmSendEEP | userSendEEP);

flow_ctrl u_flow_ctrl_0(
    .clk(clk),
    .rstN(rstN),
    .linkRun(linkRun),
    .rxFCT(isFCT),
    .txNcharSent(ncharAck),
    .rxNcharRcvd(isNchar),
    .rxBuffReady(1'b1),

    .sendFCT(sendFCTFlow),
    .txCreditOk(txCreditOk),
    .txCredits(txCredits),
    .rxBuffCount(rxBuffCount),
    .creditErr(creditErr) 
);


tx_mux u_tx_mux_0(
    .clk(clk),
    .rstN(rstN),
    .linkRun(linkRun),
    .linkConnecting(linkConnecting),
    .sendNULL(sendNULL),
    .sendFCT(sendFCT),
    .sendEOP(sendEOP),
    .sendEEP(sendEEP),
    .ncharIn(ncharIn),
    .nCharValid(nCharValid),
    .txReady(txReady),
    .txCreditOk(txCreditOk),
    .txChar(txChar),
    .txValid(txValid),
    .ncharAck(ncharAck),
    .tcChar(tcChar),
    .tcCharValid(tcCharValid),
    .tcCharAck(tcCharAck)

);

link_fsm u_link_fsm_0(
    .clk(clk),
    .rstN(rstN),
    .gotNULL(isNULL),
    .gotFCT(isFCT),
    .gotNchar(isNchar),
    .gotEOP(isEOP),
    .gotEEP(isEEP),
    .parityErr(parity_err),
    .disconnectErr(disc_done),
    .invalidCharErr(isInvalidChar),
    .creditErr(creditErr),
    .txCreditOk(txCreditOk),
    .txCredits(txCredits),
    .rxBuffCount(rxBuffCount),
    .sendNULL(sendNULL),
    .sendFCT(sendFCTFsm),
    .sendEOP(fsmSendEOP),
    .sendEEP(fsmSendEEP),
    .linkRun(linkRun),
    .linkConnecting(linkConnecting),
    .linkError(linkError)

);

`ifdef SIMULATION
reg [2:0] prev_state;
always @(posedge clk) begin
    prev_state <= u_link_fsm_0.state;
    // Print on every FSM state change
    if (u_link_fsm_0.state !== prev_state)
        $display("[LINK_TOP %m] t=%0t  FSM %0d->%0d  linkRun=%b linkErr=%b linkConn=%b",
                 $time, prev_state, u_link_fsm_0.state, linkRun, linkError, linkConnecting);
    // Print every time a key char is decoded
    if (isNULL)
        $display("[LINK_TOP %m] t=%0t  isNULL rxChar=%03x", $time, rxChar);
    if (isFCT)
        $display("[LINK_TOP %m] t=%0t  isFCT  rxChar=%03x", $time, rxChar);
    if (isInvalidChar)
        $display("[LINK_TOP %m] t=%0t  INVALID rxChar=%03x parity_err=%b", $time, rxChar, parity_err);
    // Print fctPending transitions
    if (u_tx_mux_0.fctPending && !$past(u_tx_mux_0.fctPending))
        $display("[LINK_TOP %m] t=%0t  fctPending SET", $time);
    if (u_tx_mux_0.txValid)
        $display("[LINK_TOP %m] t=%0t  TX txChar=%03x NULLPhase=%b fctPending=%b sendFCT=%b",
                 $time, u_tx_mux_0.txChar, u_tx_mux_0.NULLPhase,
                 u_tx_mux_0.fctPending, sendFCT);
end
`endif
    
endmodule