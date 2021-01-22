using Mavlink
using Mavlink.CSockets: SockAddrIn

##
buf = zeros(UInt8, 20)
sock = CSockets.udpsocket()
addr = CSockets.SockAddrIn(14549,0)
CSockets.printaddr(addr)
CSockets.bind(sock, addr)
r = CSockets.recvfrom(sock, buf, addr)
String(buf[1:r])
CSockets.sendto(sock, buf[1:r], addr)
CSockets.printaddr(addr)

sock = CSockets.udpsocket()
addr = CSockets.SockAddrIn(14551,0)
@allocated CSockets.sendto(sock, buf, addr)

##
using Statistics
times = zeros(10)
for i = 1:10
    times[i] = @elapsed begin
        @timeat begin
            n = rand(50:100)
            rand(n,n) \ rand(n)
        end 10Hz
    end
end
std(times)
abs(mean(times) - 0.1) < 0.01