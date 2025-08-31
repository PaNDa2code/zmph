# Zig minimal prefect hash-map

ZMPH is a Zig module that helps you create a fast, compile-time, minimal [perfect hash map](https://en.wikipedia.org/wiki/Perfect_hash_function). It leverages Zig's comptime feature to generate efficient, collision-free mappings at compile time, making lookups extremely fast.

read more
- [Minimal Perfect Hash Function University of Waterloo](https://cs.uwaterloo.ca/~dstinson/papers/aticihash.pdf)
- [Throw away the keys: Easy, Minimal Perfect Hashing](https://stevehanov.ca/blog/?id=119)

```

➜ lscpu | grep "Model name"

Model name:                      Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz

➜ zig build benchmark --release=fast
benchmark              runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995
----------------------------------------------------------------------------------------------------------------------------

zmph build             69       1.992s         28.872ms ± 617.072us  (28.361ms ... 32.443ms)      28.947ms   32.443ms   32.443ms
zmph Lookup            100000   2.653ms        26ns ± 4ns            (18ns ... 96ns)              30ns       38ns       40ns
StaticStringMap build  987      2.002s         2.029ms ± 56.593us    (1.96ms ... 2.385ms)         2.044ms    2.243ms    2.318ms
StaticStringMap Lookup 100000   1.04s          10.4us ± 7.359us      (22ns ... 89.198us)          15.693us   27.708us   30.958us
StringHashMap build    296      1.805s         6.1ms ± 83.67us       (5.972ms ... 6.595ms)        6.139ms    6.401ms    6.419ms
StringHashMap Lookup   100000   4.506ms        45ns ± 152ns          (22ns ... 29.795us)          49ns       106ns      123ns

````

### Benchmark Environment:
The following benchmark results were obtained on my machine:
- CPU: Intel Core i7-8750H @ 2.20GHz
- OS: Linux Debian 
- Zig Version: 0.14.0-dev.3237+ddff1fa4c

### Observations:

#### Lookup Performance

- **ZMPH Lookup (26ns avg)** is the fastest.  
- **StaticStringMap Lookup (10.4µs avg)** is ~400× slower than ZMPH, which makes sense since it’s doing a binary search.  
- **StringHashMap Lookup (45ns avg)** is ~1.7× slower than ZMPH but still orders of magnitude faster than StaticStringMap.

#### Build Performance

- **ZMPH Build:** ~28.9ms per run.  
- **StaticStringMap Build:** ~2.03ms per run.  
- **StringHashMap Build:** ~6.1ms per run.  

This means ZMPH is ~14× slower to build than StaticStringMap and ~5× slower than StringHashMap.

### Conclusion

- **ZMPH provides the fastest runtime lookups**, which makes it ideal when query performance is critical.  
- The trade-off is **higher build cost** at compile time compared to other map types.  
- For use cases with **frequent lookups and rare builds**, ZMPH is the clear winner.  
- For cases where build time matters more (e.g. massive tables generated at build), StaticStringMap may be more attractive.

## How to use

inside your project directory run:

```bash
zig fetch --save git+https://github.com/PaNDa2code/zmph
````

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

    const map = try zmph.PerfectHashMap([]const u8, u64).init(allocator, kv_list);
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
    const map = zmph.PerfectHashMap([]const u8, u64).comptimeInit(kv_list);

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
