`timescale 1ns/1ps
`include "spw_params.vh"
`define SIMULATION

// =============================================================================
//  caduceus — SpaceWire IP Core (ECSS-E-ST-50-12C)
//  File    : tb_caduceus_top.v
//  Purpose : Extensive RTL testbench for caduceus_top_noRout
//
//  Test suite:
//  [1]  Reset behaviour
//  [2]  Link startup — two nodes reach RUN state
//  [3]  Single N-char transfer A→B
//  [4]  Burst N-char transfer A→B (16 bytes)
//  [5]  Bidirectional simultaneous transfer
//  [6]  EOP packet termination
//  [7]  EEP error packet termination
//  [8]  Flow control — credit exhaustion and FCT replenishment
//  [9]  RMAP Write command
//  [10] RMAP Read command
//  [11] RMAP invalid key rejection
//  [12] Timecode TX/RX
//  [13] Disconnect error injection
//  [14] Parity error injection (via corrupted DS sequence)
//  [15] Link recovery after error
//
//  Topology: Node A �?→ Node B (loopback — Dout_A→Din_B, Sout_A→Sin_B etc.)
//
//  Author  : Soumyadip Roy
//  Licence : MIT
// =============================================================================

module tb_caduceus_top;

// ---------------------------------------------------------------------------
//  Parameters
// ---------------------------------------------------------------------------
localparam CLK_PERIOD    = 20;           // 50 MHz
localparam CLK_HALF      = CLK_PERIOD/2;
localparam RESET_CYCLES  = 20;
localparam LINK_TIMEOUT  = 150000;         // cycles to wait for linkRun
localparam CDC_LATENCY   = 3;
localparam CLKS_PER_BIT  = `SPW_CLKS_PER_BIT;

// RMAP config
localparam RMAP_KEY      = 8'hAB;
localparam TARGET_ADDR   = 8'hFE;
localparam TEST_MEM_ADDR = 32'h0000_1000;

// ---------------------------------------------------------------------------
//  Clock and reset
// ---------------------------------------------------------------------------
reg clk;
reg rstN;

initial clk = 0;
always #CLK_HALF clk = ~clk;

// ---------------------------------------------------------------------------
//  Node A signals
// ---------------------------------------------------------------------------
reg         a_userTxValid;
reg  [7:0]  a_txByte;
reg         a_txEop;
reg         a_txEep;
wire        a_txReady;
wire [7:0]  a_rxByte;
wire        a_rxValid;
wire        a_rxEop;
wire        a_rxEep;
wire        a_linkRun;
wire        a_linkError;
wire        a_linkConnecting;
// RMAP — node A is initiator, memory bus tied off
reg  [7:0]  a_memRData;
reg         a_memReady;
wire [31:0] a_memAddr;
wire [7:0]  a_memWData;
wire        a_memWe;
wire        a_memRe;
wire [7:0]  a_rmapStatus;
wire        a_rmapErr;
wire        a_rmapBusy;
// Timecode
reg         a_tcSend;
reg  [7:0]  a_tcTxValue;
wire        a_tcTxReady;
wire        a_tcRxValid;
wire [7:0]  a_tcRxValue;
// Physical
wire        a_Dout, a_Sout;
reg         a_Din,  a_Sin;

// ---------------------------------------------------------------------------
//  Node B signals
// ---------------------------------------------------------------------------
reg         b_userTxValid;
reg  [7:0]  b_txByte;
reg         b_txEop;
reg         b_txEep;
wire        b_txReady;
wire [7:0]  b_rxByte;
wire        b_rxValid;
wire        b_rxEop;
wire        b_rxEep;
wire        b_linkRun;
wire        b_linkError;
wire        b_linkConnecting;
// RMAP — node B is target, memory model attached
reg  [7:0]  b_memRData;
reg         b_memReady;
wire [31:0] b_memAddr;
wire [7:0]  b_memWData;
wire        b_memWe;
wire        b_memRe;
wire [7:0]  b_rmapStatus;
wire        b_rmapErr;
wire        b_rmapBusy;
// Timecode
reg         b_tcSend;
reg  [7:0]  b_tcTxValue;
wire        b_tcTxReady;
wire        b_tcRxValid;
wire [7:0]  b_tcRxValue;
// Physical
wire        b_Dout, b_Sout;
reg         b_Din,  b_Sin;

// ---------------------------------------------------------------------------
//  Loopback wiring — A outputs → B inputs, B outputs → A inputs
// ---------------------------------------------------------------------------
always @(*) begin
    b_Din = a_Dout;
    b_Sin = a_Sout;
    a_Din = b_Dout;
    a_Sin = b_Sout;
end

// ---------------------------------------------------------------------------
//  Simple memory model for Node B (RMAP target)
// ---------------------------------------------------------------------------
reg [7:0] mem [0:255];
integer mi;

always @(posedge clk) begin
    b_memReady <= 1'b0;
    if(b_memWe) begin
        mem[b_memAddr[7:0]] <= b_memWData;
        b_memReady <= 1'b1;
    end
    if(b_memRe) begin
        b_memRData <= mem[b_memAddr[7:0]];
        b_memReady <= 1'b1;
    end
end

// ---------------------------------------------------------------------------
//  DUT instantiation — Node A
// ---------------------------------------------------------------------------
caduceus_top_noRout u_node_a (
    .clk             (clk),
    .rstN            (rstN),
    .Din             (a_Din),
    .Sin             (a_Sin),
    .Dout            (a_Dout),
    .Sout            (a_Sout),
    .txByte          (a_txByte),
    .userTxValid     (a_userTxValid),
    .txEop           (a_txEop),
    .txEep           (a_txEep),
    .txReady         (a_txReady),
    .rxByte          (a_rxByte),
    .rxValid         (a_rxValid),
    .rxEop           (a_rxEop),
    .rxEep           (a_rxEep),
    .linkRun         (a_linkRun),
    .linkError       (a_linkError),
    .linkConnecting  (a_linkConnecting),
    .memRData        (a_memRData),
    .memReady        (a_memReady),
    .rmapKey         (RMAP_KEY),
    .targetAddr      (TARGET_ADDR),
    .memAddr         (a_memAddr),
    .memWData        (a_memWData),
    .memWe           (a_memWe),
    .memRe           (a_memRe),
    .rmapStatus      (a_rmapStatus),
    .rmapErr         (a_rmapErr),
    .rmapBusy        (a_rmapBusy),
    .tcSend          (a_tcSend),
    .tcTxValue       (a_tcTxValue),
    .tcTxReady       (a_tcTxReady),
    .tcRxValid       (a_tcRxValid),
    .tcRxValue       (a_tcRxValue)
);

// ---------------------------------------------------------------------------
//  DUT instantiation — Node B
// ---------------------------------------------------------------------------
caduceus_top_noRout u_node_b (
    .clk             (clk),
    .rstN            (rstN),
    .Din             (b_Din),
    .Sin             (b_Sin),
    .Dout            (b_Dout),
    .Sout            (b_Sout),
    .txByte          (b_txByte),
    .userTxValid     (b_userTxValid),
    .txEop           (b_txEop),
    .txEep           (b_txEep),
    .txReady         (b_txReady),
    .rxByte          (b_rxByte),
    .rxValid         (b_rxValid),
    .rxEop           (b_rxEop),
    .rxEep           (b_rxEep),
    .linkRun         (b_linkRun),
    .linkError       (b_linkError),
    .linkConnecting  (b_linkConnecting),
    .memRData        (b_memRData),
    .memReady        (b_memReady),
    .rmapKey         (RMAP_KEY),
    .targetAddr      (TARGET_ADDR),
    .memAddr         (b_memAddr),
    .memWData        (b_memWData),
    .memWe           (b_memWe),
    .memRe           (b_memRe),
    .rmapStatus      (b_rmapStatus),
    .rmapErr         (b_rmapErr),
    .rmapBusy        (b_rmapBusy),
    .tcSend          (b_tcSend),
    .tcTxValue       (b_tcTxValue),
    .tcTxReady       (b_tcTxReady),
    .tcRxValid       (b_tcRxValid),
    .tcRxValue       (b_tcRxValue)
);

// ---------------------------------------------------------------------------
//  Test tracking
// ---------------------------------------------------------------------------
integer pass_count;
integer fail_count;
integer test_num;

// ---------------------------------------------------------------------------
//  Waveform dump
// ---------------------------------------------------------------------------
initial begin
    $dumpfile("tb_caduceus_top.vcd");
    $dumpvars(0, tb_caduceus_top);
end

// ---------------------------------------------------------------------------
//  Simulation timeout watchdog
// ---------------------------------------------------------------------------
initial begin
    #(CLK_PERIOD * 10_00_000);
    $display("[TIMEOUT] Simulation exceeded limit. Tests incomplete.");
    $display("RESULTS: %0d PASSED | %0d FAILED", pass_count, fail_count);
    $finish;
end

// ---------------------------------------------------------------------------
//  Helper tasks
// ---------------------------------------------------------------------------

task wait_cycles;
    input integer n;
    integer i;
    begin
        for(i = 0; i < n; i = i+1)
            @(posedge clk);
    end
endtask

// ---------------------------------------------------------------------------
//  Reset task - re-initialize all driven inputs during reset assertion
// ---------------------------------------------------------------------------
task apply_reset;
    begin
        rstN          = 1'b0;
        a_userTxValid = 1'b0;
        a_txByte      = 8'h00;
        a_txEop       = 1'b0;
        a_txEep       = 1'b0;
        a_tcSend      = 1'b0;
        a_tcTxValue   = 8'h00;
        a_memRData    = 8'h00;
        a_memReady    = 1'b0;

        b_userTxValid = 1'b0;
        b_txByte      = 8'h00;
        b_txEop       = 1'b0;
        b_txEep       = 1'b0;
        b_tcSend      = 1'b0;
        b_tcTxValue   = 8'h00;

        wait_cycles(RESET_CYCLES);
        @(posedge clk);
        rstN = 1'b1;
        @(posedge clk);
        $display("[RESET] Released at time %0t", $time);
    end
endtask

task check;
    input        condition;
    input [255:0] name;
    begin
        if(condition) begin
            $display("[PASS] T%0d: %s", test_num, name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] T%0d: %s  at time %0t", test_num, name, $time);
            fail_count = fail_count + 1;
        end
    end
endtask

// Wait for both nodes to reach linkRun
//task wait_link_up;
//    input integer timeout_cycles;
//    integer i;
//    reg timed_out;
//    begin
//        timed_out = 0;
//        for(i = 0; i < timeout_cycles; i = i+1) begin
//            @(posedge clk);
//            if(a_linkRun && b_linkRun) begin
//                i = timeout_cycles; // break
//            end
//        end
//        if(!a_linkRun || !b_linkRun) begin
//            timed_out = 1;
//            $display("[WARN] Link did not reach RUN within %0d cycles", timeout_cycles);
//        end
//    end
//endtask

task wait_link_up;
    input integer timeout_cycles;
    integer i;
    begin
        i = 0;
        while(i < timeout_cycles && !(a_linkRun && b_linkRun)) begin
            @(posedge clk);
            i = i + 1;
        end
        if(!a_linkRun || !b_linkRun)
            $display("[WARN] Link did not reach RUN within %0d cycles", timeout_cycles);
    end
endtask

// Send one byte from Node A
task send_byte_a;
    input [7:0] data;
    input       eop;
    begin
        @(posedge clk);
        while(!a_txReady) @(posedge clk);
        a_txByte      = data;
        a_userTxValid = 1;
        a_txEop       = eop;
        @(posedge clk);
        a_userTxValid = 0;
        a_txEop       = 0;
    end
endtask

// Send one byte from Node B
task send_byte_b;
    input [7:0] data;
    input       eop;
    begin
        @(posedge clk);
        while(!b_txReady) @(posedge clk);
        b_txByte      = data;
        b_userTxValid = 1;
        b_txEop       = eop;
        @(posedge clk);
        b_userTxValid = 0;
        b_txEop       = 0;
    end
endtask

// Wait for byte received on Node B with timeout
task wait_rx_b;
    input  [7:0]  expected;
    input  integer timeout;
    output reg    received;
    output reg    correct;
    integer i;
    begin
        received = 0;
        correct  = 0;
        for(i = 0; i < timeout; i = i+1) begin
            @(posedge clk);
            if(b_rxValid) begin
                received = 1;
                correct  = (b_rxByte == expected);
                i = timeout;
            end
        end
    end
endtask

// Wait for byte received on Node A with timeout
task wait_rx_a;
    input  [7:0]  expected;
    input  integer timeout;
    output reg    received;
    output reg    correct;
    integer i;
    begin
        received = 0;
        correct  = 0;
        for(i = 0; i < timeout; i = i+1) begin
            @(posedge clk);
            if(a_rxValid) begin
                received = 1;
                correct  = (a_rxByte == expected);
                i = timeout;
            end
        end
    end
endtask

// Build and send RMAP Write command packet from Node A to Node B
// Simplified: target_addr, protocol=0x01, instr, key, initiator_addr,
//             reserved, trans_id_msb, trans_id_lsb, addr(4), len(3), hdr_crc, data..., data_crc
task send_rmap_write;
    input [7:0]  t_addr;
    input [7:0]  key;
    input [31:0] addr;
    input [7:0]  data;
    input [15:0] trans_id;
    begin
        // Header — 16 bytes
        send_byte_a(t_addr,    0);  // [0] target logical address
        send_byte_a(8'h01,     0);  // [1] protocol ID
        send_byte_a(8'h6C,     0);  // [2] instruction: write, verify, reply, increment
        send_byte_a(key,       0);  // [3] key
        send_byte_a(8'h00,     0);  // [4] initiator logical address
        send_byte_a(8'h00,     0);  // [5] reserved
        send_byte_a(trans_id[15:8], 0); // [6] transaction ID MSB
        send_byte_a(trans_id[7:0],  0); // [7] transaction ID LSB
        send_byte_a(addr[31:24],0); // [8]  memory address
        send_byte_a(addr[23:16],0); // [9]
        send_byte_a(addr[15:8], 0); // [10]
        send_byte_a(addr[7:0],  0); // [11]
        send_byte_a(8'h00,     0);  // [12] data length MSB
        send_byte_a(8'h00,     0);  // [13] data length mid
        send_byte_a(8'h01,     0);  // [14] data length LSB = 1 byte
        send_byte_a(8'h00,     0);  // [15] header CRC placeholder
        // Data
        send_byte_a(data,      0);  // data byte
        send_byte_a(8'h00,     1);  // data CRC placeholder + EOP
    end
endtask


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

// ---------------------------------------------------------------------------
//  RX monitoring — capture received bytes into buffer
// ---------------------------------------------------------------------------
reg [7:0] b_rx_buf [0:63];
reg [5:0] b_rx_cnt;
reg       b_rx_eop_seen;

reg [7:0] a_rx_buf [0:63];
reg [5:0] a_rx_cnt;
reg       a_rx_eop_seen;

always @(posedge clk) begin
    if(!rstN) begin
        b_rx_cnt     <= 0;
        b_rx_eop_seen<= 0;
    end else begin
        if(b_rxValid) begin
            b_rx_buf[b_rx_cnt] <= b_rxByte;
            b_rx_cnt           <= b_rx_cnt + 1;
        end
        if(b_rxEop) b_rx_eop_seen <= 1;
        if(b_rxEep) b_rx_eop_seen <= 1;
    end
end

always @(posedge clk) begin
    if(!rstN) begin
        a_rx_cnt     <= 0;
        a_rx_eop_seen<= 0;
    end else begin
        if(a_rxValid) begin
            a_rx_buf[a_rx_cnt] <= a_rxByte;
            a_rx_cnt           <= a_rx_cnt + 1;
        end
        if(a_rxEop) a_rx_eop_seen <= 1;
        if(a_rxEep) a_rx_eop_seen <= 1;
    end
end

// ---------------------------------------------------------------------------
//  TEST SEQUENCES
// ---------------------------------------------------------------------------

// ===== TEST 1: Reset =====
task test_reset;
    begin
        test_num = 1;
        $display("\n--- TEST 1: Reset Behaviour ---");
        apply_reset;
        wait_cycles(5);
        check(!a_linkRun,      "A: linkRun LOW after reset");
        check(!b_linkRun,      "B: linkRun LOW after reset");
        check(a_linkError,     "A: linkError HIGH after reset (ErrorReset state)");
        check(b_linkError,     "B: linkError HIGH after reset (ErrorReset state)");
        check(!a_rmapBusy,     "A: rmapBusy LOW after reset");
        check(!b_rmapBusy,     "B: rmapBusy LOW after reset");
        check(!a_tcRxValid,    "A: tcRxValid LOW after reset");
        check(!b_tcRxValid,    "B: tcRxValid LOW after reset");
    end
endtask

// ===== TEST 2: Link Startup =====
task test_link_startup;
    begin
        test_num = 2;
        $display("\n--- TEST 2: Link Startup (NULL exchange → FCT → RUN) ---");
        // Nodes are already released from reset
        // Wait for both to reach RUN
        wait_link_up(LINK_TIMEOUT);
        check(a_linkRun, "A: reached linkRun");
        check(b_linkRun, "B: reached linkRun");
        check(!a_linkError, "A: no linkError in RUN");
        check(!b_linkError, "B: no linkError in RUN");
        $display("[INFO] Link established at time %0t", $time);
    end
endtask

// ===== TEST 3: Single byte A→B =====
task test_single_byte;
    reg rx_ok, data_ok;
    begin
        test_num = 3;
        $display("\n--- TEST 3: Single Byte Transfer A→B ---");
        b_rx_cnt = 0;
        send_byte_a(8'hA5, 0);
        // Wait for B to receive
        wait_rx_b(8'hA5, 500, rx_ok, data_ok);
        check(rx_ok,   "B: rxValid pulsed");
        check(data_ok, "B: received correct byte 0xA5");
    end
endtask

// ===== TEST 4: Burst transfer A→B =====
task test_burst_transfer;
    integer i;
    reg rx_ok, data_ok;
    begin
        test_num = 4;
        $display("\n--- TEST 4: Burst Transfer A→B (16 bytes) ---");
        b_rx_cnt = 0;
        for(i = 0; i < 16; i = i+1) begin
            send_byte_a(i[7:0], 0);
        end
        // Wait enough time for all bytes to propagate
        wait_cycles(16 * CLKS_PER_BIT * 12);
        check(b_rx_cnt == 16, "B: received all 16 bytes");
        // Spot check first and last
        check(b_rx_buf[0] == 8'h00,  "B: first byte correct (0x00)");
        check(b_rx_buf[15] == 8'h0F, "B: last byte correct (0x0F)");
    end
endtask

// ===== TEST 5: Bidirectional simultaneous =====
task test_bidirectional;
    reg a_rx_ok, a_data_ok;
    reg b_rx_ok, b_data_ok;
    begin
        test_num = 5;
        $display("\n--- TEST 5: Bidirectional Simultaneous Transfer ---");
        a_rx_cnt = 0;
        b_rx_cnt = 0;
        // Fork: A sends to B, B sends to A simultaneously
        fork
            send_byte_a(8'hDE, 0);
            send_byte_b(8'hAD, 0);
        join
        wait_cycles(200);
        check(b_rx_cnt > 0,              "B: received data from A");
        check(b_rx_buf[0] == 8'hDE,     "B: correct data from A (0xDE)");
        check(a_rx_cnt > 0,              "A: received data from B");
        check(a_rx_buf[0] == 8'hAD,     "A: correct data from B (0xAD)");
    end
endtask

// ===== TEST 6: EOP packet termination =====
task test_eop;
    integer i;
    begin
        test_num = 6;
        $display("\n--- TEST 6: EOP Packet Termination ---");
        b_rx_cnt      = 0;
        b_rx_eop_seen = 0;
        // Send 4-byte packet then EOP
        send_byte_a(8'h01, 0);
        send_byte_a(8'h02, 0);
        send_byte_a(8'h03, 0);
        send_byte_a(8'h04, 1);  // EOP on last byte
        wait_cycles(300);
        check(b_rx_cnt == 4,    "B: received 4 data bytes");
        check(b_rx_eop_seen,    "B: EOP received");
    end
endtask

// ===== TEST 7: EEP error packet =====
task test_eep;
    begin
        test_num = 7;
        $display("\n--- TEST 7: EEP Error End of Packet ---");
        b_rx_cnt      = 0;
        b_rx_eop_seen = 0;
        send_byte_a(8'hFF, 0);
        // Assert EEP
        @(posedge clk);
        while(!a_txReady) @(posedge clk);
        a_txEep = 1;
        @(posedge clk);
        a_txEep = 0;
        wait_cycles(200);
        check(b_rx_eop_seen, "B: EEP received after error");
    end
endtask

// ===== TEST 8: Flow control =====
task test_flow_control;
    integer i;
    begin
        test_num = 8;
        $display("\n--- TEST 8: Flow Control (credit exhaustion) ---");
        b_rx_cnt = 0;
        // Send 56 bytes (max credits = 7 FCTs × 8 chars)
        for(i = 0; i < 56; i = i+1) begin
            send_byte_a(i[7:0], 0);
        end
        wait_cycles(56 * CLKS_PER_BIT * 12 + 500);
        check(b_rx_cnt == 56, "B: all 56 bytes received (full credit window)");
        // After receiving 8 bytes, B should have sent FCTs
        // Send 8 more to confirm credits were replenished
        b_rx_cnt = 0;
        for(i = 0; i < 8; i = i+1) begin
            send_byte_a(8'hCC, 0);
        end
        wait_cycles(8 * CLKS_PER_BIT * 12 + 200);
        check(b_rx_cnt == 8, "B: 8 more bytes received after FCT replenishment");
    end
endtask

// ===== TEST 9: RMAP Write =====
task test_rmap_write;
    integer timeout;
    reg write_seen;
    begin
        test_num = 9;
        $display("\n--- TEST 9: RMAP Write Command ---");
        // Initialise memory
        for(timeout = 0; timeout < 256; timeout = timeout+1)
            mem[timeout] = 8'hFF;

        b_rx_cnt = 0;
        send_rmap_write(TARGET_ADDR, RMAP_KEY, TEST_MEM_ADDR, 8'h42, 16'h0001);

        // Wait for memWe on node B
        write_seen = 0;
        for(timeout = 0; timeout < 2000; timeout = timeout+1) begin
            @(posedge clk);
            if(b_memWe) begin
                write_seen = 1;
                timeout = 2000;
            end
        end

        wait_cycles(100);
        check(write_seen,                        "B: memWe asserted");
        check(b_memAddr == TEST_MEM_ADDR,        "B: correct memory address");
        check(b_memWData == 8'h42,               "B: correct write data (0x42)");
        check(mem[TEST_MEM_ADDR[7:0]] == 8'h42,  "B: memory model updated");
        check(!b_rmapErr,                        "B: no RMAP error");
    end
endtask

// ===== TEST 10: RMAP Read =====
task test_rmap_read;
    integer timeout;
    reg read_seen;
    begin
        test_num = 10;
        $display("\n--- TEST 10: RMAP Read Command ---");
        // Pre-load memory
        mem[TEST_MEM_ADDR[7:0]] = 8'hBE;
        b_memRData = 8'hBE;

        // Send read command (instr[5]=0)
        send_byte_a(TARGET_ADDR, 0);
        send_byte_a(8'h01,       0);  // protocol
        send_byte_a(8'h4C,       0);  // instruction: read, reply, increment
        send_byte_a(RMAP_KEY,    0);
        send_byte_a(8'h00,       0);  // initiator addr
        send_byte_a(8'h00,       0);  // reserved
        send_byte_a(8'h00,       0);  // trans_id MSB
        send_byte_a(8'h02,       0);  // trans_id LSB
        send_byte_a(TEST_MEM_ADDR[31:24], 0);
        send_byte_a(TEST_MEM_ADDR[23:16], 0);
        send_byte_a(TEST_MEM_ADDR[15:8],  0);
        send_byte_a(TEST_MEM_ADDR[7:0],   0);
        send_byte_a(8'h00,       0);  // length MSB
        send_byte_a(8'h00,       0);  // length mid
        send_byte_a(8'h01,       0);  // length = 1
        send_byte_a(8'h00,       1);  // header CRC + EOP

        read_seen = 0;
        for(timeout = 0; timeout < 2000; timeout = timeout+1) begin
            @(posedge clk);
            if(b_memRe) begin
                read_seen = 1;
                timeout = 2000;
            end
        end

        wait_cycles(200);
        check(read_seen,                  "B: memRe asserted");
        check(b_memAddr == TEST_MEM_ADDR, "B: correct read address");
        check(!b_rmapErr,                 "B: no RMAP error");
    end
endtask

// ===== TEST 11: RMAP invalid key =====
task test_rmap_bad_key;
    integer timeout;
    reg err_seen;
    begin
        test_num = 11;
        $display("\n--- TEST 11: RMAP Invalid Key Rejection ---");
        send_rmap_write(TARGET_ADDR, 8'hFF, TEST_MEM_ADDR, 8'h00, 16'h0003);
        // Wrong key = 0xFF instead of RMAP_KEY

        err_seen = 0;
        for(timeout = 0; timeout < 2000; timeout = timeout+1) begin
            @(posedge clk);
            if(b_rmapErr) begin
                err_seen = 1;
                timeout = 2000;
            end
        end

        wait_cycles(100);
        check(err_seen,                   "B: rmapErr asserted on bad key");
        check(b_rmapStatus == 8'h04,      "B: ECSS status 0x04 (invalid key)");
    end
endtask

// ===== TEST 12: Timecode TX/RX =====
task test_timecode;
    integer timeout;
    reg tc_seen;
    begin
        test_num = 12;
        $display("\n--- TEST 12: Timecode TX/RX ---");
        // Send timecode from A, check B receives it
        @(posedge clk);
        while(!a_tcTxReady) @(posedge clk);
        a_tcTxValue = 8'h2A;   // timecode value = 42
        a_tcSend    = 1'b1;
        @(posedge clk);
        a_tcSend    = 1'b0;

        tc_seen = 0;
        for(timeout = 0; timeout < 500; timeout = timeout+1) begin
            @(posedge clk);
            if(b_tcRxValid) begin
                tc_seen = 1;
                timeout = 500;
            end
        end

        check(tc_seen,                "B: tcRxValid pulsed");
        check(b_tcRxValue == 8'h2A,   "B: correct timecode value (0x2A)");

        // Send from B → A
        @(posedge clk);
        while(!b_tcTxReady) @(posedge clk);
        b_tcTxValue = 8'h55;
        b_tcSend    = 1'b1;
        @(posedge clk);
        b_tcSend    = 1'b0;

        tc_seen = 0;
        for(timeout = 0; timeout < 500; timeout = timeout+1) begin
            @(posedge clk);
            if(a_tcRxValid) begin
                tc_seen = 1;
                timeout = 500;
            end
        end

        check(tc_seen,                "A: tcRxValid pulsed");
        check(a_tcRxValue == 8'h55,   "A: correct timecode value (0x55)");
    end
endtask

// ===== TEST 13: Disconnect error =====
task test_disconnect;
    integer timeout;
    reg err_seen;
    begin
        test_num = 13;
        $display("\n--- TEST 13: Disconnect Error Injection ---");
        // Force Din/Sin to stop toggling by overriding the loopback
        // This is done by temporarily driving fixed values
        // In simulation we can force signals
        $display("[INFO] Injecting disconnect — holding Din/Sin static");

        // Save loopback — force static (no DS transitions)
        // Use force/release for simulation only
        force b_Din = 1'b0;
        force b_Sin = 1'b0;

        // Wait for disconnect timeout
        // SPW_DISC_TIMEOUT = 64 cycles + prescaler
        err_seen = 0;
        for(timeout = 0; timeout < 1000; timeout = timeout+1) begin
            @(posedge clk);
            if(b_linkError) begin
                err_seen = 1;
                timeout = 1000;
            end
        end

        release b_Din;
        release b_Sin;

        check(err_seen, "B: linkError after disconnect timeout");
    end
endtask

// ===== TEST 14: Link recovery after error =====
task test_link_recovery;
    begin
        test_num = 14;
        $display("\n--- TEST 14: Link Recovery After Error ---");
        // After test 13, link should be in error state
        // Wait for automatic recovery (link FSM reruns startup)
        wait_link_up(LINK_TIMEOUT * 2);
        check(a_linkRun, "A: recovered to linkRun");
        check(b_linkRun, "B: recovered to linkRun");
        $display("[INFO] Link recovered at time %0t", $time);
    end
endtask

// ===== TEST 15: Back-to-back packets =====
task test_back_to_back_packets;
    integer i;
    begin
        test_num = 15;
        $display("\n--- TEST 15: Back-to-Back Packets ---");
        b_rx_cnt      = 0;
        b_rx_eop_seen = 0;

        // Packet 1: 3 bytes + EOP
        send_byte_a(8'hAA, 0);
        send_byte_a(8'hBB, 0);
        send_byte_a(8'hCC, 1);  // EOP

        wait_cycles(200);

        // Packet 2: immediately after
        b_rx_cnt      = 0;
        b_rx_eop_seen = 0;
        send_byte_a(8'h11, 0);
        send_byte_a(8'h22, 1);  // EOP

        wait_cycles(200);
        check(b_rx_cnt == 2,     "B: packet 2 received (2 bytes)");
        check(b_rx_eop_seen,     "B: EOP of packet 2 received");
        check(b_rx_buf[0]==8'h11,"B: packet 2 byte 0 correct");
        check(b_rx_buf[1]==8'h22,"B: packet 2 byte 1 correct");
    end
endtask

// ---------------------------------------------------------------------------
//  Main test sequence
// ---------------------------------------------------------------------------
initial begin
    pass_count = 0;
    fail_count = 0;
    test_num   = 0;
// ---------------------------------------------------------------------------
//  Initial block - set all testbench-driven inputs to zero at time 0
// ---------------------------------------------------------------------------
    a_userTxValid = 1'b0;
    a_txByte      = 8'h00;
    a_txEop       = 1'b0;
    a_txEep       = 1'b0;
    a_tcSend      = 1'b0;
    a_tcTxValue   = 8'h00;
    a_memRData    = 8'h00;
    a_memReady    = 1'b0;

    b_userTxValid = 1'b0;
    b_txByte      = 8'h00;
    b_txEop       = 1'b0;
    b_txEep       = 1'b0;
    b_tcSend      = 1'b0;
    b_tcTxValue   = 8'h00;


    $display("=======================================================");
    $display("  caduceus — Full Stack RTL Testbench");
    $display("  Two-node loopback: Node A �?→ Node B");
    $display("=======================================================");

    test_reset;
    test_link_startup;

    if(a_linkRun && b_linkRun) begin
        test_single_byte;
        test_burst_transfer;
        test_bidirectional;
        test_eop;
        test_eep;
        test_flow_control;
        test_rmap_write;
        test_rmap_read;
        test_rmap_bad_key;
        test_timecode;
        test_disconnect;
        test_link_recovery;
        if(a_linkRun && b_linkRun)
            test_back_to_back_packets;
    end else begin
        $display("[SKIP] Link never reached RUN — skipping data transfer tests");
        fail_count = fail_count + 1;
    end

    $display("\n=======================================================");
    $display("  RESULTS: %0d PASSED | %0d FAILED", pass_count, fail_count);
    $display("=======================================================");

    if(fail_count == 0)
        $display("  ALL TESTS PASSED ✓");
    else
        $display("  FAILURES DETECTED — open VCD in GTKWave");

    #1000000000 $finish;
end
//initial begin
//    #10000;  // 10 �s after reset release
//    force u_node_a.linkError = 0;
//    force u_node_b.linkError = 0;
//    #100;
//    release u_node_a.linkError;
//    release u_node_b.linkError;
//end
endmodule

// =============================================================================
//  End of tb_caduceus_top.v
// =============================================================================
