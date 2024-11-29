const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Self = @This();
const usize_max = 1 << 32;

keys: []const []const u8,
n: usize,
displacement_table: []isize,
values: []usize,
allocator: Allocator,

inline fn hash(key: []const u8, seed: u32, mod_value: usize) usize {
    return std.hash.Murmur3_32.hashWithSeed(key, seed) % mod_value;
}

const Bucket = ArrayList(usize);

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
    std.mem.sort(Bucket, buckets, {}, bucketDecOrder);

    // Step 3: Resolve collisions with displacement
    var slots = ArrayList(usize).init(allocator);
    defer slots.deinit();

    var bucket_index: usize = 0;
    for (buckets, 0..) |bucket, idx| {
        bucket_index = idx;
        if (bucket.items.len <= 1) break; // Skip buckets with only one key

        var displacement: u32 = 1;
        var item: usize = 0;
        slots.clearRetainingCapacity(); // Clear slots list for each new displacement

        while (item < bucket.items.len) {
            const slot = hash(self.keys[bucket.items[item]], displacement, self.n);

            // If slot is occupied, try a new displacement
            if (self.values[slot] != usize_max or std.mem.containsAtLeast(usize, slots.items, 1, &.{slot})) {
                displacement += 1;
                item = 0; // Reset to start over with a new displacement
                slots.clearRetainingCapacity(); // Clear slots to retry finding a slot
            } else {
                try slots.append(slot);
                item += 1;
            }
        }

        // Store the calculated displacement for this bucket
        self.displacement_table[hash(self.keys[bucket.items[0]], 0, self.n)] = @intCast(displacement);

        // Assign slots to the values array
        for (0..bucket.items.len) |i| {
            self.values[slots.items[i]] = bucket.items[i];
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

pub fn getIndex(self: *Self, key: []const u8) ?usize {
    const displacement = self.displacement_table[hash(key, 0, self.n)];
    const pos: usize = if (displacement < 0) @intCast(-displacement - 1) else hash(key, @intCast(displacement), self.n);
    const idx = self.values[pos];
    return if (std.mem.eql(u8, key, self.keys[idx])) idx else null;
}
