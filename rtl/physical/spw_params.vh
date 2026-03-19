// =============================================================================
//  caduceus — SpaceWire IP Core (ECSS-E-ST-50-12C compliant)
//  File    : spw_params.vh
//  Author  : Soumyadip Roy
//  Licence : MIT 
// =============================================================================

`ifndef SPW_PARAMS_VH
`define SPW_PARAMS_VH

`define SPW_SYS_CLK_HZ          50_000_000
`define SPW_LINK_BIT_RATE        10_000_000
`define SPW_CLKS_PER_BIT         (`SPW_SYS_CLK_HZ / `SPW_LINK_BIT_RATE)
`define SPW_DISC_TIMEOUT         64
`define SPW_ERRWAIT_TIMEOUT      320

`define SPW_TX_FIFO_DEPTH        16
`define SPW_RX_FIFO_DEPTH        16

`define SPW_RMAP_EN              1   
`define SPW_TIMECODE_EN          1   
`define SPW_ROUTER_PORTS         4   

`define SPW_ST_ERROR_RESET       3'd0
`define SPW_ST_ERROR_WAIT        3'd1
`define SPW_ST_READY             3'd2
`define SPW_ST_STARTED           3'd3
`define SPW_ST_CONNECTING        3'd4
`define SPW_ST_RUN               3'd5

`endif 