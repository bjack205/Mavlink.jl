using Mavlink
using Mavlink.CSockets

sock = CSockets.tcpsocket() 
addr = CSockets.SockAddrIn(4560, ip"127.0.0.1")

# Server Example
CSockets.bind(sock, addr)
CSockets.listen(sock)
sock_cli = CSockets.accept(sock, addr)

fd = CSockets.Poll(sock_cli, 1, 0)
CSockets.poll(fd, 5000)
buf = zeros(UInt8, 100)
CSockets.recv(sock_cli, buf)
String(buf[1:2])