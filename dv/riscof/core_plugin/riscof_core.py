import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template
import sys

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class core(pluginTemplate):
    __model__ = "core"
    __version__ = "0.1"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        self.dut_exe = os.path.join(config['PATH'],"core_tb")

        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

        self.pluginpath=os.path.abspath(config['pluginpath'])

        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        if 'target_run' in config and config['target_run']=='0':
            self.target_run = False
        else:
            self.target_run = True

    def initialise(self, suite, work_dir, archtest_env):
       self.work_dir = work_dir
       self.suite_dir = suite
       toolchain = os.getenv("RISCV_TOOLCHAIN", "riscv64-unknown-elf-")

       self.compile_cmd = toolchain + 'gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env + ' {2} -o {3} {4}'

       self.makehex_cmd = toolchain + 'objcopy -O verilog \
               --verilog-data-width={1} {2} {3} {4}'

    def build(self, isa_yaml, platform_yaml):
      ispec = utils.load_yaml(isa_yaml)['hart0']
      self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
      self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else ('ilp32e ' if "E" in ispec["ISA"] else 'ilp32 '))

    def runTests(self, testList):
      if os.path.exists(self.work_dir+ "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir+ "/Makefile." + self.name[:-1])
      make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
      make.makeCommand = 'make -k -j' + self.num_jobs

      for testname in testList:
          testentry = testList[testname]
          test = testentry['test_path']
          test_dir = testentry['work_dir']

          elf = 'my.elf'

          sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")
          log_file = os.path.join(test_dir, self.name[:-1] + ".log")

          compile_macros= ' -D' + " -D".join(testentry['macros'])
          cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen, test, elf, compile_macros)
          makehex_text = self.makehex_cmd.format(self.xlen, int(int(self.xlen) / 8), "--only-section=.text*", elf, "my_text.hex")
          makehex_data = self.makehex_cmd.format(self.xlen, int(int(self.xlen) / 8), "--only-section=.data* --only-section=.bss", elf, "my_data.hex")

          if self.target_run:
            simcmd = self.dut_exe + ' +UVM_TESTNAME=core_test_riscof +RISCOF_SIG_PATH={0} +TEXT_HEX=my_text.hex +DATA_HEX=my_data.hex'.format(sig_file)
            simcmd += " | tee {0}".format(log_file)
          else:
            simcmd = 'echo "NO RUN"'

          execute = 'cd {}; {}; {}; {}; {};'.format(testentry['work_dir'], cmd, makehex_text, makehex_data, simcmd)

          make.add_target(execute)

      make.execute_all(self.work_dir, timeout = 3600)

      if not self.target_run:
          raise SystemExit(0)
