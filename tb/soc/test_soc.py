import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.types import LogicArray
from cocotb.clock import Clock
import os
import logging

logger = logging.getLogger("soc_test")
logger.setLevel(logging.INFO)

def get_resp_code(resp):
    if resp == 0:
        return "OKAY"
    elif resp == 1:
        return "EXOKAY"
    elif resp == 2:
        return "SLVERR"
    elif resp == 3:
        return "DECERR"
    logger.error("Resp code not within 2 bits")
    assert (0)

def dump_axil_bus(cycle, axil_if):
    ret = ""

    if axil_if.awvalid.value and axil_if.awready.value:
        addr = int(axil_if.awaddr.value)
        ret += f"waddr  [0x{addr:016x}]  "
    if axil_if.wvalid.value and axil_if.wready.value:
        wdata = int(axil_if.wdata.value)
        ret += f"wdata  0x{wdata:016x}  "
    if axil_if.bvalid.value and axil_if.bready.value:
        bresp = axil_if.bresp.value
        bresp_str = get_resp_code(bresp)
        ret += f"write resp  {bresp_str}  "

    if axil_if.arvalid.value and axil_if.arready.value:
        addr = int(axil_if.araddr.value)
        ret += f"read  [0x{addr:016x}]  "
    if axil_if.rvalid.value and axil_if.rready.value:
        rdata = int(axil_if.rdata.value)
        rresp = axil_if.rresp.value
        rresp_str = get_resp_code(rresp)
        ret += f"read resp  0x{rdata:016x} : {rresp_str}  "

    if ret != "":
        ret = f"cycle {cycle}\n" + ret
        return ret
    return False

def get_mem(dut):
    dualport = dut.u_axil_ram.DualPort.value
    return dut.u_axil_ram.l_dualport.u_mem.mem if dualport else dut.u_axil_ram.l_singleport.u_mem.mem

async def run_program(dut, filepath, timeout):
    filepath = os.path.abspath(os.path.join(os.path.dirname(__file__), "sim_build", filepath))

    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    dut.rst_ni.value = 0
    for _ in range(3):
        await dut.clk_i.rising_edge
    dut.rst_ni.value = 1

    program = open(filepath, "rb")
    word = program.read(8)
    cnt = 0
    while (word):
        word_bytes = int.from_bytes(word, byteorder="little")
        bytes_la = LogicArray.from_unsigned(word_bytes, 64)
        get_mem(dut)[cnt].set(bytes_la)
        cnt += 1
        word = program.read(8)
    program.close()

    cycles = 0
    is_ebreak = False
    while not is_ebreak:
        is_ebreak = dut.rvfi_valid.value and dut.rvfi_insn.value == 0x00100073
        axil = dump_axil_bus(cycles, dut.core_axil)
        if axil:
            logger.info(axil)
        await dut.clk_i.rising_edge
        cycles += 1
        assert cycles < timeout, f"Cycles exceeded {timeout}"

@cocotb.test()
async def test_load(dut):
    await run_program(dut, "load.bin", 100)
    assert dut.u_core.reg_inst.regs_q[2].get().to_unsigned() == 0xffffffff87654321
    assert dut.u_core.reg_inst.regs_q[3].get().to_unsigned() == 0x00000021
    assert dut.u_core.reg_inst.regs_q[4].get().to_unsigned() == 0xffffffffffffff87
    assert dut.u_core.reg_inst.regs_q[5].get().to_unsigned() == 0x00004321
    assert dut.u_core.reg_inst.regs_q[6].get().to_unsigned() == 0xffffffffffff8765
    assert dut.u_core.reg_inst.regs_q[7].get().to_unsigned() == 0x00000087
    assert dut.u_core.reg_inst.regs_q[8].get().to_unsigned() == 0x00008765

@cocotb.test()
async def test_store(dut):
    await run_program(dut, "store.bin", 100)
    mem = get_mem(dut)
    assert mem[6].value  == 0xdeadbeef
    assert mem[7].value  == 0x0000beef
    assert mem[8].value  == 0xbeef0000
    assert mem[9].value  == 0x000000ef
    assert mem[10].value == 0x0000ef00
    assert mem[11].value == 0x00ef0000
    assert mem[12].value == 0xef000000

@cocotb.test()
async def test_loop(dut):
    await run_program(dut, "loop.bin", 100)
    assert dut.u_core.reg_inst.regs_q[1].get().to_unsigned()  == 0x00000072
    assert dut.u_core.reg_inst.regs_q[2].get().to_unsigned()  == 0x00000064
    assert dut.u_core.reg_inst.regs_q[3].get().to_unsigned()  == 0xdeadbeef
    mem = get_mem(dut)
    assert mem[7].value == 0xdeadbeef

@cocotb.test()
async def test_misalign(dut):
    await run_program(dut, "misalign.bin", 150)
    assert dut.u_core.reg_inst.regs_q[31].get() == 2
    mem = get_mem(dut)
    assert mem[128].value == 0
    assert mem[129].value == 4
    assert mem[130].value == 6

@cocotb.test()
async def test_fencei(dut):
    await run_program(dut, "fencei.bin", 50)
    assert dut.u_core.reg_inst.regs_q[1].get() == 0x42
