// Targets Zig 0.13.x. Build: `zig build` -> zig-out/bin/intent-v.elf
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .m }),
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "intent-v.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });
    exe.setLinkerScript(b.path("linker.ld"));
    b.installArtifact(exe);

    // Host-side unit tests for the register-level logic (no hardware needed).
    const host_tests = b.addTest(.{
        .root_source_file = b.path("src/ccu.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(host_tests);
    b.step("test", "Run host-side unit tests").dependOn(&run_tests.step);
}
