# Verification handoff

All code in this repo was written without sbt, zig or ngspice available, so
**nothing has been compiled or run.** This file is the checklist for whoever
verifies it first. Fix what breaks with minimal changes and report what you
changed.

## Run in order

```sh
cd rtl      && sbt test                       # Chisel 3.6.0 / chiseltest 0.6.2
cd rtl      && sbt run                        # emits rtl/generated/CcuMmio.v
cd firmware && zig build test                 # needs Zig 0.13.x
cd firmware && zig build                      # RV32IM freestanding ELF
cd spice    && ngspice -b nexus_nand.sp       # must print t_emergence
```

## Highest-risk spots (my best guesses at what fails)

1. **`rtl/build.sbt`**: the `addCompilerPlugin` line and dependency versions
   (Chisel 3.6.0 needs the `chisel3-plugin`; check Scala 2.13.10 resolves).
2. **`CcuMmio.scala`**: `switch`/`is` with `0x00.U` literals, and `Elaborate`
   using `chisel3.stage.ChiselStage` (deprecated but present in 3.6).
3. **`IntentNexusSpec.scala`**: the saturation test steps 300 cycles; the
   reset-on-bind test expects entropy to read 0 one cycle after `passionBound`.
4. **`firmware/build.zig`**: Zig build API moves between releases; written for
   0.13 (`b.path`, `resolveTargetQuery`, `cpu_features_add`).
5. **`firmware/src/main.zig`**: `callconv(.Naked)` + inline asm `_start`, and the
   0.13-style `pub fn panic` signature. The linker script entry symbol and
   section names (`.text.init`) must line up.
6. **`firmware/src/ccu.zig`**: `fence()` uses `asm volatile ("fence iorw, iorw"
   ::: "memory")`; the host test builds on x86/arm, where it compiles to nothing.
   The test's fake register block cannot react to writes (see below).
7. **`spice/nexus_nand.sp`**: `.measure` syntax differs across ngspice
   versions; `models.lib` is a level-1 placeholder, not a real 32nm PDK.

## Known limitations (not bugs to "fix" silently)

- The Zig host test pre-loads the product into the fake register block, so it
  checks layout and error handling, not multiplication. RTL tests cover the math.
- Zig `Registers` offsets must match `CcuMmio.scala` (0x00/04/08/0C/10). A
  cross-check (e.g. a generated header) does not exist yet.
- SPICE timing numbers are meaningless without a real process library.

## Report back

For each command above: pass/fail, the exact error, and the diff you applied.
If CI (`.github/workflows/ci.yml`) disagrees with your local result, say which
tool versions differ.
