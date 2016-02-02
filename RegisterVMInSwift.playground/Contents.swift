/*:

# Register VM in Swift

_A Swift playground corresponding to a chapter in the Wikibook_ [Creating a Virtual Machine](https://en.wikibooks.org/wiki/Creating_a_Virtual_Machine) _by Jeffrey Meunier and other Wikibooks contributors._

_This text is incorporated into the wikibook as_ [Register VM in Swift](https://en.wikibooks.org/wiki/Creating_a_Virtual_Machine/Register_VM_in_Swift). _It is a direct translation from C into Swift of the chapter_
[Register VM in C](https://en.wikibooks.org/wiki/Creating_a_Virtual_Machine/Register_VM_in_C).

_This text and the text from which it was translated are licensed under the_ [Creative Commons Attribution-ShareAlike License](http://creativecommons.org/licenses/by-sa/3.0/).

_This text will render well in Xcode 7 if you select_ Show Rendered Markup _in the Editor menu._

_This playground has been updated to work with Swift 2.1._

## Design

The first example will be one of the simplest possible architectures, and it will consist of
the following components:

1. A set of registers (we will arbitrarily choose to have 4 of them, numbered 0 to 3). The
registers serve as a group of read/write memory cells.
2. A program, which is a read-only sequence of VM instructions
3. An execution unit to run the program. The execution unit will read each instruction in
order and _execute_ it.

## Addressing modes

In any assembly language numbers serve multiple uses.  Aside from representing scalar
values, they also represent register numbers and memory locations.  In this example I
will follow the convention of using prefix characters to denote the role the number plays.

* Register numbers begin with the letter _r,_ like _r0, r1, r2._
* Immediate (scalar) values begin with the has mark _#,_ like _#100, #200._
* Memory addresses begin with the at sign @, like _@1000, @1004._

## Instruction set

After designing a VM, it is necessary to design the VM's instruction set.  The
instruction set is simply a reflection of the kinds of things we would like to do (or allow
others to do) with this VM.  Here are some things it should be possible to do with this VM:

* Load an immediate number (a constant) into a register.
* Perform an arithmetic sum on two registers (i.e., add two numbers).
* Halt the machine.

Let's keep it just that simple for now.  After we have a working implementation we can go
back and add more instructions.

First let's write a short program using these three instructions to see what they might
look like:

    1 loadi r0 #100
    2 loadi r1 #200
    3 add r2 r0 r1
    4 halt

If the VM were to run the program, this is a description of what would happen on each line:

1. Load the immediate value 100 into the register _r0._ Note that placing a value into a
register is commonly called a _load_ operation.
2. Load the immediate value 200 into register _r1._
3. Add the contents of registers _r0_ and _r1_ and place the sum into register _r2._
4. End the program and halt the VM.

Note that in keeping with common convention we have chosen to place the destination
registers first in the operand list.

## Instruction codes

After the assembly language is created it is necessary to determine how to represent each
instruction as a number.  This establishes a one-to-one correspondence between each
instruction in the assembly language and each instruction code in the set of instruction
codes.  Converting a program from assembly language to instruction codes is called
_assembling,_ and conversion from instruction codes back into assembly language is
called _disassembling._

Several choices we must make at this point are:

* What number is used to represent each assembly language instruction?
* How are instruction operands encoded?
* Are operands part of the instruction word (remember, by _word_ we mean _number_), or
are they separate words (numbers)?

First, to answer the last question, since there are only small numbers of instructions and
registers in this VM it should not be very difficult to encode all operands in a single
instruction word, even if (for sake of simplicity) we were to use a 16-bit instruction
word.  Thus, a 16-bit number written in hexadecimal has 4 digits, giving us easy access to
4 information fields, each containing 16 variations (0-9 and A-F).

1. The first digit of each machine word will be the instruction number.  This gives our VM
the potential for having up to 16 different instructions.  This is a small amount by
contemporary standards, but it is plenty for our example virtual machine.
2. The next three digits will be used for the operands.  These can be used as three 1-digit
operands, two operands of 1 and 2 digits, or a single 3-digit operand.

Having made these decisions, let us now establish the encoding.  Recall that we have 16
instruction numbers available.

The _halt_ instruction will be instruction 0, and there is an important reason for choosing
0 for this instruction.  Since empty space in the computer's memory will mostly likely be
filled with 0s, any run-away program will eventually encounter a 0 and attempt to
execute this instruction, immediately halting the program.

The remaining two instructions can be assigned arbitrarily: the _loadi_ instruction can be
instruction 1, and the _add_ instruction can be instruction 2.  This is our current
instruction encoding list:

    0 = halt
    1 = loadi
    2 = add

Examining the first program instruction, we see that we must now encode the register
and the immediate value:

There are three hexadecimal digits available for operands, so we will use the first of
those three as the register number, and the second and third together as the immediate
value.  Now we have just determined the complete encoding of the _loadi_ instruction:

    bits 15-12 = 1
    bits 11- 8 = register value
    bits  7- 0 = immediate value

The register number for this instruction is 0, and the immediate value is 100, which in
hexadecimal is 64 (6 x 16 + 4). Thus, the complete 16-bit hexadecimal instruction code
for the first instruction is 1064.

The second instruction is assembled in a similar way.  The immediate value is 200, which
is hexadecimal C8.  The second instruction assembles to 11C8.

The third instruction is 2201.

The last instruction is 0.

Putting the instructions together, we get these 4 16-bit hexadecimal numbers as the
complete program:

    1064
    11C8
    2201
    0000

## Implementation

It is now time to implement this design.  We have chosen to write this program in Swift for a
number of reasons:

* It is a simple, concise and modern language.
* It has low-level features with obvious correspondences with the low-level features of C.

The primary consideratio of the VM will be a _run_ function that does the following steps in
order inside a loop.  The loop repeats until the _halt_ instruction is executed.

1. Fetch the next instruction from the program.
2. Decode the instruction into its constituent parts.
3. Execute the decoded instruction.

Let's begin writing the program.

## Registers

The first and simplest part to implement is the set of 4 registers.

*/

let NUM_REGS = 4
var regs = [Int](count: NUM_REGS, repeatedValue: 0)

/*:

The registers in this VM are signed integers that are, depending on your computer and
operating system, either 16, 32, or 64 bits wide.  The exact size is irrelevant for this
example.

## Program instructions

The fully assembled program can easily be stored in an array of integers.

*/

let prog = [0x1064, 0x11c8, 0x2201, 0x0000]

/*:

## Fetch

The _fetch_ function retrieves the next word from the program. In order to do this we must
introduce a variable called the _program counter_ (also sometimes called the _instruction pointer_).

*/

var pc = 0  // program counter


func fetch() -> Int {
    return prog[pc++]
}

/*:

## Decode

The _decode_ function will decode each instruction completely.  It will determine the three
operand registers and immediate value for each instruction, even if an instruction
doesn't use that part.  This actually makes the function simpler.  The instruction number
and operands are stored in variables.

*/

var instrNum = 0
// operands:
var reg1     = 0
var reg2     = 0
var reg3     = 0
var imm      = 0


// decode a word
func decode(instr:Int) -> Void {
    instrNum = (instr & 0xF000) >> 12
    reg1     = (instr & 0xF00 ) >>  8
    reg2     = (instr & 0xF0  ) >>  4
    reg3     = (instr & 0xF   )
    imm      = (instr & 0xFF  )
}

/*:

## Execute

The _execute_ function actually performs the instruction.  First there needs to be a _running_
flag that the _halt_ instruction set to 0.

*/

// the VM runs until this flag becomes 0
var running = 1

/*:

Now the _eval_ function. It's just a _switch_ ladder.  This function uses the instruction code
and operand variables that the _decode_ function stored values into.  Notice that in each
instruction case we display the instruction.  This makes it easy to follow the program as it
runs.

*/

// evaluate the last decoded instruction
func eval() -> Void {
    switch instrNum {
    case 0:
        // halt
        print("halt")
        running = 0
    case 1:
        // loadi
        print("loadi r\(reg1) #\(imm)")
        regs[reg1] = imm;
    case 2:
        // add
        print("add r\(reg1) r\(reg2) r\(reg3)");
        regs[reg1] = regs[reg2] + regs[reg3]
    default:
        print("oops");
    }
}

/*:

## Showing the registers

We have added a _showRegs_ function in order to see the values of all the registers
between instructions.  This allows us to verify that both the VM and the assembled
program are working correctly.

*/

func formatRegister(reg:Int) -> String {
    let hex = String(reg, radix: 16, uppercase: true)
    let paddingCharacter = "0" as Character
    let padding = String(count: 4 - hex.characters.count, repeatedValue: paddingCharacter)
    return padding + hex
}

func showRegs() -> Void {
    print("regs = ", terminator:"")
    print(regs.map(formatRegister).joinWithSeparator(" "))
}

/*:

## Run

The _run_ function is rather simple: fetch, then decode, then execute, with calls to showRegs
to see the values.

*/

func run() -> Void {
    showRegs()
    while running != 0 {
        let instr = fetch()
        decode(instr)
        eval()
        showRegs()
    }
}

/*:

## Entry point

The entry point for our VM is the _run_ function.

*/

run()

/*:

## Sample run
Here is the output from the program:

    loadi r0 #100
    regs = 0064 0000 0000 0000
    loadi r1 #200
    regs = 0064 00C8 0000 0000
    add r2 r0 r1
    regs = 0064 00C8 012C 0000
    halt
    regs = 0064 00C8 012C 0000

*/

