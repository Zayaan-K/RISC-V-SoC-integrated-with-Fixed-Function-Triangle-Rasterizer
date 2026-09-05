https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html

## RV32I Instruction Formats

RV32I instructions are always 32 bits wide. The instruction format determines how those 32 bits are divided into fields such as the opcode, source registers, destination register, function codes, and immediate value.

| Format | Example instructions | Primary purpose |
| --- | --- | --- |
| R-type | `ADD`, `SUB`, `AND`, `OR`, `XOR` | Register-to-register arithmetic and logical operations |
| I-type | `ADDI`, `LW`, `JALR` | Immediate arithmetic, memory loads, and indirect jumps |
| S-type | `SW`, `SH`, `SB` | Storing register values into memory |
| B-type | `BEQ`, `BNE`, `BLT` | Conditional PC-relative branches |
| U-type | `LUI`, `AUIPC` | Operations using a 20-bit upper immediate |
| J-type | `JAL` | Unconditional PC-relative jumps |

### Common Instruction Fields

| Field | Bit range | Width | Description |
| --- | --- | ---: | --- |
| `opcode` | `[6:0]` | 7 bits | Identifies the general instruction category |
| `rd` | `[11:7]` | 5 bits | Destination register |
| `funct3` | `[14:12]` | 3 bits | Further identifies the operation |
| `rs1` | `[19:15]` | 5 bits | First source register |
| `rs2` | `[24:20]` | 5 bits | Second source register |
| `funct7` | `[31:25]` | 7 bits | Further distinguishes related operations |
| `imm` | Varies | Varies | Immediate constant or address offset |

Registers are identified using five-bit fields because RV32I provides 32 integer registers:

```text
2^5 = 32 registers

## R-Type

```text
 31          25 24       20 19       15 14    12 11      7 6        0
┌──────────────┬───────────┬───────────┬────────┬──────────┬──────────┐
│ funct7 [6:0] │ rs2 [4:0] │ rs1 [4:0] │ funct3 │ rd [4:0] │  opcode  │
└──────────────┴───────────┴───────────┴────────┴──────────┴──────────┘
```

OP CODE = 0110011


funct3 & funct7 is used to determine specific operation

| Instruction | `funct7`  | `funct3` | Operation                              |
| ----------- | --------- | -------- | -------------------------------------- |
| `ADD`       | `0000000` | `000`    | `rd = rs1 + rs2`                       |
| `SUB`       | `0100000` | `000`    | `rd = rs1 - rs2`                       |
| `SLL`       | `0000000` | `001`    | `rd = rs1 << rs2[4:0]`                 |
| `SLT`       | `0000000` | `010`    | `rd = (signed(rs1) < signed(rs2))`     |
| `SLTU`      | `0000000` | `011`    | `rd = (unsigned(rs1) < unsigned(rs2))` |
| `XOR`       | `0000000` | `100`    | `rd = rs1 ^ rs2`                       |
| `SRL`       | `0000000` | `101`    | `rd = rs1 >> rs2[4:0]`                 |
| `SRA`       | `0100000` | `101`    | `rd = signed(rs1) >>> rs2[4:0]`        |
| `OR`        | `0000000` | `110`    | `rd = rs1 \| rs2`                      |
| `AND`       | `0000000` | `111`    | `rd = rs1 & rs2`                       |




## I-Type

```text
 31                    20 19       15 14    12 11      7 6        0
┌────────────────────────┬───────────┬────────┬──────────┬──────────┐
│      imm[11:0]         │ rs1 [4:0] │ funct3 │ rd [4:0] │  opcode  │
└────────────────────────┴───────────┴────────┴──────────┴──────────┘
```

| I-type family   | Opcode    | Instructions                                                           |
| --------------- | --------- | ---------------------------------------------------------------------- |
| Immediate ALU   | `0010011` | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| Loads           | `0000011` | `LB`, `LH`, `LW`, `LBU`, `LHU`                                         |
| Indirect jump   | `1100111` | `JALR`                                                                 |
| Memory ordering | `0001111` | `FENCE`                                                                |
| System          | `1110011` | `ECALL`, `EBREAK`                                                      |



Immediate ALU

| Instruction | `funct3` | Operation                     |
| ----------- | -------- | ----------------------------- |
| `ADDI`      | `000`    | `rd = rs1 + immediate`        |
| `SLTI`      | `010`    | Signed less-than comparison   |
| `SLTIU`     | `011`    | Unsigned less-than comparison |
| `XORI`      | `100`    | `rd = rs1 ^ immediate`        |
| `ORI`       | `110`    | `rd = rs1 \| immediate`       |
| `ANDI`      | `111`    | `rd = rs1 & immediate`        |
| `SLLI`      | `001`    | Logical left shift            |
| `SRLI`      | `101`    | Logical right shift           |
| `SRAI`      | `101`    | Arithmetic right shift        |

### Immediate Shift Instructions

For immediate shifts, `shamt[4:0]` specifies the shift amount.

| Instruction | `imm[11:5]` | `funct3` | Operation |
|---|---|---|---|
| `SLLI` | `0000000` | `001` | `rd = rs1 << shamt` |
| `SRLI` | `0000000` | `101` | `rd = rs1 >> shamt` |
| `SRAI` | `0100000` | `101` | `rd = signed(rs1) >>> shamt` |

Where:

`shamt = instruction[24:20]`

In RV32I, valid shift amounts range from 0 through 31.


All RV32I load instructions use the opcode `0000011`.

Address is calculated as [address = rs1 + sign_extend(immediate)]

| Instruction | `funct3` | Loaded value | Extension |
|---|---|---|---|
| `LB` | `000` | 8-bit byte | Sign-extended to 32 bits |
| `LH` | `001` | 16-bit halfword | Sign-extended to 32 bits |
| `LW` | `010` | 32-bit word | No extension required |
| `LBU` | `100` | 8-bit byte | Zero-extended to 32 bits |
| `LHU` | `101` | 16-bit halfword | Zero-extended to 32 bits |

JALR performs an indirect jump.


| Instruction | Opcode    | `funct3` | Operation                                                 |
| ----------- | --------- | -------- | --------------------------------------------------------- |
| `JALR`      | `1100111` | `000`    | Jump to an address calculated from `rs1` and an immediate |

FUNC MUST BE 000

The target address is calculated as: [target = (rs1 + sign_extend(immediate)) & ~1]

The address of the next instruction is written into rd

FENCE controls the ordering of memory and I/O operations.

| Instruction | Opcode    | `funct3` | Purpose                                 |
| ----------- | --------- | -------- | --------------------------------------- |
| `FENCE`     | `0001111` | `000`    | Orders memory and device-I/O operations |


imm is divided into

 31       28 27      24 23      20
┌───────────┬──────────┬──────────┐
│    fm     │   pred   │   succ   │
└───────────┴──────────┴──────────┘

| Field  |  Width | Purpose                                        |
| ------ | -----: | ---------------------------------------------- |
| `fm`   | 4 bits | Fence mode                                     |
| `pred` | 4 bits | Operations that must complete before the fence |
| `succ` | 4 bits | Operations that must occur after the fence     |



Sys calls

| Instruction | `imm[11:0]`    | `rs1`   | `funct3` | `rd`    | Opcode    |
| ----------- | -------------- | ------- | -------- | ------- | --------- |
| `ECALL`     | `000000000000` | `00000` | `000`    | `00000` | `1110011` |
| `EBREAK`    | `000000000001` | `00000` | `000`    | `00000` | `1110011` |

ECALL requests a service from the execution environmen

EBREAK requests that execution stop and transfer control to a debugging environment

## S-Type

```text
 31          25 24       20 19       15 14    12 11        7 6        0
┌──────────────┬───────────┬───────────┬────────┬────────────┬──────────┐
│  imm[11:5]   │ rs2 [4:0] │ rs1 [4:0] │ funct3 │  imm[4:0]  │  opcode  │
└──────────────┴───────────┴───────────┴────────┴────────────┴──────────┘
```

all have the same opcode : 0100011

Unlike an I-type load, an S-type store does not need rd, because it does not write a result into the register file. Those five bits are instead used to hold part of the immediate.

| Instruction | Opcode    | `funct3` | Stored data             |
| ----------- | --------- | -------- | ----------------------- |
| `SB`        | `0100011` | `000`    | Lowest 8 bits of `rs2`  |
| `SH`        | `0100011` | `001`    | Lowest 16 bits of `rs2` |
| `SW`        | `0100011` | `010`    | All 32 bits of `rs2`    |


Calculates address using

address = rs1 + sign_extend(immediate)

memory roles are

| Field    | Purpose                                 |
| -------- | --------------------------------------- |
| `rs1`    | Contains the base memory address        |
| `rs2`    | Contains the data being stored          |
| `imm`    | Signed offset added to the base address |
| `funct3` | Selects the number of bytes to store    |
| `opcode` | Identifies the instruction as a store   |


## B-Type

```text
 31          30 29       25 24       20 19       15 14    12 11       8 7          6        0
┌──────────────┬────────────┬───────────┬───────────┬────────┬───────────┬──────────┬──────────┐
│   imm[12]    │ imm[10:5]  │ rs2 [4:0] │ rs1 [4:0] │ funct3 │ imm[4:1]  │ imm[11]  │  opcode  │
└──────────────┴────────────┴───────────┴───────────┴────────┴───────────┴──────────┴──────────┘
```

All instructions use the opcode: 1100011


The immediate is reconstructed as:

```verilog
b_imm = {
    {19{instruction[31]}},
    instruction[31],
    instruction[7],
    instruction[30:25],
    instruction[11:8],
    1'b0
};
```

The branch target is calculated using:


branch_target = pc + b_imm


### Conditional Branch Instructions

| Instruction | `funct3` | Branch condition |
|---|---|---|
| `BEQ`  | `000` | Branch if `rs1 == rs2` |
| `BNE`  | `001` | Branch if `rs1 != rs2` |
| `BLT`  | `100` | Branch if `signed(rs1) < signed(rs2)` |
| `BGE`  | `101` | Branch if `signed(rs1) >= signed(rs2)` |
| `BLTU` | `110` | Branch if `unsigned(rs1) < unsigned(rs2)` |
| `BGEU` | `111` | Branch if `unsigned(rs1) >= unsigned(rs2)` |

If the condition is true:

`pc_next = pc + b_imm`

Otherwise:

`pc_next = pc + 4`

The B-type immediate represents a signed PC-relative offset with an
implied zero in bit 0, giving a branch range of approximately ±4 KiB.

## U-Type

```text
 31                                      12 11      7 6        0
┌──────────────────────────────────────────┬──────────┬──────────┐
│                imm[31:12]                │ rd [4:0] │  opcode  │
└──────────────────────────────────────────┴──────────┴──────────┘
```

The instruction directly supplies bits [31:12] of the resulting immediate. The processor fills the lower 12 bits with zeros:

| Instruction | Opcode    | Operation               |
| ----------- | --------- | ----------------------- |
| `LUI`       | `0110111` | `rd = u_immediate`      |
| `AUIPC`     | `0010111` | `rd = pc + u_immediate` |




## J-Type

```text
 31          30                  21 20          19            12 11      7 6        0
┌──────────────┬───────────────────┬────────────┬────────────────┬──────────┬──────────┐
│   imm[20]    │     imm[10:1]     │  imm[11]   │   imm[19:12]   │ rd [4:0] │  opcode  │
└──────────────┴───────────────────┴────────────┴────────────────┴──────────┴──────────┘
```

`JAL` uses the opcode: 1101111


The immediate is reconstructed as:

```verilog
j_imm = {
    {11{instruction[31]}},
    instruction[31],
    instruction[19:12],
    instruction[20],
    instruction[30:21],
    1'b0
};
```

The jump target and return address are calculated using:


jump_target = pc + j_imm
rd          = pc + 4


> Both B-type and J-type offsets have an implied zero as their least-significant bit because their offsets are encoded in multiples of two bytes.


## Programmer-Visible State

RV32I contains:

- 32 integer registers, `x0` through `x31`
- One 32-bit program counter, `pc`
- A 32-bit register width (`XLEN = 32`)

Register `x0` is permanently hardwired to zero:

- Reading `x0` always returns `0`
- Writes to `x0` are ignored

Unless an instruction changes control flow, the next program-counter
value is:

`pc_next = pc + 4`