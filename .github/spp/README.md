# spp-patches

This fork carries fixes that the CI of [spp](https://github.com/SamG101-Developer/spp) and
[sppc](https://github.com/SamG101-Developer/sppc) needs before qemu ships them. Each is also offered upstream, and
the fork goes once all of them are in a qemu release.

- `master` is qemu's own master, fast-forwarded from gitlab.com/qemu-project/qemu.
- `spp-patches` (the default branch) is `master` plus the fixes, and the files under `.github/`.

The fixes:

- **linux-user/ppc:** the 32-bit rt sigreturn CFA leaves out `RT_SIGFRAME_ADJUST`, so unwinding out of a signal
  handler crashes under qemu-ppc.
- **linux-user/loongarch64:** the sigreturn CFI takes the CFA from `$tp`, not `$sp`, and the return address from
  column 64 (`fcc0`), not 72, so unwinding out of a signal handler faults, then aborts
  ([#4743](https://gitlab.com/qemu-project/qemu/-/work_items/4743)).
- **linux-user:** `getsockopt()` of `SO_RCVTIMEO`/`SO_SNDTIMEO` returns length 0 and no value.

Workflows:

- **Sync** (`spp-sync.yaml`, weekly or by hand): fast-forwards `master`, rebases `spp-patches` onto it, and if that
  moved the branch, starts Release with publishing on. A fix qemu has taken drops out; one that no longer applies
  fails the run, and nothing is pushed.
- **Release** (`spp-release.yaml`; from Sync, by hand, or on a pushed `spp-*` tag): builds static `qemu-<arch>`
  linux-user binaries, proves the fixes with `check-fixes.sh`, and publishes
  `qemu-user-static-<tag>-x86_64.tar.xz` (its binaries under `bin/`) and its sha256 as a release. By hand, tick
  "publish" to release (named `spp-<UTC date>`); unticked, it only builds and checks.
