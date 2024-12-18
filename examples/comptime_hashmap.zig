const std = @import("std");
const zmph = @import("zmph");

pub fn main() !void {
    const map = zmph.MinimalPerfectHashMap([]const u8, u64).comptimeInit(kv_list);

    for (kv_list) |kv| {
        std.debug.print("{s}:{?s}\n", .{ kv[0], map.get(kv[0]) });
    }
}

// you can you tuples in comptime init, but not in runtime init
const kv_list = .{
    .{ "Hello", 0 },
    .{ "World", 1 },
};
