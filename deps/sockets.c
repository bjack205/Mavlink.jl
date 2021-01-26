
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <string.h>
#include <arpa/inet.h>  // inet_addr
#include <unistd.h>     // read and write

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

int accept_client(int sock, struct sockaddr_in* addr) {
    int len = sizeof(struct sockaddr);
    int sock_cli = accept(sock, (struct sockaddr*) addr, &len);
    return sock_cli;
}

int reuse(int sock) {
    int opt = 1;
    return setsockopt(sock, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt));
}

int connect_to_server(int sock, struct sockaddr_in* addr) {
    return connect(sock, (struct sockaddr*) addr, sizeof(struct sockaddr));
}

void print_addr(struct sockaddr_in* addr) {
    printf("family: %d\n", addr->sin_family);
    printf("port: %d\n", addr->sin_port);
    printf("address: %d\n", addr->sin_addr.s_addr);
}

#define BUFFER_LENGTH 2041

void test_udp(int port) {
    int sock = udp_socket();
    struct sockaddr_in gcAddr;
	memset(&gcAddr, 0, sizeof(gcAddr));
    gcAddr.sin_family = AF_INET;
    gcAddr.sin_port = htons(port);
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
}

void test_tcp_server(int port) {
    // Create socket
    int sock = tcp_socket();
    if (sock == -1) {
        printf("socket creation failed...\n");
        exit(0);
    } else {
        printf("Socket successfully created...\n");
    }

    // Define the port
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    int len = sizeof(addr);

    // Bind socket to port
    if ((reuse(sock) != 0)) {
        printf("setting solver options failed...\n");
    }
    if ((bind_socket(sock, &addr) != 0)) {
        printf("socket bind failed...\n");
        exit(0);
    } else {
        printf("Socket bound to port.\n");
    }

    // Listen for client
    if((listen(sock, 5)) != 0) {
        printf("listen failed...\n");
    } else {
        printf("Server listening...\n");
    }

    // Accept the data packet from the client and verification
    // int consock = accept(sock, (struct sockaddr*) &addr, &len);
    int consock = accept_client(sock, &addr);
    if (consock < 0) {
        printf("serve accept failed...\n");
        exit(0);
    } else {
        printf("server accepted the client!\n");
    }

    char buf[BUFLEN];
    printf("Waiting for client message...\n");
    read(consock, buf, BUFLEN);
    printf("Client says: %s", buf);

    bzero(buf, BUFLEN);
    strcpy(buf, "Hello from the server!\n");
    write(consock, buf, BUFLEN);

    close(sock);
}

void test_tcp_client(int port) {
    // Create socket
    int sock = tcp_socket();
    reuse(sock);

    // specify address
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // connect
    if (connect(sock, (struct sockaddr*) &addr, sizeof(addr)) < 0) {
        printf("Connection failed\n");
    }

    char buf[BUFLEN];
    char* hello = "Hello from client\n";
    write(sock, hello, strlen(hello));

    read(sock, buf, BUFLEN);
    printf("Server says: %s", buf);

    close(sock);
}

int main() {
    // test_tcp_server(8002);
    test_tcp_client(7000);
    return 0;
}