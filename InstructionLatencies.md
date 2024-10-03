# Instruction Latencies

| Instruction | Latency | Throughput |
|:---|:----:|:----:|
| mv rd, rs1 | 0* | 2 |
| Zba,Zbb,Zbs instructions | 1 | 2 |
| All arithmeitc instructions | 1 | 2 |
| lui rd, imm | 1 | 2 |
| auipc rd, imm | 1 | 1 |
| All branch instructions | 1 | 1 |
| All PSX instructions | 1 | 2 |
| Multiplications | at least 5 | 1/5 |
| Divisions | at least 34 | 1/34 |
| lb,lh,lw,lbu,lhu | at least 4* | 1 |
| sb,sh,sw | at least 3* | 1 |
| All CSR operations | 3 | 1/3 |

Latencies measured from the start of the cycle after Register Read

0* The mv pseudo instruction is recognised by the CPU and eliminated from the instruction stream, (only present in RCU and not scheduler/pipeline).
Note that chaining dependent mov's together does not change this, it is handled by the rename logic.

3* The store instructions results are placed in a store buffer, hence commit to the memory system eventually with variable latencies taken to store.

4* Loads actually finish executing in 3 stages, but do not do forwarding like the integer ALU's do, hence taking till the start of the 4th clock since execution to obtain the correct value from the Physical Register File.

Divisions and Multiplications are out of pipe, and write back to a moment where the load engine does not write a value back to the PRF.

Note that the CPU is up to tri-issue, two arithmetic instructions and 1 of mul/div/csr/mem.