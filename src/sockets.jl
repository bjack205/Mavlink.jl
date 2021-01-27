export CSockets
module CSockets

using Sockets
const libsockets = joinpath(@__DIR__, "..","deps","sockets.so")
const AF_INET = 2
const ByteVec = Vector{UInt8}

struct Hertz end
Base.:*(time::Real, ::Hertz) = 1/time
const Hz = Hertz()

import Sockets.@ip_str

export 
    @timeat, 
    Hz,
    SockAddrIn,
    @ip_str

"""
    @timeat expr time

Run the `expr` and sleep until the entire time takes at least `time` seconds.
Useful for running a piece of code at a specified rate.

The time can be easily specified in terms of frequency using the `Hertz` type.

# Example
```julia
@timeat begin
    n = rand(50:100)
    rand(n,n) \\ rand(n)
end 10Hz
```
Runs the code at approximately 10 Hz, or 0.1 seconds.
"""
macro timeat(expr::Expr, time)
    return esc(quote
        t_start = time_ns()
        $expr
        t_used = (time_ns() - t_start) / 1e9  # in seconds
        t_used < $time && sleep($time - t_used)
    end)
end

"""
    getbyte(x,i)

Get the `i`th bit from `x` (zero-indexed).
"""
getbyte(x::T,i) where T = UInt8((x & T(0xff) << 8i) >> 8i)

"""
    InAddr

Represents a network address. An alias for the `in_addr` C type.
When an `IPv4` address is passed in, it is passed through `hton`.

# Usage
    InAddr(ip::IPv4)
    InAddr(ip::UInt32)

Any other input will be first passed to the constructor of `IPv4`.

"""
struct InAddr
    s_addr::Culong
    InAddr(ip::UInt32) = new(ip)
end
InAddr(ip::InAddr) = ip
InAddr(ip::IPv4) = InAddr(hton(UInt32(ip)))
InAddr(ip) = InAddr(IPv4(ip))

"""
    SockAddrIn

The Julia version of the `sockaddr_in` C struct. Stores the family,
port, and address. The `bytes` field stores the byte array for these
values and should not be modified.

# Usage
    SockAddrIn(port, [addr; family])
    SockAddr(family::Integer, port::Integer, addr::InAddr)

where `addr` defaults to `Sockets.localhost` and `family` defaults to `AF_INET`.
"""
struct SockAddrIn
    family::Cshort  
    port::Cushort
    addr::Culong 
    bytes::Vector{UInt8}
    function SockAddrIn(family::Integer, port::Integer, addr::InAddr)
        family = UInt16(family)
        port = ntoh(UInt16(port))
        bytes = zeros(UInt8,16) 
        bytes[1] = getbyte(family,0) 
        bytes[2] = getbyte(family,1) 
        bytes[3] = getbyte(port,0) 
        bytes[4] = getbyte(port,1) 
        for i = 1:4
            bytes[4+i] = getbyte(addr.s_addr,i-1)
        end
        new(family, ntoh(UInt16(port)), addr.s_addr, bytes)
    end
end
function SockAddrIn(port::Integer, addr=Sockets.localhost; family::Integer=AF_INET)
    SockAddrIn(family, port, InAddr(addr))    
end

"""
    udpsocket()

Create a UDP C socket
"""
function udpsocket(; reuse::Bool=true) 
    socket = ccall((:udp_socket, libsockets), Cint, ())
    reuse && reuse_socket(socket)
    return socket
end

"""
    tcpsocket()

Create a TCP C socket
"""
function tcpsocket(; reuse::Bool=true)
    socket = ccall((:tcp_socket, libsockets), Cint, ())
    reuse && reuse_socket(socket)
    return socket
end

function reuse_socket(socket::Int32)
    if ccall((:reuse, libsockets), Cint, (Cint,), socket) != 0
        @warn "Failed to set socket options."
    end
end

"""
    bind(socket, addr)

Bind a (server) `socket ` to address and port specified by `addr`.
"""
function bind(socket::Int32, addr::SockAddrIn)
    ccall((:bind_socket, libsockets), Cint, 
        (Cint, Ref{UInt8}), socket, addr.bytes
    )
end

function listen(socket::Int32, backlog::Integer=Int32(3))
    ccall((:listen, libsockets), Cint, (Cint, Cint), socket, Int32(backlog))
end

function accept(socket::Int32, addr::SockAddrIn)
    ccall((:accept_client, libsockets), Cint, (Cint, Ref{UInt8}), socket, addr.bytes)
end

function connect(socket::Int32, addr::SockAddrIn)
    ccall((:connect_to_server, libsockets), Cint, (Cint, Ref{UInt8}), socket, addr.bytes)
end


# WARNING: this allocates!
@inline sendto(socket::Int32, msg::String, addr::SockAddrIn; kwargs...) = 
    sendto(socket, Vector{UInt8}(msg), addr; kwargs...)

# this doesn't
"""
    sendto(socket, msg, addr; kwargs...)

Send `msg` to the address and port specified by `addr::SockAddrIn` via `socket`.
The message `msg` can be either a byte array or a string. A string will be
converted to a byte array, which allocates.

# Arguments
* `len`: length of the message (defaults to `length(msg)`)
* `flags`: passed to C function
* `dest_len`: passed to C function (shouldn't be changed)
"""
function sendto(socket::Int32, msg::Vector{UInt8}, addr::SockAddrIn; 
        len = length(msg), dest_len = Cint(16), flags = Cint(0)
    )
    ccall((:sendto, libsockets), Cssize_t, 
        (Cint, Ptr{Cvoid}, Csize_t, Cint, Ref{UInt8}, Cint),
        socket, msg, len, flags, addr.bytes, dest_len 
    )
end

function send(socket::Int32, msg::ByteVec; len=length(msg), flags = Cint(0))
    ccall((:send, libsockets), Cssize_t, 
        (Cint, Ref{UInt8}, Csize_t, Cint),
        socket, msg, len, flags
    )
end

"""
    recvfrom(socket, buf, addr; kwargs...)

Wait for a message from port/addres specified by `addr::SockAddrIn` and
`socket`, storing the result in `buf`.
"""
function recvfrom(socket::Int32, buf::Vector{UInt8}, addr::SockAddrIn;
        len = length(buf), dest_len = Cint(16), flags = Cint(0)
    )
    ccall((:recvfrom, libsockets), Cssize_t, 
        (Cint, Ptr{Cvoid}, Csize_t, Cint, Ref{UInt8}, Ref{Cint}),
        socket, buf, len, flags, addr.bytes, dest_len 
    )
end

function recv(socket::Int32, buf::ByteVec; len=length(buf), flags = Cint(0))
    ccall((:recv, libsockets), Cssize_t, 
        (Cint, Ref{UInt8}, Csize_t, Cint),
        socket, buf, len, flags
    )
end

"""
    printaddr(addr::SockAddrIn)

Prints the family, port, and address as seen by the C code. Provided for 
debugging purposes.
"""
function printaddr(addr::SockAddrIn)
    ccall((:print_addr, libsockets), Cvoid, (Ref{UInt8},), addr.bytes)
end

const POLLIN = 1
mutable struct Poll
    fd::Cint
    events::Cshort
    revents::Cshort
end

Poll(socket::Integer) = Poll(socket, POLLIN, 0)

function poll(fd::Poll, timeout_ms::Integer)
    ccall((:poll, libsockets), Cint,
        (Ref{Poll}, Culong, Cint),
        Ref(fd), 1, timeout_ms
    )
end

function poll(fds::Vector{Poll}, timeout_ms::Integer)
    ccall((:poll, libsockets), Cint,
        (Ref{Poll}, Culong, Cint),
        fd, length(fds), timeout_ms
    )
end

function recv_poll(socket::Int32, buf::ByteVec, 
        timeout_ms::Integer, fd::Poll=Poll(socket);
        verbose::Bool=false
    )
    @assert socket === fd.fd
    p = poll(fd, timeout_ms)
    if p > 0
        if fd.revents == POLLIN  # new message
            p = CSockets.recv(socket, buf)
        end
    elseif p == 0
        verbose && @warn "poll timeout"
    else
        verbose && error("Poll error")     
    end
    return p
end

function poll_recv(fd::Poll, buf::ByteVec, timeout_ms::Integer)::Cint
    p = poll(fd, timeout_ms)
    if p > 0
        if fd.revents == POLLIN
            return CSockets.recv(fd.fd, buf)
        end
    end
    return p 
end

end  # module