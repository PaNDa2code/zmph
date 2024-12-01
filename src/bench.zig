const std = @import("std");
const time = std.time;
const MinimalPerfectHashMap = @import("minimal_perfect_hash.zig").MinimalPerfectHashMap;
const zbench = @import("zbench");

var word_list: []struct { []const u8, void } = undefined;
var word_idx: usize = 0;

var mphf: MinimalPerfectHashMap([]const u8, void) = undefined;
var static_map: std.static_string_map.StaticStringMap(void) = .{};
var hash_map: std.StringHashMap(void) = undefined;

var glop_allocator: std.mem.Allocator = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    glop_allocator = allocator;

    const path = "/usr/share/dict/words";

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 1024 * 1024 * 5);
    defer allocator.free(buffer);

    var iter = std.mem.tokenizeAny(u8, buffer, "\n");
    var words = std.ArrayList(struct { []const u8, void }).init(allocator);
    defer words.deinit();

    while (iter.next()) |word| {
        try words.append(.{ word, {} });
    }

    word_list = words.items;

    var bench = zbench.Benchmark.init(allocator, .{ .track_allocations = false });
    defer bench.deinit();

    try bench.add("Perfect-hash build", benchmarkInit, .{ .hooks = .{
        .after_each = MinimalPHF_After,
    } });
    try bench.add("Perfect-hash Lookup", benchmarkLookup, .{ .hooks = .{
        .before_all = MinimalPHF_Before,
        .after_all = MinimalPHF_After,
        .after_each = nextWord,
    } });
    try bench.add("StaticStringMap build", StaticMapInit, .{ .hooks = .{
        .after_each = StaticHashmapAfter,
    } });
    try bench.add("StaticStringMap Lookup", StaticMapLookup, .{ .hooks = .{
        .before_all = StaticHashmapBefore,
        .after_all = StaticHashmapAfter,
        .after_each = nextWord,
    } });
    try bench.add("StringHashMap build", StdHashmapBuild, .{ .hooks = .{
        .after_each = StdHashmapAfter,
    } });
    try bench.add("StringHashMap Lookup", StdHashmapLookup, .{ .hooks = .{
        .before_all = StdHashmapBefore,
        .after_all = StdHashmapAfter,
        .after_each = nextWord,
    } });
    try bench.run(std.io.getStdOut().writer());
}

fn nextWord() void {
    word_idx = (word_idx + 1) % word_list.len;
}

// |------------------- Minimal perfect hash bench functions ----------------|
fn benchmarkInit(allocator: std.mem.Allocator) void {
    mphf = @TypeOf(mphf).init(allocator, word_list) catch unreachable;
}

fn MinimalPHF_After() void {
    mphf.deinit();
}

fn MinimalPHF_Before() void {
    mphf = @TypeOf(mphf).init(glop_allocator, word_list) catch unreachable;
}

fn benchmarkLookup(_: std.mem.Allocator) void {
    _ = mphf.getIndex(word_list[word_idx].@"0");
}

// |------------------- StaticStringMap bench functions ---------------------|
fn StaticMapInit(allocator: std.mem.Allocator) void {
    static_map = @TypeOf(static_map).init(word_list, allocator) catch unreachable;
}

fn StaticHashmapAfter() void {
    static_map.deinit(glop_allocator);
}

fn StaticHashmapBefore() void {
    StaticMapInit(glop_allocator);
}

fn StaticMapLookup(_: std.mem.Allocator) void {
    _ = static_map.get(word_list[word_idx].@"0");
}

// |----------------- StdHashMap bench functions -------------------------|
fn StdHashmapBuild(allocator: std.mem.Allocator) void {
    hash_map = @TypeOf(hash_map).init(allocator);
    for (word_list) |word| {
        hash_map.put(word.@"0", {}) catch unreachable;
    }
}

fn StdHashmapBefore() void {
    StdHashmapBuild(glop_allocator);
}

fn StdHashmapAfter() void {
    hash_map.deinit();
}

fn StdHashmapLookup(_: std.mem.Allocator) void {
    _ = hash_map.get(word_list[word_idx].@"0");
}
