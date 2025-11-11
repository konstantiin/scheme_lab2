execute following to run tests:
```
iverilog -o test.vvp src/test_bench.v
vvp test.vvp
```
execute following to view visualization:
```
gtkwave wave.vcd
```