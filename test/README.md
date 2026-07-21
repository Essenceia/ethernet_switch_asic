# Simulation testbench 

Using both pure RTL and gate level simulation. 

## Usage 

Run classic sim using icarus on raw verilog files: 
```
make
```

Select alterative simulator like `verilator` : 
```
make GATES=yes SIM=verilator
```

Use icarus with gate level netlist and pdk supplied timing models: 
```
make GATES=yes
```

Enable waves `WAVES=1` (set by default) 
```
make WAVES=1
```
