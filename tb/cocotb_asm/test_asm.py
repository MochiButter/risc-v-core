import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.types import LogicArray
from cocotb.clock import Clock
from cocotb_tools.runner import get_runner
import os
import random
import math
import logging

logger = logging.getLogger("core_test")
logger.setLevel(logging.INFO)

class Mem():
    bytes_per_word = 4
    mem = None
    maxint = 0
    addr_shamt = 2

    def __init__(self, datawidth, path=None):
        self.mem = [0] * 256
        self.bytes_per_word = int(datawidth / 8)
        self.addr_shamt = int(math.log2(self.bytes_per_word))
        self.maxint = (1 << datawidth) - 1
        if not path:
            return
        program = open(path, "rb")
        word = program.read(self.bytes_per_word)
        cnt = 0
        while (word):
            data = int.from_bytes(word, "little")
            self.mem[cnt] = data
            cnt += 1
            word = program.read(self.bytes_per_word)
        program.close()

    def dump_mem(self):
        logger.debug("Mem dump")
        cnt = 0
        skip = False
        for i in self.mem:
            if i == 0:
                if not skip:
                    logger.debug("...")
                skip = True
                cnt += self.bytes_per_word
                continue
            logger.debug(f"[0x{cnt:016x}] 0x{i:016x}")
            cnt += self.bytes_per_word
            skip = False

    def read_word(self, addr):
        word = self.mem[addr >> self.addr_shamt]
        return word

    def write_word(self, addr, data, mask):
        tmp_data = self.mem[addr >> self.addr_shamt]
        for i in reversed(range(self.bytes_per_word)):
            mask_bit = (mask & (1 << i)) >> i
            data_byte = (data >> (i * 8)) & (0xff if mask_bit else 0x00)
            tmp_data = tmp_data | (data_byte << (i * 8))
        logger.info(f"Wrote [0x{addr:016x}] 0b{mask:08b} 0x{tmp_data:016x}")
        self.mem[addr >> self.addr_shamt] = tmp_data

    async def run_instmem(self, dut):
        dut.instmem_ready_i.value = 1;
        while True:
            await dut.clk_i.rising_edge
            if not dut.rst_i.value and dut.instmem_valid_o.value == 1:
                req_addr = int(dut.instmem_addr_o.value)
                dut.instmem_rdata_i.value = self.read_word(req_addr)
                dut.instmem_rvalid_i.value = 1
            else:
                dut.instmem_rvalid_i.value = 0

    async def run_datamem(self, dut):
        dut.datamem_ready_i.value = 1;
        while True:
            await dut.clk_i.rising_edge
            if dut.datamem_valid_o.value == 1:
                req_addr = int(dut.datamem_addr_o.value)
                dut.datamem_rdata_i.value = self.read_word(req_addr)
                if dut.datamem_wmask_o.value != 0:
                    wdata = int(dut.datamem_wdata_o.value)
                    mask = int(dut.datamem_wmask_o.value)
                    self.write_word(req_addr, wdata, mask)
                dut.datamem_rvalid_i.value = 1
            else:
                dut.datamem_rvalid_i.value = 0

async def run_program(dut, filepath, check_mem=None):
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "asm", filepath))
    instmem = Mem(64, filepath)
    instmem.dump_mem()

    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    cocotb.start_soon(instmem.run_instmem(dut))
    cocotb.start_soon(instmem.run_datamem(dut))

    dut.rst_i.value = 1
    for _ in range(3):
        await dut.clk_i.rising_edge
    dut.rst_i.value = 0

    inst = 0
    count = 0
    while inst != 0x00100073:
        if dut.inst_valid.value == 1 and not dut.mem_busy.value:
            pc = int(dut.inst_pc.value)
            inst = int(dut.inst_data.value)
            logger.info(f"[0x{pc:016x}] 0x{inst:08x}")
        await dut.clk_i.rising_edge
        count += 1
        if count > 100:
            logger.error("Timeout reached")
            assert(0)
            break
    instmem.dump_mem()
    if check_mem:
        check_mem(instmem.mem)

@cocotb.test()
async def test_arith(dut):
    await run_program(dut, "arithmetic.bin")
    assert dut.reg_inst.regs_q[1].get().to_unsigned()  == 0x96
    assert dut.reg_inst.regs_q[2].get().to_unsigned()  == 0xffffffffffffffce
    assert dut.reg_inst.regs_q[3].get().to_unsigned()  == 0x56
    assert dut.reg_inst.regs_q[4].get().to_unsigned()  == 0x76
    assert dut.reg_inst.regs_q[5].get().to_unsigned()  == 0x20
    assert dut.reg_inst.regs_q[6].get().to_unsigned()  == 0xfffffffcba000000
    assert dut.reg_inst.regs_q[7].get().to_unsigned()  == 0x1ffffffff7dde000
    assert dut.reg_inst.regs_q[8].get().to_unsigned()  == 0xfffffffff7dde000
    assert dut.reg_inst.regs_q[9].get().to_unsigned()  == 0x1
    assert dut.reg_inst.regs_q[10].get().to_unsigned() == 0x1
    assert dut.reg_inst.regs_q[11].get().to_unsigned() == 0x0
    assert dut.reg_inst.regs_q[12].get().to_unsigned() == 0x1

@cocotb.test()
async def test_jump(dut):
    await run_program(dut, "jump.bin")
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
    await run_program(dut, "load.bin")
    assert dut.reg_inst.regs_q[2].get().to_unsigned() == 0xffffffff87654321
    assert dut.reg_inst.regs_q[3].get().to_unsigned() == 0x00000021
    assert dut.reg_inst.regs_q[4].get().to_unsigned() == 0xffffffffffffff87
    assert dut.reg_inst.regs_q[5].get().to_unsigned() == 0x00004321
    assert dut.reg_inst.regs_q[6].get().to_unsigned() == 0xffffffffffff8765
    assert dut.reg_inst.regs_q[7].get().to_unsigned() == 0x00000087
    assert dut.reg_inst.regs_q[8].get().to_unsigned() == 0x00008765

@cocotb.test()
async def test_store(dut):
    def check_mem(mem):
        assert mem[6] == 0xdeadbeef
        assert mem[7] == 0x0000beef
        assert mem[8] == 0xbeef0000
        assert mem[9] == 0x000000ef
        assert mem[10] == 0x0000ef00
        assert mem[11] == 0x00ef0000
        assert mem[12] == 0xef000000
    await run_program(dut, "store.bin", check_mem)

@cocotb.test()
async def test_branch(dut):
    await run_program(dut, "branch.bin")
    assert dut.reg_inst.regs_q[3].get().to_unsigned()  == 0
    assert dut.reg_inst.regs_q[4].get().to_unsigned()  == 2
    assert dut.reg_inst.regs_q[5].get().to_unsigned()  == 3
    assert dut.reg_inst.regs_q[6].get().to_unsigned()  == 4

@cocotb.test()
async def test_extra(dut):
    await run_program(dut, "extra.bin")
    assert dut.reg_inst.regs_q[1].get().to_unsigned()  == 0x12345000
    assert dut.reg_inst.regs_q[2].get().to_unsigned()  == 0x12345004

@cocotb.test()
async def test_loop(dut):
    def check_mem(mem):
        assert mem[7] == 0xdeadbeef
    await run_program(dut, "loop.bin", check_mem)
    assert dut.reg_inst.regs_q[1].get().to_unsigned()  == 0x00000072
    assert dut.reg_inst.regs_q[2].get().to_unsigned()  == 0x00000064
    assert dut.reg_inst.regs_q[3].get().to_unsigned()  == 0xdeadbeef
