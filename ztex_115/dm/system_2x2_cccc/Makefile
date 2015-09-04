# Copyright (c) 2012-2013 by the author(s)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Author(s):
#   Stefan Wallentowitz <stefan.wallentowitz@tum.de>
#   Philipp Wagner <philipp.wagner@tum.de>

# Do not set this variable in the Makefile, export it as environment variable!
# It is used by Synplify as well to determine the output directory of the
# synthesis.
OPTIMSOC_SYN_OUTDIR ?= .

# The commands synplify, bitgen and flash default to this target. If you want
# to explicitly specify a target, call the target directly (e.g. 
# "make bitgen_b_bram")!
BOARD_TARGET ?= d_ddr

# The "synplify" executable. You can overwrite the default set here with an
# environment variable, e.g. export SYNPLIFY=synplify_premier_dp
SYNPLIFY ?= synplify

synplify: synplify_$(BOARD_TARGET)

bitgen: bitgen_$(BOARD_TARGET)

flash: flash_$(BOARD_TARGET)

synplify.prj: synplify_project.tcl
	$(SYNPLIFY) -batch synplify_project.tcl

synplify_b_ddr: synplify.prj
	$(SYNPLIFY) -batch synplify.prj -impl ztex_115_dm_system_2x2_cccc_b_ddr

synplify_d_bram: synplify.prj
	$(SYNPLIFY) -batch synplify.prj -impl ztex_115_dm_system_2x2_cccc_d_bram

synplify_d_ddr: synplify.prj
	$(SYNPLIFY) -batch synplify.prj -impl ztex_115_dm_system_2x2_cccc_d_ddr

bitgen_b_ddr: $(OPTIMSOC_SYN_OUTDIR)/ztex_115_dm_system_2x2_cccc_b_ddr/pr_1/system_2x2_cccc.bit

bitgen_d_bram: $(OPTIMSOC_SYN_OUTDIR)/ztex_115_dm_system_2x2_cccc_d_bram/pr_1/system_2x2_cccc.bit

bitgen_d_ddr: $(OPTIMSOC_SYN_OUTDIR)/ztex_115_dm_system_2x2_cccc_d_ddr/pr_1/system_2x2_cccc.bit

flash_b_ddr: $(OPTIMSOC_SYN_OUTDIR)/ztex_115_dm_system_2x2_cccc_b_ddr/pr_1/system_2x2_cccc.bit
	FWLoader -v 0x221a 0x100 -f -uf $<

flash_d_bram: $(OPTIMSOC_SYN_OUTDIR)/ztex_115_dm_system_2x2_cccc_d_bram/pr_1/system_2x2_cccc.bit
	FWLoader -v 0x221a 0x100 -f -uf $<

flash_d_ddr: $(OPTIMSOC_SYN_OUTDIR)/ztex_115_dm_system_2x2_cccc_d_ddr/pr_1/system_2x2_cccc.bit
	FWLoader -v 0x221a 0x100 -f -uf $<

%.bit: %.ncd
	bitgen -w $*.ncd

clean:
	rm synplify.prj
