# rms_norm_binary dyn：编译器插入 TMOV(INVALID) → gfsim Deadlock

本目录是 llvm-project issue 的本地复现包。源码在 SuperNPUBench
`drop-rms-norm-binary-workspace`（PR https://github.com/PTO-ISA/SuperNPUBench/pull/72）。

对照：

| 仿真 | dyn `[1,8192]` | static 同 shape |
|------|----------------|-----------------|
| gfrun（功能，无 `-t 1`） | PASS R2=0，precision max_abs=0 | PASS |
| gfsim（无 `res_check` ELF） | **FAIL Deadlock cycle=4147** | PASS 3959 cycles |

源码 **没有** `TMOV`。拷贝用 `TMULS(dst, src, 1.0f)`。clang 在
`update_cache`（`tile_v updateTile[8]` 跨 R-split 保活）里插入：

```text
BSTART.TLSU  TMOV
B.IOT        t#1, mask=1111, last, ->t<128B>
# 没有 B.DATR（dtype），没有 B.DIM
```

gfsim 解码成 `TMOV, lb0:1, lb1:1, lb2:1 INVALID`，随后 Deadlock。

## 复现（本机路径）

```bash
export COMPILER_DIR=/home/wangyu/Code/SuperScalar/linx-toolchain-build/output/linx_blockisa_llvm_musl/bin
export CFLAGS="-resource-dir /home/wangyu/Code/SuperScalar/SuperNPUBench/Daily/2026-08-20/rms_norm_verify_main/clang_res_6369707"
bash Daily/2026-08-21/rms_norm_binary_dyn_tmov_gfsim/compile.sh
# 或直接对已编好的 ELF：
/home/wangyu/Code/SuperScalar/SuperScalarModel/bin/gfsim \
  -f Daily/2026-08-21/rms_norm_binary_dyn_tmov_gfsim/rms_norm_binary_dyn.elf \
  --pto-v02 true -s core.singleTierMode=true
```

不要加 `gfrun -t 1` / `gfsim -t 1`。PE1，不要 `--conf fourpe`。
gfsim 必须用 **无** `res_check` 的 ELF（带 host I/O 的会 SIGSEGV）。
