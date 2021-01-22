
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