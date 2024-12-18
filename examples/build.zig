const std = @import("std");

pub fn build(b: *std.Build) void {
    const example_file = b.option([]const u8, "example", "Name of the example to run (e.g., comptime_hashmap.zig)") orelse "comptime_hashmap.zig";

    const target = b.standardTargetOptions(.{});
    const optmize = b.standardOptimizeOption(.{});

    const zmph = b.addModule("zmph", .{
        .root_source_file = b.path("../src/minimal_perfect_hash.zig"),
    });

    const exmaple_exe = b.addExecutable(.{
        .name = "exmaple",
        .target = target,
        .optimize = optmize,
        .root_source_file = b.path(example_file),
    });

    exmaple_exe.root_module.addImport("zmph", zmph);

    const exmaple_run = b.addRunArtifact(exmaple_exe);

    const exmaple_run_step = b.step("run", "run exmaple for using zmph");

    exmaple_run_step.dependOn(&exmaple_run.step);
}
