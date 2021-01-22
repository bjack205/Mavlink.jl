using BenchmarkTools
using Mavlink
import Mavlink: libmavlink
import Mavlink: MavlinkMessage, LocalPositionNed, Attitude, SysStatus, Heartbeat

##
pos = LocalPositionNed(10,1,2,3,4,5,6)
att = Attitude(10,1,2,3,4,5,6)
sys = SysStatus(0,0,0,0,0,0,0,0,0,0,0,0,0)
hbt = Heartbeat(0,0,0,0,0,0)
marr = MavlinkMessage(UInt8)
Mavlink.mavlinkname(pos) == "local_position_ned"
Mavlink.mavlinkname(att) == "attitude"
Mavlink.mavlinkname(sys) == "sys_status"
Mavlink.mavlinkname(hbt) == "heartbeat"
Mavlink.encode!(marr, pos, component_id=2)
msg = MavlinkMessage(marr)
msg.sysid == 1
msg.compid == 2

Mavlink.encode!(marr, att, component_id=2)
Mavlink.encode!(marr, sys, component_id=2)
Mavlink.encode!(marr, hbt, component_id=2)

pos2 = LocalPositionNed(0,0,0,0,0,0,0)
Mavlink.encode!(marr, pos, component_id=2)
Mavlink.decode!(marr, pos2)
for i = 1:fieldcount(LocalPositionNed)
    getfield(pos,i) == getfield(pos2,i)
end


##
ccall((:main, libmavlink), Cint, ())
ccall((:foo, libmavlink), Cint, ())
ccall((:bar, libmavlink), Cint, (Cint,), 2)
msg = MavlinkMessage()
arr = Vector{UInt8}(undef, 291)
ccall((:set_msg, libmavlink), Cvoid, (Ref{UInt8},), arr)
msg = MavlinkMessage(arr)

msg.checksum == 12
msg.compid == 17
msg.msgid == 17
msg.payload64[1] == 300
msg.payload64[2] == 20
msg.payload64[end] == 50
msg.ck[1] == 101
msg.ck[2] == 101
msg.signature[2] == 51
msg.signature[end] == 51
Mavlink.PAYLOAD_IDX_TERM + 13 + 2

arr = MavlinkMessage(UInt8)
pos = LocalPositionNED(10,1,2,3,4,5,6)
ccall((:local_position_ned_encode, libmavlink), UInt16,
    (UInt8, UInt8, Ref{UInt8}, Ref{LocalPositionNED}),
    10, 11, arr, Ref(pos)
)
msg = MavlinkMessage(arr)


arr = Vector{UInt8}(undef, 291)
ccall((:local_position_ned_pack, libmavlink), UInt16, 
    (UInt8, UInt8, Ref{UInt8}, UInt32, 
    Cfloat, Cfloat, Cfloat, Cfloat, Cfloat, Cfloat),
    10, 11, arr, 10, 1f0, 2f0, 3f0, 4f0, 5f0, 6f0
)
msg = MavlinkMessage(arr)
msg.sysid == 10
msg.compid == 11
msg.msgid == 32
Int(msg.payload64[1]) == 4575657221408423946
Int(msg.payload64[2]) == 4629700418010611712
Int(msg.payload64[3]) == 4656722015783223296
msg.ck[1] == 0
msg.ck[2] == 0
msg.signature[1] == 0 
msg.signature[2] == 0

buf = Vector{UInt8}(undef, 2041)
ccall((:to_send_buffer, libmavlink), UInt16, (Ref{UInt8}, Ref{UInt8}), buf, arr)
Int.(buf)


function pack!(marr::Vector{UInt8}, data::T;
        system_id = 1, component_id = 2
    ) where T <: Mavlink.MavlinkMsg
    fields = [getfield(msg, i) for i = 1:fieldcount(T)]
    argtypes = tuple(UInt8, UInt8, Ref{UInt8}, UInt32, fieldtypes(T)...)
    ccall((:local_position_ned_encode, libmavlink), UInt16, 
        (UInt8, UInt8, Ref{UInt8}, Ref{LocalPositionNED}),
        system_id, component_id, marr, data
    )
end
marr = MavlinkMessage(UInt8) 
msg = LocalPositionNED(10,1,2,3,4,5,6) 
pack!(marr, msg)

function to_buffer!(buf::Vector{UInt8}, marr::Vector{UInt8})
    ccall((:to_send_buffer, libmavlink), UInt16, 
        (Ref{UInt8}, Ref{UInt8}), buf, marr)
end

function serialize!(buf::Vector{UInt8}, marr::Vector{UInt8}, msg::LocalPositionNED;
        system_id = 1, component_id = 2, time_boot_ms = boottime_ms()
    )
    ccall((:local_position_ned_serialize, libmavlink), UInt16, 
        (Ref{UInt8}, UInt8, UInt8, Ref{UInt8}, UInt32, 
        Cfloat, Cfloat, Cfloat, Cfloat, Cfloat, Cfloat),
        buf, system_id, component_id, marr, time_boot_ms, 
        msg.x, msg.y, msg.z, msg.vx, msg.vy, msg.vz 
    )
end
buf = Vector{UInt8}(undef, 2041)
marr = Vector{UInt8}(undef, 291)
msg = LocalPositionNED(1,2,3,4,5,6) 
serialize(buf, marr, msg, system_id = 10, component_id = 12, time_boot_ms = 10)
pack!(marr, msg, system_id = 10, component_id = 12, time_boot_ms = 10)
to_buffer!(buf, marr)
Int.(buf)
@btime serialize($buf, $marr, $msg)
@btime begin
    pack!($marr, $msg)
    to_buffer!($buf, $marr)
end