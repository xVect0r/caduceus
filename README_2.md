# Caduceus 🐍🐍
### A SpaceWire (ECSS-E-ST-50-12C) Compliant RTL IP Core in Verilog

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Status: In Development](https://img.shields.io/badge/Status-In%20Development-orange)
![Standard: ECSS-E-ST-50-12C](https://img.shields.io/badge/Standard-ECSS--E--ST--50--12C-blue)
![Target: Xilinx/Intel FPGA](https://img.shields.io/badge/Target-Xilinx%20%7C%20Intel%20FPGA-green)

---

## Why "Caduceus"?

The Caduceus is the winged staff of Hermes — the messenger god of speed and communication — with **two serpents coiled around it**.

In SpaceWire, all data travels across exactly **two wires: Data and Strobe**. XOR them together and you recover the clock — no separate clock wire needed. This is called **DS (Data-Strobe) encoding**.

Two wires. Two serpents. The name chose itself.

---

## What is SpaceWire?

SpaceWire is a high-speed serial communication standard used **inside spacecraft** — connecting sensors, processors, instruments, and subsystems on ESA missions, satellites, and deep-space probes. It is defined by **ECSS-E-ST-50-12C** and operates from **2 Mbps to 400 Mbps**.

Every timing constraint in the spec is defined down to the nanosecond. This IP implements those constraints faithfully.

---

## Project Goal

To provide a **clean, readable, open-source** SpaceWire IP core that:
- Is fully **ECSS-E-ST-50-12C compliant**
- Targets **Xilinx (Vivado)** and **Intel (Quartus)** FPGAs
- Is **beginner-friendly** — every module is documented, every design decision is explained
- Can be used as a **learning resource** for anyone wanting to understand a real space-grade serial protocol from first principles
- Is **MIT licensed** — free to use, modify, and build upon

---

## Architecture

SpaceWire is a layered protocol. Caduceus implements it layer by layer:

```
┌─────────────────────────────────────────┐
│           Application Layer             │  ← User data in/out
├─────────────────────────────────────────┤
│           Network Layer (RMAP)          │  ← Remote Memory Access Protocol
├─────────────────────────────────────────┤
│           Link Layer                    │  ← Flow control, FSM, character decode
├─────────────────────────────────────────┤
│           Physical Layer  ✅ DONE        │  ← DS encoding/decoding, CDC, timers
└─────────────────────────────────────────┘
                    │
              LVDS Cable
                    │
┌─────────────────────────────────────────┐
│         Remote SpaceWire Node           │
└─────────────────────────────────────────┘
```

---

## Physical Layer — Status: ✅ Complete

The physical layer handles raw bit-level communication on the Data and Strobe wires.

### Modules

| Module | File | Description |
|--------|------|-------------|
| `phy_top` | `rtl/physical/phy_top.v` | Top-level wrapper — connects all PHY modules |
| `cd_ds` | `rtl/physical/cd_ds.v` | DS decoder — receives bits from Din/Sin pins |
| `cd_tx` | `rtl/physical/cd_tx.v` | DS encoder — transmits bits to Dout/Sout pins |
| `phy_cdc_sync` | `rtl/physical/cd_cdc_sync.v` | 3-FF CDC synchronizer for metastability hardening |
| `cd_parity` | `rtl/physical/cd_parity.v` | Parity generator (TX) and checker (RX) |
| `phy_timer` | `rtl/physical/cd_timer.v` | Dual-mode timer — disconnect watchdog + errwait |
| `spw_params` | `rtl/physical/spw_params.vh` | Central parameter file — all timing derives from here |

### Key Design Decisions

**DS Encoding:** SpaceWire uses Data-Strobe encoding. The transmitter toggles Data for a `0` bit and Strobe for a `1` bit. The receiver XORs them to recover the clock. No separate clock wire is needed, and the link is self-clocking.

**Gray-coded bit counter in `cd_ds`:** The bit position counter uses Gray code so only one bit changes per increment, preventing glitch conditions during decode.

**3-FF CDC synchronizer:** Both `Din` and `Sin` physical pins pass through separate 3-flipflop synchronizer chains before entering the design. The `(*keep="true"*)` pragma prevents synthesis tools from collapsing the chain and reintroducing metastability.

**Parameterized timer:** All timeouts are derived from a single `SPW_SYS_CLK_HZ` define. Change the clock frequency and every timing constant recalculates automatically via `$clog2` and localparam arithmetic.

### Physical Layer Port Map (`phy_top`)

```verilog
module phy_top (
    input  wire        clk,           // System clock
    input  wire        rst_n,         // Active-low reset

    // Physical pins
    input  wire        Din,           // Data pin from cable
    input  wire        Sin,           // Strobe pin from cable
    output wire        Dout,          // Data pin to cable
    output wire        Sout,          // Strobe pin to cable

    // TX interface
    input  wire [9:0]  tx_char,       // 10-bit character to transmit
    input  wire        tx_valid,      // Character ready to send
    output wire        tx_ready,      // PHY ready to accept
    output wire        tx_done,       // One-cycle pulse: TX complete

    // RX interface
    output wire [9:0]  rx_char,       // Received character
    output wire        rx_valid,      // One-cycle pulse: RX valid
    output wire        parity_err,    // Parity error flag

    // Link FSM control (driven by link layer)
    input  wire        rx_en,         // Enable RX
    input  wire        arm_errwait,   // Start 6.4us errwait timer
    input  wire        arm_disc,      // Start 850ns disconnect watchdog
    output wire        errwait_done,  // 6.4us elapsed
    output wire        disc_done,     // 850ns elapsed, no DS activity
    output wire        tick           // 1MHz prescaler tick
);
```

---

## Link Layer — Status: 🔨 In Progress

The link layer implements the ECSS §8.5.3 state machine and manages link establishment, flow control, and character-level protocol.

### Modules Planned

| Module | Description |
|--------|-------------|
| `spw_link_fsm` | 6-state link FSM: ErrorReset→ErrorWait→Ready→Started→Connecting→Run |
| `spw_char_decode` | Character classifier: NULL / FCT / EOP / EEP / N-char / Timecode |
| `spw_flow_ctrl` | Credit counter — FCT generation and consumption |
| `spw_tx_mux` | Mux between NULL/FCT/data going to PHY TX |

### Link FSM States (ECSS §8.5.3)

```
ErrorReset → ErrorWait → Ready → Started → Connecting → Run
     ↑____________↑__________↑_______↑__________↑_________↑
                    (Any error condition collapses to ErrorReset)
```

| State | Description |
|-------|-------------|
| ErrorReset | Power-on / error state. All outputs disabled. Waits 6.4µs minimum. |
| ErrorWait | Still disabled. Waiting for errwait timer. Any error restarts. |
| Ready | Sending NULLs. Disconnect watchdog armed. Waiting for NULL from remote. |
| Started | Got first NULL. Waiting for FCT from remote. |
| Connecting | Got FCT. Sending FCTs. Almost there. |
| Run | Full duplex. N-chars, timecodes, RMAP all flow. |

---

## Network / RMAP Layer — Status: 📋 Planned

RMAP (Remote Memory Access Protocol, ECSS-E-ST-50-52C) allows a SpaceWire node to read and write memory on a remote node without software intervention.

Caduceus will implement Read and Write commands — covering the vast majority of real-world RMAP usage.

---

## Getting Started

### Prerequisites

- **Vivado 2022.x or later** (Xilinx) — primary target
- **Quartus Prime Lite** (Intel) — also supported
- Verilog-2001 compatible simulator (ModelSim, Vivado Simulator, Verilator)

### Repository Structure

```
caduceus/
├── rtl/
│   └── physical/           # Physical layer RTL
│       ├── spw_params.vh   # Central parameter file — edit this first
│       ├── phy_top.v       # PHY top-level
│       ├── cd_ds.v         # DS decoder (RX)
│       ├── cd_tx.v         # DS encoder (TX)
│       ├── cd_cdc_sync.v   # CDC synchronizer
│       ├── cd_parity.v     # Parity generator/checker
│       └── cd_timer.v      # Disconnect + errwait timer
├── tb/
│   └── tb_phy_top.v        # Physical layer connectivity testbench
├── constraints/
│   └── caduceus.xdc        # Vivado timing constraints (coming)
└── README.md
```

### Configuration

Edit `spw_params.vh` before synthesizing:

```verilog
// Set this to your board's clock frequency
`define SPW_SYS_CLK_HZ    100_000_000   // 100 MHz (Artix-7 default)

// SpaceWire link rate — must divide evenly into SYS_CLK_HZ
`define SPW_LINK_BIT_RATE  10_000_000   // 10 Mbps (safe for simulation)

// These are derived automatically — do not edit
`define SPW_CLKS_PER_BIT   (`SPW_SYS_CLK_HZ / `SPW_LINK_BIT_RATE)
`define SPW_DISC_TIMEOUT   64           // 850ns at 50MHz
`define SPW_ERRWAIT_TIMEOUT 320         // 6.4us at 50MHz
```

### Vivado Quick Start

1. Create a new Vivado project targeting your FPGA
2. Add all files from `rtl/physical/` as design sources
3. Set `phy_top` as the top-level module
4. Add `tb/tb_phy_top.v` as a simulation source
5. Set `SPW_SYS_CLK_HZ` to match your board clock in `spw_params.vh`
6. Run simulation: `Simulation → Run Simulation → Run Behavioral Simulation`
7. Run synthesis: `Flow → Run Synthesis`

### Simulation (Vivado)

In the Tcl console after opening simulation:
```tcl
add_wave -r /tb_phy_top/*
run -all
```

---

## ECSS Compliance Notes

| Requirement | Section | Status |
|-------------|---------|--------|
| DS encoding/decoding | §8.4.2 | ✅ |
| Parity generation and checking | §8.4.3 | ✅ |
| Disconnect timeout (850ns min) | §8.5.3 | ✅ |
| ErrorWait timeout (6.4µs min) | §8.5.3 | ✅ |
| Link FSM states | §8.5.3 | 🔨 |
| NULL character sequence | §8.4.4 | 🔨 |
| FCT flow control | §8.5.4 | 📋 |
| N-char support | §8.4.4 | 📋 |
| Timecode TX/RX | §8.10 | 📋 |
| RMAP Read/Write | ECSS-E-ST-50-52C | 📋 |

---

## Changelog

| Date | Entry |
|------|-------|
| 19-03-26 | Implemented the physical layer — connects to LVDS wires between modules |
| 20-03-26 | Expanded README. Physical layer implemented (pre-verification). First layer complete. |
| 23-03-26 | Cleaned physical layer implementations. Corrected layer completion status. |
| 26-03-26 | Implemented `cd_tx` DS encoder. Integrated all modules in `phy_top`. |
| 27-03-26 | Re-iterated module files. Cleaned top-level connections and assign statements. |
| 07-04-26 | Migrated to Vivado. Link layer in progress. README overhaul. |

---

## Contributing

Issues and PRs are welcome. If you've worked with SpaceWire or space-grade hardware and spot something wrong — please open an issue. Correctness over features, always.

---

## References

- ECSS-E-ST-50-12C: SpaceWire — Links, nodes, routers and networks (ESA)
- ECSS-E-ST-50-52C: SpaceWire — RMAP Protocol
- [ESA SpaceWire Working Group](https://www.spacewire.esa.int)
- [STAR-Dundee SpaceWire Resources](https://www.star-dundee.com)

---

## Author

**Soumyadip Roy**
Electronics & Instrumentation, BITS Pilani

*"An extra flipflop in your design forces the metastability to resign."* — cd_cdc_sync.v, line 14

---

## License

MIT License — see [LICENSE](./LICENSE) for details.

Free to use, modify, and distribute. If Caduceus helps you build something that flies, a mention would be appreciated. 🚀
