const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const zbench = b.dependency("zbench", .{});

    const lib = b.addSharedLibrary(.{
        .name = "MinimalPerfectHash",
        .root_source_file = b.path("src/minimal_perfect_hash.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const test_step = b.step("test", "Run unit tests");
    const benchmark_step = b.step("benchmark", "Run benchmarks");

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib_benchmark = b.addExecutable(.{
        .name = "benchmark",
        .root_source_file = b.path("src/bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    const run_lib_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_lib_unit_tests.step);

    lib_benchmark.root_module.addImport("zbench", zbench.module("zbench"));
    const run_lib_benchmark = b.addRunArtifact(lib_benchmark);
    benchmark_step.dependOn(&run_lib_benchmark.step);
}
