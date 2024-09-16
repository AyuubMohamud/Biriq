Biriq Frontend

The frontend is in-order and consists of the following stages:
- PC Generation
- Instruction Cache access
- Decode

General overview:\
The Biriq frontend does not predict individual branches but rather predicts instructions packets. An instruction packet is simply just
two instructions at a 64-bit aligned address. The frontend predicts which instructions are the actual taken branch inside a packet and
masks off any instructions that are predicted not to be executed.

PC Generation:\
During PC generation, a tag is produced from the upper 29 bits of the program counter and compared against BTB entries at an index
produced from the tag. The logic then selects from one of the matching two ways and this produces a branch target address, a branch index
(which instruction is the branch), branch type info (whether it is an unconditional jump, a call, a conditional branch or a return), and
a bimodal prediction counter (only ever used for conditional branches). This information is then submitted together with the current
program counter to the instruction cache, and if the branch is taken the branch target becomes the new program counter value.