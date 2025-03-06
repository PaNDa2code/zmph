# Zig minimal prefect hash-map

ZMPH is a Zig module that helps you create a fast, compile-time, minimal [perfect hash map](https://en.wikipedia.org/wiki/Perfect_hash_function). It leverages Zig's comptime feature to generate efficient, collision-free mappings at compile time, making lookups extremely fast.

read more
- [Minimal Perfect Hash Function University of Waterloo](https://cs.uwaterloo.ca/~dstinson/papers/aticihash.pdf)
- [Throw away the keys: Easy, Minimal Perfect Hashing](https://stevehanov.ca/blog/?id=119)

```
➜ lscpu | grep "Model name"

Model name:                      Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz

➜ zig build benchmark --release=fast
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995      
-----------------------------------------------------------------------------------------------------------------------------
zmph build             63       2.01s          31.909ms ± 899.684us   (30.921ms ... 35.033ms)      32.069ms   35.033ms   35.033ms  
zmph Lookup            100000   1.922ms        19ns ± 96ns            (14ns ... 25.791us)          22ns       27ns       30ns      
StaticStringMap build  894      1.985s         2.221ms ± 63.571us     (2.171ms ... 3.021ms)        2.239ms    2.426ms    2.53ms    
StaticStringMap Lookup 100000   1.078s         10.78us ± 7.558us      (23ns ... 120.186us)         16.202us   28.691us   31.683us  
StringHashMap build    285      2.001s         7.022ms ± 118.496us    (6.807ms ... 8.191ms)        7.043ms    7.384ms    7.749ms   
StringHashMap Lookup   100000   6.785ms        67ns ± 150ns           (22ns ... 26.765us)          68ns       417ns      536ns 
```

### Benchmark Environment:
The following benchmark results were obtained on my machine:
- CPU: Intel Core i7-8750H @ 2.20GHz
- OS: Linux Debian 
- Zig Version: 0.14.0-dev.3237+ddff1fa4c

### Observations
- ZMPH Lookup (19ns avg) is the fastest lookup implementation.
- StaticStringMap Lookup (10.78µs avg) is significantly slower (~500x slower than ZMPH).
- StringHashMap Lookup (67ns avg) is about 3.5x slower than ZMPH but still much faster than StaticStringMap.

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

