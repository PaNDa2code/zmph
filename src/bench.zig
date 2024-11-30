const std = @import("std");
const time = std.time;
const MinimalPHF = @import("minimal_perfect_hash.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const path = "/usr/share/dict/words";

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 1024 * 1024 * 5);
    defer allocator.free(buffer);

    var iter = std.mem.tokenizeAny(u8, buffer, "\n");
    var words = std.ArrayList([]const u8).init(allocator);
    defer words.deinit();

    while (iter.next()) |word| {
        try words.append(word);
    }

    const tik = time.nanoTimestamp();
    var mphf_runtime = try MinimalPHF.init(allocator, words.items);
    const tok = time.nanoTimestamp();
    defer mphf_runtime.deinit();

    for (words.items) |word| {
        if (mphf_runtime.getIndex(word) == null) @panic("getIndex() returns null value");
    }
    const tok2 = time.nanoTimestamp();

    const elapsed_init = tok - tik;
    const elapsed_lookup = tok2 - tok;
    const elapsed_per_lookup = @divFloor(elapsed_lookup, words.items.len);

    std.debug.print("---- Run time Initialization ----\n", .{});
    std.debug.print("Keys processed: {} strings\n", .{words.items.len});
    printWithUnits("Initialization time", elapsed_init);
    printWithUnits("Lookup time", elapsed_lookup);
    printWithUnits("One lookup time", elapsed_per_lookup);
}

fn printWithUnits(description: []const u8, value: i128) void {
    var scaledValue: f128 = @floatFromInt(value);
    const units = [_][]const u8{ "ns", "µs", "ms", "s" };
    var unitIndex: usize = 0;
    while (scaledValue >= 1000 and unitIndex < units.len - 1) {
        scaledValue /= 1000;
        unitIndex += 1;
    }
    std.debug.print("{s: <25}: {d: >7.3} {s}\n", .{ description, scaledValue, units[unitIndex] });
}
