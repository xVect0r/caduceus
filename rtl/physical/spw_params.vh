// =============================================================================
//  caduceus — SpaceWire IP Core (ECSS-E-ST-50-12C compliant)
//  File    : spw_params.vh
//  Purpose : Single source of truth for every tuneable constant.
//            Include this file at the top of every RTL module.
//            Override any value by redefining BEFORE the include,
//            or via Quartus assignment: set_parameter -name SPW_SYS_CLK_HZ 100000000
//
//  Author  : Soumyadip Roy
//  Licence : MIT 
// =============================================================================

`ifndef SPW_PARAMS_VH
`define SPW_PARAMS_VH

// -----------------------------------------------------------------------------
//  System clock frequency (Hz)
//  Change this to match your board. Everything timing-derived scales from here.
//  Examples: 50_000_000 (DE10-Lite), 100_000_000 (DE1-SoC), 125_000_000 (custom)
// -----------------------------------------------------------------------------
`define SPW_SYS_CLK_HZ          50_000_000

// -----------------------------------------------------------------------------
//  SpaceWire link bit-rate (bits/sec)
//  ECSS allows 2 Mbps – 400 Mbps. 10 Mbps is safe for simulation.
//  Constraint: SPW_SYS_CLK_HZ / SPW_LINK_BIT_RATE must be an integer >= 4.
//  For 200 Mbps at 200 MHz sys_clk: ratio = 1 (oversampling not needed).
// -----------------------------------------------------------------------------
`define SPW_LINK_BIT_RATE        10_000_000

// -----------------------------------------------------------------------------
//  Derived: clocks per bit period (used by timer prescaler)
// -----------------------------------------------------------------------------
`define SPW_CLKS_PER_BIT         (`SPW_SYS_CLK_HZ / `SPW_LINK_BIT_RATE)

// -----------------------------------------------------------------------------
//  Disconnect timeout (sys_clk cycles)
//  ECSS §8.5.3: link must reset if no DS transitions within 850 ns minimum.
//  At 50 MHz: 850 ns = 42.5 cycles → use 64 (next power of 2, conservative).
//  Formula: ceil(850e-9 * SYS_CLK_HZ) rounded up to power of 2.
// -----------------------------------------------------------------------------
`define SPW_DISC_TIMEOUT         64

// -----------------------------------------------------------------------------
//  Error-Wait timeout (sys_clk cycles)
//  ECSS §8.5.3: minimum 6.4 µs in Error-Wait state before advancing to Ready.
//  At 50 MHz: 6.4 µs = 320 cycles.
// -----------------------------------------------------------------------------
`define SPW_ERRWAIT_TIMEOUT      320

// -----------------------------------------------------------------------------
//  TX / RX FIFO depths (characters, must be power of 2)
//  Minimum safe depth = link_latency_cycles / clks_per_bit.
//  Default 16 is conservative for a 1m cable at 10 Mbps.
// -----------------------------------------------------------------------------
`define SPW_TX_FIFO_DEPTH        16
`define SPW_RX_FIFO_DEPTH        16

// -----------------------------------------------------------------------------
//  Feature enables — set to 0 to exclude and save LUTs
// -----------------------------------------------------------------------------
`define SPW_RMAP_EN              1   // Include RMAP engine
`define SPW_TIMECODE_EN          1   // Include timecode TX/RX
`define SPW_ROUTER_PORTS         4   // Number of router ports (1 = no router)

// -----------------------------------------------------------------------------
//  FSM state encoding (3-bit, exported on link_state port)
//  Matches ECSS §8.5.3 state names exactly.
// -----------------------------------------------------------------------------
`define SPW_ST_ERROR_RESET       3'd0
`define SPW_ST_ERROR_WAIT        3'd1
`define SPW_ST_READY             3'd2
`define SPW_ST_STARTED           3'd3
`define SPW_ST_CONNECTING        3'd4
`define SPW_ST_RUN               3'd5

`endif // SPW_PARAMS_VH
// =============================================================================
//  End of spw_params.vh
// =============================================================================
