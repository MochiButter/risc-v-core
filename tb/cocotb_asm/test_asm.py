import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.types import LogicArray
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
import os
import random

mem = []
def load_program(filename):
    del mem[:]
    addr = 0
    print("=== Program memory ===")
    program = open(filename, "rb")
    while True:
        word = program.read(4)
        if word:
            inst = int.from_bytes(word, "little")
            mem.append(inst)
            print(f"[0x{addr:08x}] 0x{inst:08x}")
            addr += 4
        else:
            program.close()
            print("=== Program end ===")
            break

async def mem_resp(dut):
    dut.instmem_ready_i.value = 1;
    while True:
        await dut.clk_i.rising_edge
        if not dut.rst_i.value and dut.instmem_valid_o.value == 1:
            req_addr = int(dut.instmem_addr_o.value)
            if (req_addr >> 2) < len(mem):
                dut.instmem_rdata_i.value = mem[req_addr >> 2]
            else:
                dut.instmem_rdata_i.value = random.getrandbits(32)
            dut.instmem_rvalid_i.value = 1
        else:
            dut.instmem_rvalid_i.value = 0

datamem = [0] * 256
async def datamem_resp(dut):
    dut.datamem_ready_i.value = 1;
    while True:
        await dut.clk_i.rising_edge
        if dut.datamem_valid_o.value == 1:
            req_addr = int(dut.datamem_addr_o.value)
            if (req_addr >> 2) < len(datamem):
                dut.datamem_rdata_i.value = datamem[req_addr >> 2]
            else:
                dut.datamem_rdata_i.value = random.getrandbits(32)
            if dut.datamem_wmask_o.value != 0:
                wdata = dut.datamem_wdata_o.value
                mask = dut.datamem_wmask_o.value
                data = 0
                for i in range(4):
                    byte = int(wdata[(i + 1) * 8 - 1:i * 8])
                    if mask[i]:
                        data += byte << (i * 8)
                print(f"Wrote 0x{data:08x}")
                datamem[req_addr >> 2] = data
            dut.datamem_rvalid_i.value = 1
        else:
            dut.datamem_rvalid_i.value = 0

async def run_program(dut, filepath):
    load_program(filepath)

    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    cocotb.start_soon(mem_resp(dut))
    cocotb.start_soon(datamem_resp(dut))

    dut.rst_i.value = 1
    for _ in range(3):
        await dut.clk_i.rising_edge
    dut.rst_i.value = 0

    inst = 0
    count = 0
    while inst != 0x00100073:
        if dut.inst_valid.value == 1:
            #pc = int(dut.fifo_rd_data.value[63:32])
            #inst = int(dut.fifo_rd_data.value[31:0])
            pc = int(dut.inst_pc.value)
            inst = int(dut.inst_data.value)
            print(f"[0x{pc:08x}] 0x{inst:08x}")
        await dut.clk_i.rising_edge
        count += 1
        if count > 50:
            print("Timeout reached")
            break

@cocotb.test()
async def test_arith(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "arithmetic.bin"))
    await run_program(dut, filepath)
    assert dut.reg_inst.regs_q[1].get().to_unsigned()  == 0x96
    assert dut.reg_inst.regs_q[2].get().to_unsigned()  == 0xffffffce
    assert dut.reg_inst.regs_q[3].get().to_unsigned()  == 0x56
    assert dut.reg_inst.regs_q[4].get().to_unsigned()  == 0x76
    assert dut.reg_inst.regs_q[5].get().to_unsigned()  == 0x20
    assert dut.reg_inst.regs_q[6].get().to_unsigned()  == 0xba000000
    assert dut.reg_inst.regs_q[7].get().to_unsigned()  == 0x17dde000
    assert dut.reg_inst.regs_q[8].get().to_unsigned()  == 0xf7dde000
    assert dut.reg_inst.regs_q[9].get().to_unsigned()  == 0x1
    assert dut.reg_inst.regs_q[10].get().to_unsigned() == 0x1
    assert dut.reg_inst.regs_q[11].get().to_unsigned() == 0x0
    assert dut.reg_inst.regs_q[12].get().to_unsigned() == 0x1

@cocotb.test()
async def test_jump(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "jump.bin"))
    await run_program(dut, filepath)
    assert dut.reg_inst.regs_q[1].value == 0x1c
    assert dut.reg_inst.regs_q[2].value == 0x2c
    assert dut.reg_inst.regs_q[6].value == 0x0
    assert dut.reg_inst.regs_q[7].value == 0x2
    assert dut.reg_inst.regs_q[8].value == 0x4
    assert dut.reg_inst.regs_q[9].value == 0x0
    assert dut.reg_inst.regs_q[10].value == 0x0
    assert dut.reg_inst.regs_q[11].value == 0x32

@cocotb.test()
async def test_load(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "load.bin"))
    datamem[12] = 0x87654321
    await run_program(dut, filepath)
    assert dut.reg_inst.regs_q[2].get().to_unsigned() == 0x87654321
    assert dut.reg_inst.regs_q[3].get().to_unsigned() == 0x00000021
    assert dut.reg_inst.regs_q[4].get().to_unsigned() == 0xffffff87
    assert dut.reg_inst.regs_q[5].get().to_unsigned() == 0x00004321
    assert dut.reg_inst.regs_q[6].get().to_unsigned() == 0xffff8765
    assert dut.reg_inst.regs_q[7].get().to_unsigned() == 0x00000087
    assert dut.reg_inst.regs_q[8].get().to_unsigned() == 0x00008765

@cocotb.test()
async def test_store(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "store.bin"))
    await run_program(dut, filepath)
    assert datamem[9]  == 0xdeadbeef
    assert datamem[10] == 0x0000beef
    assert datamem[11] == 0xbeef0000
    assert datamem[12] == 0x000000ef
    assert datamem[13] == 0x0000ef00
    assert datamem[14] == 0x00ef0000
    assert datamem[15] == 0xef000000

@cocotb.test()
async def test_branch(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "branch.bin"))
    await run_program(dut, filepath)
    assert dut.reg_inst.regs_q[3].get().to_unsigned()  == 0
    assert dut.reg_inst.regs_q[4].get().to_unsigned()  == 2
    assert dut.reg_inst.regs_q[5].get().to_unsigned()  == 3
    assert dut.reg_inst.regs_q[6].get().to_unsigned()  == 4

@cocotb.test()
async def test_extra(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "extra.bin"))
    await run_program(dut, filepath)
    assert dut.reg_inst.regs_q[1].get().to_unsigned()  == 0x12345000
    assert dut.reg_inst.regs_q[2].get().to_unsigned()  == 0x12345004

@cocotb.test()
async def test_loop(dut):
    mem = []
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", "loop.bin"))
    await run_program(dut, filepath)
    assert dut.reg_inst.regs_q[1].get().to_unsigned()  == 0x00000072
    assert dut.reg_inst.regs_q[2].get().to_unsigned()  == 0x00000064
    assert dut.reg_inst.regs_q[3].get().to_unsigned()  == 0xdeadbeef
    assert datamem[8]  == 0xdeadbeef

def test_programs_runner():
    sim = os.getenv("SIM", "icarus")

    sources = ["rtl/alu32.sv"
              ,"rtl/core.sv"
              ,"rtl/decode.sv"
              ,"rtl/fifo.sv"
              ,"rtl/mem_state.sv"
              ,"rtl/register.sv"]
    sources = [os.path.join(os.path.dirname(__file__), "../..", f) for f in sources]

    for i in sources:
        print(i)

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="core",
        always=True,
        timescale=["1ns","1ps"]
    )

    runner.test(hdl_toplevel="core", test_module="test_asm,")
