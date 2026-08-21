#!/usr/bin/env bash
# Build rms_norm_binary dyn (no res_check) and dump TMOV sites.
set -euo pipefail
ROOT=${ROOT:-/home/wangyu/Code/SuperScalar}
BENCH=$ROOT/SuperNPUBench
HERE=$(cd "$(dirname "$0")" && pwd)
COMPILER_DIR=${COMPILER_DIR:-$ROOT/linx-toolchain-build/output/linx_blockisa_llvm_musl/bin}
export CFLAGS="${CFLAGS:--resource-dir $BENCH/Daily/2026-08-20/rms_norm_verify_main/clang_res_6369707}"

cd "$BENCH/benchmark/one-level-arch/test/kernel/normalization/rms_norm_binary"
make TESTCASE=rms_norm_binary COMPILER_DIR="$COMPILER_DIR" DType=__half
make TESTCASE=rms_norm_binary_static COMPILER_DIR="$COMPILER_DIR" DType=__half \
  G_A=1 G_R=8192 TILE_A=1 TILE_R=1024 POW_R=4096

ELF_DIR=$BENCH/benchmark/one-level-arch/output/kernel/normalization/rms_norm_binary/elf
ELF=$ELF_DIR/kernel_normalization_rms_norm_binary_rms_norm_binary_DType__half.elf
SELF=$ELF_DIR/kernel_normalization_rms_norm_binary_rms_norm_binary_static_DType__half_gA1_gR8192_tA1_tR1024_powR4096.elf
cp -f "$ELF" "$HERE/rms_norm_binary_dyn.elf"
cp -f "$SELF" "$HERE/rms_norm_binary_static.elf"
"$COMPILER_DIR/llvm-objdump" -dl "$HERE/rms_norm_binary_dyn.elf" >"$HERE/rms_norm_binary_dyn.diss"
"$COMPILER_DIR/llvm-objdump" -dl "$HERE/rms_norm_binary_static.elf" >"$HERE/rms_norm_binary_static.diss"
echo "ELF  $HERE/rms_norm_binary_dyn.elf"
echo "diss $HERE/rms_norm_binary_dyn.diss"
echo "TMOV sites (dyn):"
rg -n "TMOV" "$HERE/rms_norm_binary_dyn.diss" | head
echo "S64 spill (static):"
rg -n "TLOAD, S64|TSTORE, S64" "$HERE/rms_norm_binary_static.diss"

echo
echo "gfsim (expect Deadlock ~cycle 4147):"
echo "  $ROOT/SuperScalarModel/bin/gfsim -f $HERE/rms_norm_binary_dyn.elf --pto-v02 true -s core.singleTierMode=true"
