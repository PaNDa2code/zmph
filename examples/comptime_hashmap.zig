const std = @import("std");
const zmph = @import("zmph");

pub fn main() !void {
    const map = zmph.PerfectHashMap([]const u8, u64).comptimeInit(kv_list);

    const value = map.get("Hello");

    if (value) |v| {
        std.debug.print("{}\n", .{v});
    }
}

// you can you tuples in comptime init, but not in runtime init
const kv_list = .{
    .{ "Hello", 0 },
    .{ "World", 1 },
};
