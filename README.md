# Minimal perfect hash function generator


```
➜ zig build benchmark --release=fast
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995      
-----------------------------------------------------------------------------------------------------------------------------
zmph build             15       1.186s         79.101ms ± 4.169ms     (75.016ms ... 90.168ms)      81.962ms   90.168ms   90.168ms  
zmph Lookup            65535    1.743ms        26ns ± 1ns             (24ns ... 216ns)             27ns       29ns       29ns      
StaticStringMap build  511      1.888s         3.694ms ± 236.867us    (3.533ms ... 5.339ms)        3.721ms    4.636ms    5.038ms   
StaticStringMap Lookup 65535    1.066s         16.277us ± 11.8us      (43ns ... 192.855us)         24.351us   45.514us   49.221us  
StringHashMap build    127      1.367s         10.767ms ± 638.794us   (9.723ms ... 13.462ms)       10.975ms   13.425ms   13.462ms  
StringHashMap Lookup   65535    2.668ms        40ns ± 52ns            (32ns ... 9.163us)           44ns       62ns       126ns     

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

    const map = try zmph.MinimalPerfectHashMap([]const u8, u64).init(allocator, kv_list);
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

    const map = comptime zmph.MinimalPerfectHashMap([]const u8, u64).comptimeInit(kv_list);

    for (kv_list) |kv| {
        std.debug.print("{s}:{any}\n", .{ kv[0], map.get(kv[0]) });
    }
}

const kv_list = [2]struct { []const u8, u64 }{
    .{ "Hello", 0 },
    .{ "World", 1 },
};
```
