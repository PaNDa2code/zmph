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

    const tik = time.milliTimestamp();
    var mphf = try MinimalPHF.init(allocator, words.items);
    const tok = time.milliTimestamp();
    defer mphf.deinit();

    for (words.items) |word| {
        if (mphf.getIndex(word) == null) @panic("getIndex() returns null value");
    }
    const took = time.milliTimestamp();

    std.debug.print("Done initializing {} keys in {}ms\n", .{ words.items.len, tok - tik });
    std.debug.print("Done looking up for {} keys in {}ms\n", .{ words.items.len, took - tok });
}
