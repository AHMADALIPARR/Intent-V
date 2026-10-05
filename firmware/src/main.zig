const ccu = @import("ccu.zig");

export fn _start() linksection(".text.init") callconv(.Naked) noreturn {
    asm volatile (
        \\la sp, _stack_top
        \\call kmain
        \\1: j 1b
    );
}

export fn kmain() noreturn {
    const unit = ccu.Ccu.init(ccu.BASE_ADDR);
    _ = unit.compute(6, 7) catch halt();
    halt();
}

fn halt() noreturn {
    while (true) asm volatile ("wfi");
}

pub fn panic(_: []const u8, _: ?*@import("std").builtin.StackTrace, _: ?usize) noreturn {
    halt();
}
