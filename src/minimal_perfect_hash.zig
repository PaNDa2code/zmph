const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

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

pub fn MinimalPerfectHashMap(K: type, V: type) type {
    return struct {
        const Self = @This();
        const v_fill: V = undefined;
        const max_usize: comptime_int = std.math.maxInt(usize);

        const empty_disps = [0]isize{};
        const empty_keys = [0]K{};
        const empty_values = [0]V{};

        const empty_kvs = KVs{
            .keys = &empty_keys,
            .values = &empty_values,
            .len = 0,
        };

        const KVs = struct {
            keys: [*]const K,
            values: [*]const V,
            len: usize,
        };

        kvs: *const KVs = &empty_kvs,
        len: usize = 0,
        displacement_table: []isize = &empty_disps,
        allocator: Allocator = undefined,

        inline fn hash(key: K, seed: u32, mod_value: usize) usize {
            return std.hash.Murmur3_32.hashWithSeed(std.mem.asBytes(&key), seed) % mod_value;
        }

        // O(N²) runtime initial
        pub fn init(allocator: Allocator, kv_list: anytype) !Self {
            const n = kv_list.len;

            var keys = try allocator.alloc(K, n);
            var values = try allocator.alloc(V, n);
            var displacement_table = try allocator.alloc(isize, n);

            for (kv_list, 0..) |kv, i| {
                keys[i] = kv.@"0";
                values[i] = if (V == void) {} else kv.@"1";
            }

            var buckets = try allocator.alloc(ArrayList(usize), n);

            @memset(buckets, @TypeOf(buckets[0]).init(allocator));
            defer {
                for (buckets) |bucket| {
                    bucket.deinit();
                }
                allocator.free(buckets);
            }

            for (keys, 0..) |key, key_index| {
                try buckets[hash(key, 0, n)].append(key_index);
            }

            var slot_version: u32 = 0;
            var slots = try allocator.alloc(u32, n);
            defer allocator.free(slots);

            var bucket_index: usize = 0;

            for (buckets) |bucket| {
                bucket_index += 1;
                if (bucket.items.len <= 1) break;

                var displacement: u32 = 1;
                var item: usize = 0;

                while (item < bucket.items.len) {
                    const slot = hash(keys[bucket.items[item]], displacement, n);

                    if (slots[slot] == slot_version) {
                        displacement += 1;
                        slot_version += 1;
                        item = 0;
                    } else {
                        slots[slot] = slot_version;
                        item += 1;
                    }
                }

                displacement_table[hash(keys[bucket.items[0]], 0, n)] = @intCast(displacement);

                for (0..bucket.items.len) |i| {
                    if (slots[i] == slot_version and V != void)
                        values[i] = bucket.items[i];
                }
            }

            var free_slots = ArrayList(usize).init(allocator);
            defer free_slots.deinit();

            for (values, 0..) |_, i| {
                if (slots[i] != slot_version)
                    try free_slots.append(i);
            }

            for (buckets[bucket_index..]) |bucket| {
                if (bucket.items.len == 0) continue;
                const slot = free_slots.pop();
                displacement_table[hash(keys[bucket.items[0]], 0, n)] = -@as(isize, @intCast(slot)) - 1;
            }

            const final_keys = keys.ptr;
            const final_values = values.ptr;
            var kvs = try allocator.create(KVs);
            kvs.keys = final_keys;
            kvs.values = final_values;
            kvs.len = n;
            const final_kvs = kvs;
            return .{
                .kvs = final_kvs,
                .allocator = allocator,
                .displacement_table = displacement_table,
                .len = n,
            };
        }

        pub fn deinit(self: *const Self) void {
            self.allocator.free(self.kvs.keys[0..self.len]);
            self.allocator.free(self.kvs.values[0..self.len]);
            self.allocator.destroy(self.kvs);
            self.allocator.free(self.displacement_table[0..self.len]);
        }

        pub fn getIndex(self: *const Self, key: K) ?usize {
            const displacement = self.displacement_table[hash(key, 0, self.len)];
            const slot: usize = if (displacement < 0) @intCast(-displacement - 1) else hash(key, @intCast(displacement), self.len);
            return slot;
        }
    };
}
