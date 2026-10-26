/* Set SO_RCVTIMEO and read it back: linux-user must copy the timeval
 * out and report its length. */
#include <stdio.h>
#include <sys/socket.h>
#include <sys/time.h>

int main(void) {
    int s = socket(AF_INET, SOCK_STREAM, 0);
    struct timeval tv = {0, 250000}, back = {0};
    socklen_t len = sizeof back;
    int set = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    int got = getsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &back, &len);
    printf("set=%d get=%d len=%u sec=%ld usec=%ld\n", set, got, len, (long)back.tv_sec, (long)back.tv_usec);
    return 0;
}
