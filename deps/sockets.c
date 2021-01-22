
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <string.h>
#include <arpa/inet.h>  // inet_addr

#define BUFLEN 512

int udp_socket() {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    printf("Aquired socket %d\n", sock);
    return sock;
}

int tcp_socket() {
    return socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
}

int bind_socket(int sock, struct sockaddr_in* addr) {
    return bind(sock, (struct sockaddr *) addr, sizeof(struct sockaddr));
}

void print_addr(struct sockaddr_in* addr) {
    printf("family: %d\n", addr->sin_family);
    printf("port: %d\n", addr->sin_port);
    printf("address: %d\n", addr->sin_addr.s_addr);
}

#define BUFFER_LENGTH 2041

int main() {
    int sock = udp_socket();
    struct sockaddr_in gcAddr;
	memset(&gcAddr, 0, sizeof(gcAddr));
    gcAddr.sin_family = AF_INET;
    gcAddr.sin_port = htons(14550);
    gcAddr.sin_addr.s_addr = inet_addr("127.0.0.1");

    char buf[BUFFER_LENGTH];
    ssize_t recsize;
	socklen_t fromlen = sizeof(gcAddr);
	printf("GC Address: %d\n", gcAddr.sin_addr.s_addr);
	printf("GC Port: %d\n", gcAddr.sin_port);
    printf("fromlen: %d\n", fromlen);

    for (;;) {
        memset(buf, 0, BUFFER_LENGTH);
		recsize = recvfrom(sock, (void *)buf, BUFFER_LENGTH, 0, (struct sockaddr *)&gcAddr, &fromlen);
        printf("Received %ld bytes\n", recsize);
    }
    

    return 0;
}