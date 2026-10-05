//! Driver for the Conscious Coherence Unit (a gated 32-bit multiplier with an
//! idle-cycle counter). Register layout must match rtl/.../CcuMmio.scala.
const std = @import("std");

pub const BASE_ADDR: usize = 0x4000_1000;

/// Every register is a full 32-bit word; extern gives C layout (packed would
/// not allow the padding trick the original sketch used).
pub const Registers = extern struct {
    raw_intent: u32, // 0x00
    information: u32, // 0x04
    passion_bound: u32, // 0x08 (bit 0)
    emergent_structure: u32, // 0x0C (RO)
    system_entropy: u32, // 0x10 (RO, bits 7:0)
};

comptime {
    std.debug.assert(@offsetOf(Registers, "passion_bound") == 0x08);
    std.debug.assert(@offsetOf(Registers, "emergent_structure") == 0x0C);
    std.debug.assert(@offsetOf(Registers, "system_entropy") == 0x10);
}

pub const ENTROPY_LIMIT: u32 = 200;

pub const Error = error{EntropyExceeded};

pub const Ccu = struct {
    regs: *volatile Registers,

    pub fn init(base: usize) Ccu {
        return .{ .regs = @ptrFromInt(base) };
    }

    /// Multiply `a * b` (low 32 bits) on the CCU.
    ///
    /// `system_entropy` counts cycles since the unit was last bound, so it is
    /// checked *before* binding; once bound it is always cleared.
    pub fn compute(self: Ccu, a: u32, b: u32) Error!u32 {
        if ((self.regs.system_entropy & 0xFF) > ENTROPY_LIMIT) return error.EntropyExceeded;

        self.regs.raw_intent = a;
        self.regs.information = b;
        self.regs.passion_bound = 1;
        fence();
        const result = self.regs.emergent_structure;
        self.regs.passion_bound = 0;
        return result;
    }
};

inline fn fence() void {
    switch (@import("builtin").cpu.arch) {
        .riscv32, .riscv64 => asm volatile ("fence iorw, iorw" ::: "memory"),
        else => {},
    }
}

test "register layout matches RTL offsets" {
    try std.testing.expectEqual(@as(usize, 0x14), @sizeOf(Registers));
}

test "compute against a simulated register block" {
    // Host-side stand-in: emulate the RTL's behavior in plain memory.
    var fake = Registers{
        .raw_intent = 0,
        .information = 0,
        .passion_bound = 0,
        .emergent_structure = 0,
        .system_entropy = 0,
    };
    // The fake can't react to writes, so pre-load the expected product.
    fake.emergent_structure = 42;
    const ccu = Ccu{ .regs = &fake };
    try std.testing.expectEqual(@as(u32, 42), try ccu.compute(6, 7));
    try std.testing.expectEqual(@as(u32, 0), fake.passion_bound);

    fake.system_entropy = 201;
    try std.testing.expectError(error.EntropyExceeded, ccu.compute(1, 1));
}
