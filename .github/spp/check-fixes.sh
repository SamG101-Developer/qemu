#!/usr/bin/env bash
# Prove the fixes this branch carries, on the binaries just built:
# every emulator starts, a signal handler unwinds under qemu-ppc and
# qemu-loongarch64 (the vDSO CFI fixes), and SO_RCVTIMEO reads back
# under qemu-aarch64 (the getsockopt fix). Args: the folder holding
# the qemu-<arch> binaries.
set -euo pipefail

BIN="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
status=0

for q in "$BIN"/qemu-*; do
  "$q" --version > /dev/null || { echo "::error::$(basename "$q") does not start"; status=1; }
done

# The handler prints its frame count and exits with the signal number;
# a crash in the unwinder is reported by qemu instead. Handler,
# trampoline, fault and main make 4.
unwinds() {
  local arch="$1" cc="$2" sysroot="$3" out
  "$cc" -O1 -g -fasynchronous-unwind-tables -o "$WORK/sigbt-$arch" "$HERE/sigbt.c"
  out="$("$BIN/qemu-$arch" -L "$sysroot" "$WORK/sigbt-$arch" 2>&1 || true)"
  echo "qemu-$arch sigbt: $out"
  if ! [[ "$out" =~ backtrace:\ ([0-9]+)\ frames ]] || [ "${BASH_REMATCH[1]}" -lt 4 ]; then
    echo "::error::qemu-$arch does not unwind out of a signal handler"
    status=1
  fi
}

unwinds ppc powerpc-linux-gnu-gcc /usr/powerpc-linux-gnu
unwinds loongarch64 loongarch64-linux-gnu-gcc-14 /usr/loongarch64-linux-gnu

aarch64-linux-gnu-gcc -o "$WORK/sockto" "$HERE/sockto.c"
out="$("$BIN/qemu-aarch64" -L /usr/aarch64-linux-gnu "$WORK/sockto")"
echo "qemu-aarch64 sockto: $out"
if [[ "$out" != *" len=16 "* ]]; then
  echo "::error::qemu-aarch64 does not read SO_RCVTIMEO back"
  status=1
fi

rm -rf "$WORK"
exit "$status"
