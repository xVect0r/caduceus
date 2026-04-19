module caduceus_top_noRout (
    input clk,
    input rstN,
//Phy layer pins
    input Din,
    input Sin,
    output Dout,
    output Sout,

//user TX
    input [7:0] txByte,
    input userTxValid,
    input txEop,
    input txEep,
    output txReady,

//user RX
    output wire [7:0] rxByte,
    output wire rxValid,
    output wire rxEop,
    output wire rxEep,

//LinkStatus
    output wire linkRun,
    output wire linkError,
    output wire linkConnecting,

//RMAP
    input [7:0] memRData,
    input memReady,
    input [7:0] rmapKey,
    input [7:0] targetAddr,
    output wire [31:0] memAddr,
    output wire [7:0] memWData,
    output wire memWe,
    output wire memRe,
    output wire [7:0] rmapStatus,
    output wire rmapErr,
    output wire rmapBusy,

//Timecode
    input tcSend,
    input [7:0] tcTxValue,
    output wire [7:0] tcRxValue,
    output wire tcTxReady,
    output wire tcRxValid


);

wire parityErr;
wire discDone;
wire [9:0] rxChar;
wire txDone;
wire [9:0] linkTxChar;
wire linkTxValid;
wire phyRxValid;

wire isNchar, isEOP, isEEP, isTimecode;
wire [7:0] ncharData, timeData;
wire ncharAck;
 
wire [9:0]tcChar;
wire tcCharValid;
wire tcCharAck;
 
wire [7:0] rmapTxByte;
wire rmapTxByteValid;
wire rmapTxByteAck;
 
wire [7:0] ncharIn= rmapTxByteValid ? rmapTxByte:txByte;
wire nCharValid = rmapTxByteValid ? 1'b1:(userTxValid & linkRun);


assign rmapTxByteAck = ncharAck & rmapTxByteValid;
reg rx_en_r;
always @(posedge clk) rx_en_r <= ~linkError;
 

phy_top u_phy_top (
    .clk(clk),
    .rst_n(rstN),


    .Din(Din),
    .Sin(Sin),
    .Dout(Dout),
    .Sout(Sout),


    .tx_char(linkTxChar),
    .tx_valid(linkTxValid),
    .tx_ready(txReady),
    .tx_done(txDone),


    .rx_char(rxChar),
    .rx_valid(phyRxValid),
    .parity_err(parityErr),
//    .rx_en(linkRun | linkConnecting),
    .rx_en(rx_en_r),
    .arm_errwait(linkError),
    .arm_disc(linkRun | linkConnecting),
    .errwait_done(),

    .disc_done(discDone),
    .tick()


);

link_top u_link_top (
    .clk(clk),
    .rstN (rstN),

    .rxChar(rxChar),
    .rxValid(phyRxValid),
    .ncharIn(ncharIn),
    .nCharValid(nCharValid),
    .txReady(txReady),
    .parity_err(parityErr),
    .disc_done(discDone),
    .txChar(linkTxChar),
    .txValid(linkTxValid),

    .ncharAck(ncharAck),
    .linkRun(linkRun),
    .linkError(linkError),
    .linkConnecting(linkConnecting),
    .isNchar(isNchar),
    .ncharData(ncharData),
    .isEOP(isEOP),
    .isEEP(isEEP),
    .isTimecode(isTimecode),
    .timeData(timeData),

    .tcChar(tcChar),
    .tcCharAck(tcCharAck),
    .tcCharValid(tcCharValid),
    .userSendEOP(txEop),
    .userSendEEP(txEep)
);

timecode_generator u_timecode (
    .clk(clk),
    .rstN(rstN),
    .linkRun(linkRun),
    .tcSend(tcSend),
    .tcTxValue(tcTxValue),
    .isTimecode(isTimecode),
    .timeData(timeData),
    .tcCharAck(tcCharAck),
    .tcTxReady(tcTxReady),
    .tcRxValid(tcRxValid),
    .tcRxValue(tcRxValue),
    .tcChar(tcChar),
    .tcCharValid(tcCharValid)
);

rmap u_rmap (

    .clk(clk),
    .rstN(rstN),
    .linkRun(linkRun),

    .rxByte(ncharData),
    .rxByteValid(isNchar & linkRun),
    .rmapKey(rmapKey),
    .targetAddr(targetAddr),
    .memRData(memRData),
    .memReady(memReady),
    .txByteAck(rmapTxByteAck),
    .memAddr(memAddr),
    .memWData(memWData),
    .memWe(memWe),
    .memRe(memRe),

    .txByte(rmapTxByte),
    .txByteValid(rmapTxByteValid),
    .rmapBusy(rmapBusy),
    .rmapErr(rmapErr),
    .rmapStatus(rmapStatus)
);

 
assign rxByte= ncharData;
assign rxValid= (isNchar & linkRun);
assign rxEop= (isEOP& linkRun);
assign rxEep=( isEEP & linkRun);
  
endmodule