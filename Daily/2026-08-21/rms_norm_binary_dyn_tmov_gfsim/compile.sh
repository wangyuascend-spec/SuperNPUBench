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

ELF=$BENCH/benchmark/one-level-arch/output/kernel/normalization/rms_norm_binary/elf/kernel_normalization_rms_norm_binary_rms_norm_binary_DType__half.elf
cp -f "$ELF" "$HERE/rms_norm_binary_dyn.elf"
"$COMPILER_DIR/llvm-objdump" -dl "$HERE/rms_norm_binary_dyn.elf" >"$HERE/rms_norm_binary_dyn.diss"
echo "ELF  $HERE/rms_norm_binary_dyn.elf"
echo "diss $HERE/rms_norm_binary_dyn.diss"
echo "TMOV sites:"
rg -n "TMOV" "$HERE/rms_norm_binary_dyn.diss" | head

echo
echo "gfsim (expect Deadlock ~cycle 4147):"
echo "  $ROOT/SuperScalarModel/bin/gfsim -f $HERE/rms_norm_binary_dyn.elf --pto-v02 true -s core.singleTierMode=true"
