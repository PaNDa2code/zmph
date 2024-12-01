# Minimal perfect hash function generator


```
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995      
-----------------------------------------------------------------------------------------------------------------------------
Perfect-hash build     15       631.08ms       42.072ms ± 1.239ms     (40.737ms ... 45.121ms)      42.511ms   45.121ms   45.121ms  
Perfect-hash Lookup    65535    1.007ms        15ns ± 68ns            (13ns ... 17.449us)          16ns       17ns       17ns      
StaticStringMap build  255      627.59ms       2.461ms ± 169.721us    (2.31ms ... 3.131ms)         2.474ms    3.074ms    3.104ms   
StaticStringMap Lookup 65535    605.688ms      9.242us ± 6.855us      (24ns ... 77.5us)            13.596us   28.77us    34.501us  
StringHashMap build    127      809.626ms      6.375ms ± 623.466us    (5.703ms ... 10.114ms)       6.367ms    9.938ms    10.114ms  
StringHashMap Lookup   65535    1.337ms        20ns ± 106ns           (16ns ... 17.331us)          22ns       29ns       31ns
```
