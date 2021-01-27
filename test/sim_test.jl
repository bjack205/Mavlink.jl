using Mavlink
using Mavlink.CSockets


function update_sensors(sensor, t=sensor.time_usec)
    sensor.time_usec = t + 1000
    sensor.xacc = 1f-3*randn()
    sensor.yacc = 1f-3*randn()
    sensor.zacc = 1f-3*randn()
    sensor.xgyro = 1f-3*randn()
    sensor.ygyro = 1f-3*randn()
    sensor.zgyro = 1f-3*randn()
    sensor.xmag = 1f-3*randn()
    sensor.ymag = 1f-3*randn()
    sensor.zmag = 1f-3*randn()
    sensor.fields_updated = 0x01ff
    sensor.id = 1
end

function connect_to_px4()
    ## Set up TCP sockets
    sock = CSockets.tcpsocket() 
    addr = CSockets.SockAddrIn(4560, ip"127.0.0.1")
    CSockets.bind(sock, addr)
    CSockets.listen(sock)
    println("Waiting for PX4 to connect...")
    sock_cli = CSockets.accept(sock, addr)
    println("PX4 connected")
    return sock_cli
end

function test_sim(sock_cli)
    ## Initialize sensors
    sensor = Mavlink.HilSensor()
    gps = Mavlink.HilGps()
    oflow = Mavlink.HilOpticalFlow()
    rcraw = Mavlink.HilRcInputsRaw()
    state = Mavlink.HilStateQuaternion()
    cmd = Mavlink.HilActuatorControls()

    ## Initialize buffers
    msg = Mavlink.MavlinkMessage(UInt8)
    buf_out = Mavlink.MavlinkMessage(UInt8)
    buf_in = copy(buf_out)
    status = Mavlink.mavlink_status()

    fd = CSockets.Poll(sock_cli)

    println("Sending first Sensor message...")
    Mavlink.send(sock_cli, sensor, buf_out)
    # msg = Vector{UInt8}("Hello from Sim!\n")
    CSockets.send(sock_cli, msg)
    println("Waiting for PX4 response...")
    p = CSockets.recv_poll(sock_cli, buf_in, 500, fd, verbose=true)

    # println("Freewheeling...")
    # while true
    #     update_sensors(sensor)
    #     Mavlink.send(sock_cli, sensor, buf_out)

    #     p = CSockets.recv_poll(sock_cli, buf_in, 500, fd, verbose=true)
    #     if p > 0
    #         break
    #     end
    # end


    println("Starting loop...")
    freewheeling = 0 
    cnt = 0
    for i = 1:100
        update_sensors(sensor)
        Mavlink.send(sock_cli, sensor, buf_out)
        p = CSockets.poll_recv(fd, buf_in, 500)
        if p > 0
            println("Message received")
        end
        # p = CSockets.poll(fd, 100)
        # if p > 0
        #     recsize = CSockets.recv(sock_cli, buf_in)
        #     Mavlink.parse!(recsize, msg, buf_in)
        #     println("Message received: ", Mavlink.msgid(msg))
        # end
        # @time p = CSockets.recv_poll(sock_cli, buf_in, 1000, fd, verbose=true)
        # if p > 0
        #     freewheeling += 1
        #     Mavlink.parse!(p, msg, buf_in)
        #     println("($freewheeling) Message id: ", Mavlink.msgid(msg))
        # else
        #     cnt += 1
        #     freewheeling = 0
        # end
        # cnt > 10 && break
    end
end

##
sock = connect_to_px4()
test_sim(sock)

## Link sim
Mavlink.send(sock_cli, sensor, buf_out)
Mavlink.receive!(sock_cli, cmd, buf_in, msg, status)
update_sensors(sensor, cmd.time_usec)
Mavlink.send(sock_cli, sensor, buf_out)
Mavlink.receive!(sock_cli, cmd, buf_in, msg, status)

@time for i = 1:100
    Mavlink.receive!(sock_cli, cmd, buf_in, msg, status)
    t = cmd.time_usec 
    println("Received commands at t = ", t * 1e6, " sec")

    # modify sensor command
    Mavlink.send(sock_cli, sensor, buf_out)
    
    # Mavlink.send(sock_cli, gps, buf)
    # Mavlink.send(sock_cli, oflow, buf)
    # Mavlink.send(sock_cli, rcraw, buf)
    # Mavlink.send(sock_cli, state, buf)

end