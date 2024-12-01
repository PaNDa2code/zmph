const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Self = @This();
const usize_max: comptime_int = 1 << 32;

keys: []const []const u8,
n: usize = 0,
displacement_table: []isize = undefined,
values: []usize = undefined,
allocator: Allocator = undefined,

inline fn hash(key: []const u8, seed: u32, mod_value: usize) usize {
    return std.hash.Murmur3_32.hashWithSeed(key, seed) % mod_value;
}

const Bucket = ArrayList(usize);

fn staticList(comptime T: type, comptime n: usize, comptime fill: T) type {
    return struct {
        items: [n]T = [_]T{fill} ** n,
        len: usize = 0,
        fn decOrder(_: void, lhs: @This(), rhs: @This()) bool {
            return lhs.len > rhs.len;
        }
        fn append(self: *@This(), value: T) void {
            self.items[self.len] = value;
            self.len += 1;
        }
        fn pop(self: *@This()) T {
            self.len -= 1;
            return self.items[self.len];
        }
        fn clear(self: *@This()) void {
            // @memset(self.items, 0);
            self.len = 0;
        }
        fn has(self: *@This(), value: T) bool {
            for (self.items) |item| {
                if (value == item) return true;
            }
            return false;
        }
    };
}

pub inline fn comptimeInit(comptime keys: []const []const u8) !Self {
    comptime {
        @setEvalBranchQuota(1_000_000);
        const n = keys.len;

        const BucketComptime = staticList(usize, n, 0);

        var buckets = staticList(BucketComptime, n, .{}){};

        for (keys, 0..) |key, key_index| {
            buckets.items[hash(key, 0, n)].append(key_index);
        }

        std.mem.sort(BucketComptime, &buckets.items, {}, BucketComptime.decOrder);

        var slots = staticList(usize, n, 0){};
        var displacement_table = staticList(isize, n, 0){};
        var values = staticList(usize, n, usize_max){};

        var bucket_index: usize = 0;

        for (buckets.items, 0..) |bucket, bucket_idx| {
            bucket_index = bucket_idx;
            if (bucket.len <= 1) break;

            var displacement: u32 = 1;
            var item: usize = 0;
            slots.clear();

            while (item < bucket.len) {
                const slot = hash(keys[bucket.items[item]], displacement, n);

                if (values.items[slot] != usize_max or slots.has(slot)) {
                    displacement += 1;
                    item = 0;
                    slots.clear();
                } else {
                    slots.append(slot);
                    item += 1;
                }
            }

            displacement_table.items[hash(keys[bucket.items[0]], 0, n)] = @intCast(displacement);

            for (0..bucket.len) |i| {
                values.items[slots.items[i]] = bucket.items[i];
            }
        }

        var free_slots = staticList(usize, n, 0){};
        for (values.items, 0..) |val, i| {
            if (val == usize_max)
                free_slots.append(i);
        }

        for (buckets.items[bucket_index..]) |bucket| {
            if (bucket.len == 0) continue;
            const slot = free_slots.pop();
            displacement_table.items[hash(keys[bucket.items[0]], 0, n)] = -@as(isize, @intCast(slot)) - 1;
            values.items[slot] = 0;
        }

        const _values = values.items;
        const _dispacement_table = displacement_table.items;

        return .{
            .n = n,
            .keys = keys,
            .values = @ptrCast(@constCast(&_values)),
            .displacement_table = @ptrCast(@constCast(&_dispacement_table)),
        };
    }
}

pub fn init(allocator: Allocator, keys: []const []const u8) !Self {
    const self = Self{
        .keys = keys,
        .n = keys.len,
        .displacement_table = try allocator.alloc(isize, keys.len),
        .values = try allocator.alloc(usize, keys.len),
        .allocator = allocator,
    };

    @memset(self.values, usize_max);

    var buckets = try allocator.alloc(Bucket, self.n);
    defer {
        for (buckets) |bucket| {
            bucket.deinit();
        }
        allocator.free(buckets);
    }

    @memset(buckets, Bucket.init(allocator));

    // Step 1: Assign keys to buckets using the first hash function
    for (keys, 0..) |key, key_index| {
        try buckets[hash(key, 0, self.n)].append(key_index);
    }

    // Step 2: Sort buckets by size in descending order
    // std.mem.sort(Bucket, buckets, {}, bucketDecOrder);

    // Step 3: Resolve collisions with displacement
    var slot_version: u32 = 0;
    var slots = try allocator.alloc(u32, keys.len);
    defer allocator.free(slots);

    var bucket_index: usize = 0;
    for (buckets, 0..) |bucket, idx| {
        bucket_index = idx;
        if (bucket.items.len <= 1) break; // Skip buckets with only one key

        var displacement: u32 = 1;
        var item: usize = 0;

        while (item < bucket.items.len) {
            const slot = hash(self.keys[bucket.items[item]], displacement, self.n);

            // If slot is occupied, try a new displacement
            if (self.values[slot] != usize_max or slots[slot] == slot_version) {
                // Reset to start over with a new displacement
                displacement += 1;
                slot_version += 1;
                item = 0;
            } else {
                slots[slot] = slot_version;
                item += 1;
            }
        }

        // Store the calculated displacement for this bucket
        self.displacement_table[hash(self.keys[bucket.items[0]], 0, self.n)] = @intCast(displacement);

        // Assign slots to the values array
        for (0..bucket.items.len) |i| {
            if (slots[i] == slot_version)
                self.values[i] = bucket.items[i];
        }
    }

    // Step 4: Assign single-key buckets directly to free slots
    var free_slots = ArrayList(usize).init(allocator);
    defer free_slots.deinit();
    for (self.values, 0..) |val, i| {
        if (val == usize_max)
            try free_slots.append(i);
    }

    // Step 5: Place keys with only one item in the bucket into the free slots
    for (buckets[bucket_index..]) |bucket| {
        if (bucket.items.len == 0) continue; // Skip empty buckets
        const slot = free_slots.pop();
        self.displacement_table[hash(self.keys[bucket.items[0]], 0, self.n)] = -@as(isize, @intCast(slot)) - 1;
        self.values[slot] = bucket.items[0];
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.displacement_table);
    self.allocator.free(self.values);
}

fn bucketDecOrder(_: void, lhs: Bucket, rhs: Bucket) bool {
    return lhs.items.len > rhs.items.len;
}

pub fn getIndex(self: *const Self, key: []const u8) ?usize {
    const displacement = self.displacement_table[hash(key, 0, self.n)];
    const slot: usize = if (displacement < 0) @intCast(-displacement - 1) else hash(key, @intCast(displacement), self.n);
    return slot;
}

pub fn get(self: *const Self, key: []const u8) ?usize {
    return self.values[self.getIndex(key) orelse return null];
}
