This is a yet to be fully verified 2-way superscalar, out-of-order speculative RV32IMB_Zicond_Zifencei_Zicsr implementation with Machine and User support.

Properties:
- A configurable BTB/RAS storing both targets and bimodal prediction counters.
- 8KB I-Cache and 8KB write-through D-Cache, both with 128 byte cache lines.
- 10-entry Store Buffer/Queue (holds both speculative and commited results)
- A branch mispredict recovery delay of 16 cycles.
- Move elimniation supported using the pseudo-instruction mov present in RISC-V assembler.
- Non-blocking Loads.
- 64 physical registers with PR0 mapped permanently to $zero.
- Forwarding for both integer ALU's and branch unit.
- Up to 32 instructions in flight.

Queue capacities:
Up to 16 memory/mul/div/csr instructions
up to 12 ALU/Branch instructions.

Branches are scheduled on the second time round to avoid a ALU instruction taking a branch capable slot over a branch within the UIQ.
The ALU/Branch scheduler is unified to enable efficient use of CPU resources.
All ALU's support most of the base integer and all bit manipulation instructions alongside Zicond.

Pipeline is as follows:
- IF1: generate PC and predict.
- ICache: fetch instruction from cache or miss and fill.
- Predecode: Prepare and decode operands as necessary to simplify rename.
- READ: Rename/Eliminate(MOV's from instruction stream)/Allocation(of free registers and scheduler slots)/Dispatch to Schedulers
- Issue: Issue to a specific functional unit.

From here on it splits into three pipelines: Integer, Memory and Mul/Div/CSR.

Integer: Register Read, Execute, Writeback\
Loads: AGEN, Detect unaligned, Cache Read and conflict detect, Writeback

When a load conflicts with more than one store it is held until it is the oldest instruction in the system and forces the RCU not to take exceptions/interrupts whilst it executes. This property holds regardless of whether the load is to the CPU's memory or IO region.

Loads to the IO region, whilst weakly ordered (in the sense that later loads can come ahead of earlier stores), they are not allowed to execute speculatively and stops the ROB
from executing interrupts during that time.

Stores: AGEN, Detect unaligned, Enqueue (into store buffer)

Multiplies and Divides get sent to the complex unit which stores instruction information in a seperate register, whilst letting non-M instructions execute in the meanwhile, and only writing back on a cycle where the wb_valid of the load unit is low.

Special instructions FENCE.I, MRET, WFI do not get assigned to any functional unit but rather go straight to the RCU, where they are held until they are the oldest instruction to be committed, where the RCU will proceed to execute them.

Improvements:
- Add ebreak into decoder (done)
- Make divider and multiplier out of pipe (done)
- Add in timeout wait (done)
- Fix RAS (done)
- Fix the load pipeline, and improve non-blocking cache (done, but needs more testing)
- Add in coherent I/O by means of a port into the data cache (complete)
- Optimise multiplier
- Add in supervisor mode.
- Add configurable PMAs
- Add PMP for NAPOT only with >1024 byte granules
- Add atomic instructions for both IO and non IO regions
- Make dcache/icache more bus agnostic to enable different bus implementations (AXI, AHB, Wishbone)
- Make more parameters configurable

This core supports a regular TileLink Uncached Heavyweight bus at 32-bit data width, and 32-bit address width.

This core is licenced under the CERN OHL v2.0 - Weakly Reciprocal.