/* Unwind out of a SIGSEGV handler: under a linux-user vDSO whose signal
 * frame CFI is wrong, backtrace() crashes or stops at the trampoline. */
#define _GNU_SOURCE
#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void handler(int sig, siginfo_t *si, void *uctx) {
    (void)si; (void)uctx;
    void *frames[32];
    char buf[64];
    int n = backtrace(frames, 32);
    int len = snprintf(buf, sizeof buf, "backtrace: %d frames\n", n);
    write(1, buf, (size_t)len);
    _exit(sig);
}

__attribute__((noinline)) int fault(volatile int *p) {
    return *p;
}

int main(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_sigaction = handler;
    sa.sa_flags = SA_SIGINFO;
    sigaction(SIGSEGV, &sa, NULL);
    return fault(NULL);
}
