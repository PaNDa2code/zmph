const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "MinimalPerfectHash",
        .root_source_file = b.path("src/chd_minimal_perfect_hash.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const test_step = b.step("test", "Run unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_lib_unit_tests.step);
}
