# Minimal perfect hash function generator


```
➜ zig build benchmark --release=fast
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995      
-----------------------------------------------------------------------------------------------------------------------------
zmph build             15       1.026s         68.466ms ± 11.425ms    (53.18ms ... 88.944ms)       80.24ms    88.944ms   88.944ms  
zmph Lookup            65535    1.301ms        19ns ± 10ns            (14ns ... 1.524us)           23ns       28ns       33ns      
StaticStringMap build  1023     1.962s         1.918ms ± 139.463us    (1.791ms ... 2.744ms)        1.943ms    2.417ms    2.503ms   
StaticStringMap Lookup 65535    766.088ms      11.689us ± 8.357us     (25ns ... 106.524us)         16.859us   35.86us    44.843us  
StringHashMap build    255      1.476s         5.791ms ± 468.839us    (5.37ms ... 8.905ms)         5.968ms    8.531ms    8.607ms   
StringHashMap Lookup   65535    1.541ms        23ns ± 226ns           (16ns ... 19.731us)          23ns       30ns       34ns      
```

## How to use

inside your project directory run:

```bash
zig fetch --save git+https://github.com/PaNDa2code/zmph
```

then in `build.zig` file add `zmph` as import for project excutable:
```zig
const zmph = b.dependency("zmph", .{});

const exe = b.addExecutable(.{
    ...
});

exe.root_module.addImport("zmph", zmph.module("zmph"));
```

now you can use it inside your project
```zig
const std = @import("std");
const zmph = @import("zmph");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const map = try zmph.FrozenHashMap([]const u8, u64).init(allocator, kv_list);
    defer map.deinit();

    for (kv_list) |kv| {
        std.debug.print("{s}:{any}\n", .{ kv[0], map.get(kv[0]) });
    }
}

const kv_list = [2]struct { []const u8, u64 }{
    .{ "Hello", 0 },
    .{ "World", 1 },
};

```

you can also define a comptime hash map using `comptimeInit`
```zig
const std = @import("std");
const zmph = @import("zmph");

pub fn main() !void {
    const map = zmph.FrozenHashMap([]const u8, u64).comptimeInit(kv_list);

    for (kv_list) |kv| {
        std.debug.print("{s}:{any}\n", .{ kv[0], map.get(kv[0]) });
    }
}

// you can you tuples in comptime init, but not in runtime init
const kv_list = .{
    .{ "Hello", 0 },
    .{ "World", 1 },
};
```

for more examples look at [examples](./examples/)

