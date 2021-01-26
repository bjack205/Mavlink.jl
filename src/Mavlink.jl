module Mavlink

const MAVLINK_MAX_PAYLOAD = 255
const MAVLINK_NUM_CHECKSUM_BYTES = 2
const MAVLINK_SIGNATURE_BLOCK_LEN = 13
const libmavlink = joinpath(@__DIR__,"..","deps","libmavlink.so")
const STATUS_SIZE = 40

const MAVLINK_BUFFER_SIZE = (MAVLINK_MAX_PAYLOAD + MAVLINK_NUM_CHECKSUM_BYTES + 7) ÷ 8
const PAYLOAD_IDX_TERM = 13+8*(MAVLINK_BUFFER_SIZE)-1
const BOOT_TIME = time() 
const MSG_SIZE = 12 + MAVLINK_BUFFER_SIZE*8 + 2 + 13

const ByteVec = Vector{UInt8}

include("utils.jl")
include("sockets.jl")
include("messages.jl")

export CSockets

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
        # msgid = UInt32(arr[10]) + (UInt32(arr[11]) << 8) + (UInt32(arr[12]) << 16)
        msgid = _msgid(arr)

        pay = reinterpret(UInt64, view(arr, 13:PAYLOAD_IDX_TERM))
        payload = tuple($(pay_...))
        ck = (arr[PAYLOAD_IDX_TERM+1], arr[PAYLOAD_IDX_TERM+2])
        signature = tuple($(sig_...))
        MavlinkMessage(checksum, magic, len, incompat_flags, compat_flags, seq, 
            sysid, compid, msgid, payload, ck, signature)
    end
end
_msgid(msg::Vector{UInt8}) = UInt32(msg[10]) + (UInt32(msg[11]) << 8) + (UInt32(msg[12]) << 16)
msgid(msg::MavlinkMessage) = MESSAGE_ID[msg.msgid]
msgid(msg::Vector{UInt8}) = MESSAGE_ID[_msgid(msg)] 

# struct MavlinkStatus
#     msg_received::UInt8
#     buffer_overrun::UInt8
#     parse_error::UInt8
#     parse_state
#     packet_idx::UInt8
#     current_rx_seq::UInt8
#     current_tx_seq::UInt8
#     packet_rx_success_count::UInt16
#     packet_rx_drop_count::UInt16
#     flags::UInt8
#     signature_wait::UInt8
#     signing::MavlinkSigning
#     signing_streams::MavlinkSigningStreams
# end
mavlink_status() = zeros(UInt8, STATUS_SIZE) 

for msg in values(MESSAGE_ID) 
    Msg = Symbol(camelcase(msg))
    encodefn = "mavlink_msg_" * string(msg) * "_encode"
    decodefn = "mavlink_msg_" * string(msg) * "_decode"
    @eval begin
        function mavlinkname(::$Msg)
            return $(string(msg))
        end
        function encode!(marr::Vector{UInt8}, data::$Msg,
                system_id = 1, component_id = 1
            )
            ccall(($encodefn, libmavlink), UInt16, 
                (UInt8, UInt8, Ref{UInt8}, Ref{$Msg}),
                system_id, component_id, marr, data
            )
        end
        function decode!(marr::Vector{UInt8}, data::$Msg)
            ccall(($decodefn, libmavlink), Cvoid,
                (Ref{UInt8}, Ref{$Msg}),
                marr, data
            )
        end
    end
end

function decode(msg::ByteVec)
    Msg = eval(camelcase(msgid(msg)))()
    decode!(msg, Msg)
    return Msg
end

function parse_message(recsize::Integer, buf::ByteVec, msg::ByteVec, status::ByteVec=mavlink_status(); chan=0)
    ccall((:parse_msg, Mavlink.libmavlink), Int8, 
        (UInt8, Cssize_t, Ref{UInt8}, Ref{UInt8}, Ref{UInt8}),
        chan, recsize, buf, msg, status
    )
end

function send(sock::Int32, addr::CSockets.SockAddrIn, data::MavlinkMsg, 
        msg=MavlinkMessage(UInt8); component_id=1, system_id=1)
    Mavlink.encode!(msg, data, component_id=component_id, system_id=system_id)
    CSockets.sendto(sock, msg, addr)
end

function receive!(sock::Int32, addr::CSockets.SockAddrIn, data::MavlinkMsg, 
        buf::ByteVec=MavlinkMessage(UInt8), msg::ByteVec=MavlinkMessage(UInt8), 
        status=mavlink_status()
    )
    recsize = CSockets.recvfrom(sock, buf, addr);

    # get mavlink message from buffer
    ccall((:parse_msg, Mavlink.libmavlink), Int8, 
        (UInt8, Cssize_t, Ref{UInt8}, Ref{UInt8}, Ref{UInt8}),
        0, recsize, buf, msg, status
    )

    # decode message into data type
    Mavlink.decode!(msg, data)
end

end # module
