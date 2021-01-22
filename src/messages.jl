
abstract type MavlinkMsg end
@generated function (::Type{T})() where T <: MavlinkMsg
    :(T($(zeros(fieldcount(T))...)))
end

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