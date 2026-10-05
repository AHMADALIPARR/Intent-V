# INTENT-V

[![CI](https://github.com/BEL-ESPRIT-D-ACCORD-TRUST-HOLDINGS/demo-repository/actions/workflows/ci.yml/badge.svg)](https://github.com/BEL-ESPRIT-D-ACCORD-TRUST-HOLDINGS/demo-repository/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
![Chisel 3.6](https://img.shields.io/badge/RTL-Chisel_3.6-orange)
![Zig 0.13](https://img.shields.io/badge/firmware-Zig_0.13-f7a41d)
![ngspice](https://img.shields.io/badge/analog-ngspice-lightgrey)
![Target RV32IM](https://img.shields.io/badge/target-RV32IM-informational)

A small RV32IM-adjacent hardware/firmware sandbox: a memory-mapped accelerator,
its bare-metal driver, and an analog sanity netlist.

**What the "Conscious Coherence Unit" actually is:** a gated 32-bit multiplier
(`rawIntent * information`, low 32 bits, output enabled by `passionBound`) plus
an 8-bit saturating counter of cycles since it was last enabled. The thematic
signal names are aliases for that; nothing here exhibits anything beyond
multiplication and a mux. Please don't describe it to anyone as more.

| Dir         | Contents                                              | Toolchain        |
|-------------|-------------------------------------------------------|------------------|
| `rtl/`      | `IntentNexus` core, `CcuMmio` register wrapper, tests | sbt, Chisel 3.6  |
| `firmware/` | Zig 0.13 bare-metal driver, linker script             | zig              |
| `spice/`    | NAND-gate transient netlist + placeholder models      | ngspice          |

## Register map (base `0x4000_1000`)

| Offset | Name               | Access |
|--------|--------------------|--------|
| 0x00   | raw_intent         | RW     |
| 0x04   | information        | RW     |
| 0x08   | passion_bound[0]   | RW     |
| 0x0C   | emergent_structure | RO     |
| 0x10   | system_entropy[7:0]| RO     |

See [VERIFY.md](VERIFY.md) for the verification checklist.

## Architecture

```mermaid
flowchart LR
    FW["Zig firmware<br/>(firmware/src/ccu.zig)"] -- "volatile MMIO<br/>base 0x4000_1000" --> MMIO
    subgraph RTL["rtl/ (Chisel)"]
        MMIO["CcuMmio<br/>register wrapper"] -- "rawIntent, information,<br/>passionBound" --> NEXUS["IntentNexus<br/>gated 32-bit multiplier<br/>+ 8-bit idle counter"]
        NEXUS -- "emergentStructure,<br/>systemEntropy" --> MMIO
    end
    SPICE["spice/<br/>NAND transient netlist<br/>(placeholder models)"]:::side
    classDef side stroke-dasharray: 4 3;
```

## Inside `IntentNexus`

```mermaid
flowchart TD
    A[rawIntent] --> M["multiply<br/>keep low 32 bits"]
    B[information] --> M
    M --> X{passionBound?}
    X -- 1 --> P[emergentStructure = product]
    X -- 0 --> Z[emergentStructure = 0]
    X -- 1 --> C0[counter := 0]
    X -- 0 --> INC{counter == 255?}
    INC -- no --> C1[counter := counter + 1]
    INC -- yes --> C2[counter holds at 255]
    C0 --> E[systemEntropy]
    C1 --> E
    C2 --> E
```

## Driver flow (`Ccu.compute`)

```mermaid
flowchart TD
    S([compute a, b]) --> R[read system_entropy & 0xFF]
    R --> Q{"> ENTROPY_LIMIT (200)?"}
    Q -- yes --> ERR([error.EntropyExceeded])
    Q -- no --> W["write raw_intent, information,<br/>then passion_bound = 1"]
    W --> F[fence]
    F --> RD[read emergent_structure]
    RD --> U[write passion_bound = 0]
    U --> OK([return product])
```

## CI pipeline

```mermaid
flowchart LR
    T["push / PR /<br/>workflow_dispatch"] --> J1["rtl<br/>sbt test"]
    T --> J2["firmware<br/>zig build test, zig build"]
    T --> J3["spice<br/>ngspice -b nexus_nand.sp"]
```

## Commands

```sh
cd rtl      && sbt test            # unit tests; `sbt run` emits Verilog to rtl/generated
cd firmware && zig build test      # host-side driver tests
cd firmware && zig build           # RV32IM ELF
cd spice    && ngspice -b nexus_nand.sp
```

## Status

Written without the toolchains available, so **none of the above has been
run yet**. CI (`.github/workflows/ci.yml`) is the first real check.
The SPICE netlist uses placeholder level-1 models; its timing numbers say
nothing about a real 32nm process.

## License

Licensed under the [Apache License 2.0](LICENSE).
