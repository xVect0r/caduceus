// module tx_mux (
//     input clk,
//     input rstN,
//     input linkRun,
//     input linkConnecting,
//     input sendNULL,
//     input sendFCT,
//     input sendEOP,
//     input sendEEP,
//     input [7:0]ncharIn,
//     input nCharValid,
//     input txReady,
//     input txCreditOk,
//     input [9:0] tcChar,
//     input tcCharValid,

//     output reg [9:0] txChar,
//     output reg txValid,
//     output reg ncharAck,
//     output reg tcCharAck

// );

// localparam ESC = 10'b0_00000011_1 ;
// localparam FCT = 10'b0_00000000_1;
// localparam EOP = 10'b0_00000001_1;
// localparam EEP = 10'b0_00000010_1;

// wire [9:0] Nchar;
// reg NULLPhase;

// assign Nchar={1'b0,ncharIn,1'b0};

// always @(posedge clk) begin
//     if(!rstN) begin
//         txChar<=0;
//         txValid<=1'b0;
//         ncharAck<=1'b0;
//         NULLPhase<=1'b0;
//         tcCharAck<= 1'b0;

//     end
//     else begin
//         txValid<=1'b0;
//         ncharAck<=1'b0;
//         tcCharAck<= 1'b0;
//         if (txReady) begin
//             if((sendNULL || NULLPhase) && !linkRun) begin
//                 txValid<=1'b1;

//                 if(NULLPhase==1'b0) begin
//                     txChar<=ESC;
//                     NULLPhase<=1'b1;
//                 end
//                 else begin
//                     txChar<=FCT;
//                     NULLPhase<=1'b0;
//                 end
//             end
//             else if (sendFCT && !NULLPhase) begin txChar<=FCT; txValid<=1'b1; end
//             else if (tcCharValid && linkRun) begin
//                 txChar<= tcChar;
//                 txValid<= 1'b1;
//                 tcCharAck<= 1'b1;
//             end        
//             else if (sendEEP && (linkRun||linkConnecting)) begin txChar<=EEP; txValid<=1'b1; end
//             else if (sendEOP && (linkRun||linkConnecting))  begin txChar<=EOP; txValid<=1'b1; end
//             else if (linkRun && nCharValid && txCreditOk) begin
//                 txValid<=1'b1;
//                 txChar<=Nchar;
//                 ncharAck<=1'b1;
//             end
//             else txValid<=1'b0;
//         end
        
//     end
// end
    
// endmodule
// =============================================================================
//  cd_tx_mux.v — Transmit multiplexer
//
//  Fixes:
//  1. Original: NULL priority blocked standalone FCTs entirely when sendNULL=1.
//     In STARTED state (sendNULL=1, sendFCT=1) this meant only NULLs were sent,
//     gotFCT never fired, link stuck in STARTED forever.
//
//  2. Naive fix (FCT priority over NULL) broke the case where one node is still
//     in READY while the other is in STARTED — the READY node needs to see a
//     NULL to advance (gotFCT is ignored in READY state).
//
//  Final fix: In STARTED (sendNULL=1 AND sendFCT=1), interleave by alternating
//  between starting a NULL and sending a standalone FCT using a fctPending flag.
//  Sequence: ESC, FCT(null-half), FCT(standalone), ESC, FCT(null-half), FCT...
//  Receiver sees: NULL, FCT, NULL, FCT... satisfying both gotNULL and gotFCT.
// =============================================================================
module tx_mux (
    input  wire        clk,
    input  wire        rstN,
    input  wire        linkRun,
    input  wire        linkConnecting,
    input  wire        sendNULL,
    input  wire        sendFCT,
    input  wire        sendEOP,
    input  wire        sendEEP,
    input  wire [7:0]  ncharIn,
    input  wire        nCharValid,
    input  wire        txReady,
    input  wire        txCreditOk,
    input  wire [9:0]  tcChar,
    input  wire        tcCharValid,

    output reg  [9:0]  txChar,
    output reg         txValid,
    output reg         ncharAck,
    output reg         tcCharAck
);

localparam ESC = 10'b0_00000011_1;
localparam FCT = 10'b0_00000000_1;
localparam EOP = 10'b0_00000001_1;
localparam EEP = 10'b0_00000010_1;

wire [9:0] Nchar = {1'b0, ncharIn, 1'b0};

reg NULLPhase;    // 1 = ESC sent, must send FCT to complete NULL
reg fctPending;   // 1 = standalone FCT due after next NULL completes

always @(posedge clk) begin
    if (!rstN) begin
        txChar     <= 10'b0;
        txValid    <= 1'b0;
        ncharAck   <= 1'b0;
        tcCharAck  <= 1'b0;
        NULLPhase  <= 1'b0;
        fctPending <= 1'b0;
    end else begin
        txValid   <= 1'b0;
        ncharAck  <= 1'b0;
        tcCharAck <= 1'b0;

        if (txReady) begin

            // ----------------------------------------------------------------
            // Priority 1: complete an in-progress NULL (must not be broken).
            // ----------------------------------------------------------------
            if (NULLPhase) begin
                txChar    <= FCT;           // FCT = second half of NULL
                txValid   <= 1'b1;
                NULLPhase <= 1'b0;
                // If a standalone FCT was also requested, send it next
                if (sendFCT) fctPending <= 1'b1;

            // ----------------------------------------------------------------
            // Priority 2: standalone FCT pending from a previous NULL+FCT pair,
            // or directly requested and not mid-NULL.
            // ----------------------------------------------------------------
            end else if (fctPending || (sendFCT && !sendNULL)) begin
                txChar     <= FCT;
                txValid    <= 1'b1;
                fctPending <= 1'b0;

            // ----------------------------------------------------------------
            // Priority 3: start a new NULL during startup (!linkRun).
            // In STARTED (sendNULL=1, sendFCT=1): after the NULL completes,
            // fctPending ensures a standalone FCT follows.
            // ----------------------------------------------------------------
            end else if (sendNULL && !linkRun) begin
                txChar    <= ESC;
                txValid   <= 1'b1;
                NULLPhase <= 1'b1;

            // ----------------------------------------------------------------
            // Priority 4: timecode (RUN only).
            // ----------------------------------------------------------------
            end else if (tcCharValid && linkRun) begin
                txChar    <= tcChar;
                txValid   <= 1'b1;
                tcCharAck <= 1'b1;

            // ----------------------------------------------------------------
            // Priority 5: EEP.
            // ----------------------------------------------------------------
            end else if (sendEEP && (linkRun || linkConnecting)) begin
                txChar  <= EEP;
                txValid <= 1'b1;

            // ----------------------------------------------------------------
            // Priority 6: EOP.
            // ----------------------------------------------------------------
            end else if (sendEOP && (linkRun || linkConnecting)) begin
                txChar  <= EOP;
                txValid <= 1'b1;

            // ----------------------------------------------------------------
            // Priority 7: N-char data (RUN, credit available).
            // ----------------------------------------------------------------
            end else if (linkRun && nCharValid && txCreditOk) begin
                txChar   <= Nchar;
                txValid  <= 1'b1;
                ncharAck <= 1'b1;
            end

        end
    end
end

endmodule