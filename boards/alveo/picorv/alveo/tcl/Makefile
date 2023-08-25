# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

.PHONY: check-env

check-env:
ifndef XILINX_XRT
	$(error XILINX_XRT is undefined)
endif


impl_tdc:
	./package.sh -mode=1 -design=0 -sensor=0 | tee package.log && ./telegram_bot.py package.log && ./impl.sh | tee impl.log && ./telegram_bot.py impl.log

impl_blk:
	./package.sh -mode=1 -design=1 -sensor=0 | tee package.log && ./telegram_bot.py package.log && ./impl.sh | tee impl.log && ./telegram_bot.py impl.log

impl_rds:
	./package.sh -mode=1 -design=0 -sensor=1 | tee package.log && ./telegram_bot.py package.log && ./impl.sh | tee impl.log && ./telegram_bot.py impl.log

impl_tdc6:
	./package.sh -mode=1 -design=0 -sensor=2 | tee package.log && ./telegram_bot.py package.log && ./impl.sh | tee impl.log && ./telegram_bot.py impl.log

package_tdc: 
	./package.sh -mode=1 -design=0 -sensor=0 | tee package.log && ./telegram_bot.py package.log

package_rds: 
	./package.sh -mode=1 -design=0 -sensor=1 | tee package.log && ./telegram_bot.py package.log

sim:
	./package.sh -mode=0 -design=0 -sensor=0 | tee package.log && ./telegram_bot.py package.log && ./sim.sh | tee sim.log && ./telegram_bot.py sim.log

sim_blk:
	./package.sh -mode=0 -design=1 -sensor=0 | tee package.log && ./telegram_bot.py package.log && ./sim.sh | tee sim.log && ./telegram_bot.py sim.log

clean:
	rm -rf v++*.log vivado*.log vivado*.jou x*.log packaged temp_packaged bin _x .Xil kernel.xo impl.log package.log sim.log
