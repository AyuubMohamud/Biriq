# OoO Engine
The Out of Order Engine contains:
- The Rename module
- Register Status Bits
- Register Reference Table
- Speculative Register Remap Table
- Committed Register Remap Table
- Register Freelist
- Completed Instruction bits
- Interrupt Router
- Retire Control Unit
- Integer Register File

## Register Status Bits
Controls whether an instruction during the rename stage is referencing a busy or ready register.
Made of a collection of LUTRAMs, made into a multiport RAM by XORing them.
## Committed Register Remap Table
Holds physical register numbers that point to the data for a certain architectural register (i.e. Indexing this table by 2 gives you register sp).
## Speculative Register Remap Table
Holds physical register numbers speculated to point to data for a certain architecture register. Also spots when two instructions are presented to the decoder and the later one depends on the earlier one.
## Register Reference Table
This holds the active count of how many times a physical register is referenced in the Committed Register Remap Table. When the reference count goes to 0, safe_to_free goes high and the physical register is put back into the freelist.
## Integer Register File
This is the 6r3w 32-bit integer register file with 64 entries.
## Freelist
Two fifos with balancing logic. Holds free physical registers. Never fills up. (Or **should** never fill up)
## Interrupt Router
Take the meip, mtip and msip signals and prioritise them as per the RISC-V spec.
## Completed Instruction Bits
Set to 0 on instruction commit, set to 1 when an instruction has been executed (doesn't have to be without exceptions).
## Rename Module
The rename module renames the registers in a RISC-V instruction, and delivers the instruction to either the memory scheduler or the MEU.