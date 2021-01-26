
abstract type MavlinkMsg end

@generated function Base.zero(::Type{NTuple{N,T}}) where {N,T}
    zs = [:(zero($T)) for i = 1:N]
    :(tuple($(zs...)))
end
@generated function (::Type{T})() where T <: MavlinkMsg
    zs = [:(zero($ft)) for ft in fieldtypes(T)]
    :(T($(zs...)))
end

@generated function Base.:(==)(a::T, b::T) where T <: MavlinkMsg
    mapreduce(n -> :(a.$n == b.$n), (a,b) -> :($a && $b), fieldnames(T))
end
@generated function Base.:(≈)(a::T, b::T) where T <: MavlinkMsg
    mapreduce(n -> :(a.$n ≈ b.$n), (a,b) -> :($a && $b), fieldnames(T))
end

const MESSAGE_ID = Dict(
    0 => :heartbeat,
    1 => :sys_status,
    30 => :attitude,
    32 => :local_position_ned,
    92 => :hil_rc_inputs_raw,
    93 => :hil_actuator_controls,
    107 => :hil_sensor,
    113 => :hil_gps,
    114 => :hil_optical_flow,
    115 => :hil_state_quaternion,
)

mutable struct LocalPositionNed <: MavlinkMsg
    time_boot_ms::UInt32
    x::Float32
    y::Float32
    z::Float32
    vx::Float32
    vy::Float32
    vz::Float32
end

mutable struct Heartbeat <: MavlinkMsg
    custom_mode::UInt32
    type::UInt8
    autopilot::UInt8
    base_mode::UInt8
    system_status::UInt8
    mavlink_version::UInt8
end

mutable struct Attitude <: MavlinkMsg
    time_boot_ms::UInt32
    roll::Cfloat
    pitch::Cfloat
    yaw::Cfloat
    rollspeed::Cfloat
    pitchspeed::Cfloat
    yawspeed::Cfloat
end

mutable struct SysStatus <: MavlinkMsg
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

mutable struct HilActuatorControls <: MavlinkMsg
    time_usec::UInt64
    flags::UInt64
    controls::NTuple{16,Float32}
    mode::UInt8
end

mutable struct HilSensor <: MavlinkMsg
    time_usec::UInt64
    xacc::Float32
    yacc::Float32
    zacc::Float32
    xgyro::Float32
    ygyro::Float32
    zgyro::Float32
    xmag::Float32
    ymag::Float32
    zmag::Float32
    abs_pressure::Float32
    diff_pressure::Float32
    pressure_alt::Float32
    temperature::Float32
    fields_updated::UInt32
    id::UInt8
end

mutable struct HilGps <: MavlinkMsg
    time_usec::UInt64
    lat::Int32
    lon::Int32
    alt::Int32
    eph::UInt16
    epv::UInt16
    vel::UInt16
    vn::Int16
    ve::Int16
    vd::Int16
    cog::UInt16
    fix_type::UInt8
    satellites_visible::UInt8
    id::UInt8
    yaw::UInt16
end

mutable struct HilOpticalFlow <: MavlinkMsg
    time_usec::UInt64
    integration_time_us::UInt32
    integrated_x::Float32
    integrated_y::Float32
    integrated_xgyro::Float32
    integrated_ygyro::Float32
    integrated_zgyro::Float32
    time_delta_distance_us::UInt32
    distance::Float32
    temperature::Int16
    sensor_id::UInt8
    quality::UInt8
end

mutable struct HilStateQuaternion <: MavlinkMsg
    time_usec::UInt64
    attitude_quaternion::NTuple{4,Float32}
    rollspeed::Float32
    pitchspeed::Float32
    yawspeed::Float32
    lat::Int32
    lon::Int32
    alt::Int32
    vx::Int16
    vy::Int16
    vz::Int16
    ind_airspeed::UInt16
    true_airspeed::UInt16
    xacc::Int16
    yacc::Int16
    zacc::Int16
end

mutable struct HilRcInputsRaw <: MavlinkMsg
    time_usec::UInt64
    chan1_raw::UInt16
    chan2_raw::UInt16
    chan3_raw::UInt16
    chan4_raw::UInt16
    chan5_raw::UInt16
    chan6_raw::UInt16
    chan7_raw::UInt16
    chan8_raw::UInt16
    chan9_raw::UInt16
    chan10_raw::UInt16
    chan11_raw::UInt16
    chan12_raw::UInt16
    rssi::UInt8
end