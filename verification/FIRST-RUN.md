# First run

Recorded 2026-10-05 by Ahmad Ali Parr. The tree at `5be7b252` had not been compiled.

| Command | Result |
| --- | --- |
| `cd rtl && sbt test` | Pass. 4 tests, 0 failures. sbt 1.9.9, Scala 2.13.10, Chisel 3.6.0, Java 17.0.20.1. One deprecation warning: `chisel3.stage.ChiselStage`. |
| `cd rtl && sbt run` | Pass. Emitted `rtl/generated/CcuMmio.v`. |
| Yosys 0.69+190 `read_verilog` / `techmap` / `check -assert` on that Verilog | Pass. 0 problems. `CcuMmio` 3319 cells, submodule `IntentNexus` 3087 cells. Not a standard-cell netlist. |
| `cd firmware && zig build test` | Pass on Zig 0.13.0. Host tests check layout and the entropy error, not multiplication. |
| `cd firmware && zig build` | Failed at Debug: `.text` overflowed the 64K ROM by 149544 bytes. Passes with ReleaseSmall (4.4K ELF). `firmware/build.zig` now defaults to ReleaseSmall so CI `zig build` matches the linker script. |
| `cd spice && ngspice -b nexus_nand.sp` | Pass. ngspice-39 printed `t_emergence = 5.003956e-09`. Placeholder level-1 models; not a 32nm result. |

No process, area, or clock claim. The multiplier is the low 32 bits of `rawIntent * information`, gated by `passionBound`.
