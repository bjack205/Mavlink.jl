using Sockets
using Mavlink
using Mavlink.CSockets: SockAddrIn
using Mavlink.CSockets

##
sock = CSockets.udpsocket()
gcAddr = SockAddrIn(14550, ip"127.0.0.1")
CSockets.printaddr(gcAddr)
# locAddr = SockAddrIn(14551, 0)
# CSockets.printaddr(locAddr)
# CSockets.bind(sock, locAddr)


# Make messages
sysid = 1
compid = 1 
hbt = Mavlink.Heartbeat(0,0,0,0,0,0)
sys = Mavlink.SysStatus(0,0,0,500,11000,-1,0,0,0,0,0,0,-1)
pos = Mavlink.LocalPositionNed(10,1,2,3,4,5,6)
att = Mavlink.Attitude(10,1.2,1.7,3.14,0.01, 0.02,0.03)

msg = Mavlink.MavlinkMessage(UInt8)
@allocated Mavlink.send(sock, gcAddr, hbt, msg, component_id=1, system_id=1)

cond = true
t = @async while cond
    @timeat begin
        Mavlink.encode!(msg, hbt, component_id=compid)
        CSockets.sendto(sock, msg, gcAddr)
        Mavlink.encode!(msg, sys, component_id=compid)
        CSockets.sendto(sock, msg, gcAddr)
        Mavlink.encode!(msg, pos, component_id=compid)
        CSockets.sendto(sock, msg, gcAddr)
        Mavlink.encode!(msg, att, component_id=compid)
        CSockets.sendto(sock, msg, gcAddr)
    end 1000Hz
end
cond = false 

buf = zeros(UInt8, 2041) 
hbt2 = Mavlink.Heartbeat(10,0,0,0,0,0)
msg2 = Mavlink.MavlinkMessage(UInt8)
status = Mavlink.mavlink_status()
Mavlink.receive!(sock, gcAddr, hbt2, buf, msg2, status)

do_recv = true
t = @async while do_recv 
    Mavlink.receive!(sock, gcAddr, hbt2, buf, msg2, status)
end
do_recv = false

Int(Mavlink._msgid(msg2))
Mavlink.msgid(msg2)
Mavlink.decode(msg2)


##
sock = UDPSocket()
@which wait(sock.recvnotify)
locAddr = IPv4(0)
locport = 14551
gcAddr = ip"127.0.0.1"
gcport = 14550
bind(sock, locAddr, locport, reuseaddr=true)

function receive(sock)
    hbt = Mavlink.Heartbeat(0,0,0,0,0,0)
    @async begin
        while true
            allocs_r = @allocated buf = recv(sock)
            allocs_d = @allocated Mavlink.decode!(buf,hbt)
            println(hbt)
            println("Allocations: $allocs_r, $allocs_d")
        end
    end 
end
receive(sock)

pos = Mavlink.LocalPositionNed(10,1,2,3,4,5,6)
arr = Mavlink.MavlinkMessage(UInt8)
Mavlink.encode!(arr, pos)
while true
    send(sock, gcAddr, gcport, arr)
    sleep(0.01)
end
send(sock, IPv4(0), 14551, buf)

