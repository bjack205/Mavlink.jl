module Mavlink

const MAVLINK_MAX_PAYLOAD = 255
const MAVLINK_NUM_CHECKSUM_BYTES = 2
const MAVLINK_SIGNATURE_BLOCK_LEN = 13
const libmavlink = joinpath(@__DIR__,"..","deps","libmavlink.so")

const MAVLINK_BUFFER_SIZE = (MAVLINK_MAX_PAYLOAD + MAVLINK_NUM_CHECKSUM_BYTES + 7) ÷ 8
const PAYLOAD_IDX_TERM = 13+8*(MAVLINK_BUFFER_SIZE)-1
const BOOT_TIME = time() 
const MSG_SIZE = 12 + MAVLINK_BUFFER_SIZE*8 + 2 + 13

boottime_ms() = UInt32(round((time() - BOOT_TIME)*1000))

Base.@kwdef struct MavlinkMessage
    checksum::UInt16 = 0
    magic::UInt8 = 0
    len::UInt8 = 0
    incompat_flags::UInt8 = 0
    compat_flags::UInt8 = 0
    seq::UInt8 = 0
    sysid::UInt8 = 0
    compid::UInt8 = 0
    msgid::UInt32 = 0
    payload64::NTuple{MAVLINK_BUFFER_SIZE,UInt64} = NTuple{MAVLINK_BUFFER_SIZE,UInt64}(zeros(UInt64,MAVLINK_BUFFER_SIZE))
    ck::NTuple{2,UInt8} = (0,0)
    signature::NTuple{MAVLINK_SIGNATURE_BLOCK_LEN, UInt8} = NTuple{MAVLINK_SIGNATURE_BLOCK_LEN,UInt8}(zeros(UInt8,MAVLINK_SIGNATURE_BLOCK_LEN))
    function MavlinkMessage(checksum, magic, len, incompat_flags, compat_flags, seq,
        sysid, compid, msgid, payload64, ck, signature)
        new(checksum, magic, len, incompat_flags, compat_flags, seq,
        sysid, compid, msgid, payload64, ck, signature)
    end
end

MavlinkMessage(::Type{UInt8}) = Vector{UInt8}(undef, MSG_SIZE)

@generated function MavlinkMessage(arr::Vector{UInt8})
    pay_ = [:(pay[$i]) for i = 1:MAVLINK_BUFFER_SIZE]
    sig_ = [:(arr[$i]) for i = PAYLOAD_IDX_TERM+3:2 + PAYLOAD_IDX_TERM + MAVLINK_SIGNATURE_BLOCK_LEN]
    return quote
        @assert length(arr) == 12 + MAVLINK_BUFFER_SIZE*8 + 2 + MAVLINK_SIGNATURE_BLOCK_LEN 
        checksum       = UInt16(arr[1]) + (UInt16(arr[2]) << 8)
        magic          = arr[3]
        len            = arr[4]
        incompat_flags = arr[5]
        compat_flags   = arr[6]
        seq            = arr[7]
        sysid          = arr[8] 
        compid         = arr[9]  
        msgid = UInt32(arr[10]) + (UInt32(arr[11]) << 8) + (UInt32(arr[12]) << 16)

        pay = reinterpret(UInt64, view(arr, 13:PAYLOAD_IDX_TERM))
        payload = tuple($(pay_...))
        ck = (arr[PAYLOAD_IDX_TERM+1], arr[PAYLOAD_IDX_TERM+2])
        signature = tuple($(sig_...))
        MavlinkMessage(checksum, magic, len, incompat_flags, compat_flags, seq, 
            sysid, compid, msgid, payload, ck, signature)
    end
end

abstract type MavlinkMsg end
struct LocalPositionNed <: MavlinkMsg
    time_boot_ms::UInt32
    x::Float32
    y::Float32
    z::Float32
    vx::Float32
    vy::Float32
    vz::Float32
end

struct Heartbeat <: MavlinkMsg
    custom_mode::UInt32
    type::UInt8
    autopilot::UInt8
    base_mode::UInt8
    system_status::UInt8
    mavlink_version::UInt8
end

struct Attitude <: MavlinkMsg
    time_boot_ms::UInt32
    roll::Cfloat
    pitch::Cfloat
    yaw::Cfloat
    rollspeed::Cfloat
    pitchspeed::Cfloat
    yawspeed::Cfloat
end

struct SysStatus <: MavlinkMsg
    onboard_control_sensors_present::UInt32
    onboard_control_sensors_enabled::UInt32
    onboard_control_sensors_health::UInt32
    load::UInt16
    voltage_battery::UInt16
    current_battery::Int16
    drop_rate_comm::UInt16
    errors_comm::UInt16
    errors_count1::UInt16
    errors_count2::UInt16
    errors_count3::UInt16
    errors_count4::UInt16
    battery_remaining::Int8
end

end # module
