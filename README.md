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
