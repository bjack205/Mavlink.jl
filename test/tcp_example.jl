using Mavlink
using Sockets

# Create the socket and specify the address
sock = CSockets.tcpsocket() 
addr = CSockets.SockAddrIn(4560, ip"127.0.0.1")

# Server Example
CSockets.bind(sock, addr)
CSockets.listen(sock)
sock_cli = CSockets.accept(sock, addr)

# start up client in netcat and send a message
"""
nc localhost 4560
howdy
""" # start netcat TCP client
buf = zeros(UInt8, 100)
nrecv = CSockets.recv(sock_cli, buf)
String(buf[1:nrecv])

#  sent a message to netcat client
msg = Vector{UInt8}("howdy, pardner\n")
CSockets.send(sock_cli, msg)


# Client example
"""
nc localhost 4561 -l
hello from the server
""" # start netcat TCP server
sock = CSockets.tcpsocket() 
addr = CSockets.SockAddrIn(4561, ip"127.0.0.1")
CSockets.connect(sock, addr)

#  receive the message from the server
buf = zeros(UInt8, 100)
nrecv = CSockets.recv(sock, buf)
String(buf[1:nrecv])

#  sent message to the server
msg = Vector{UInt8}("hello from the client\n")
CSockets.send(sock, msg)