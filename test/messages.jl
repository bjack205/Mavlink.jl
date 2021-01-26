using Mavlink
using Test
for msgname ∈ values(Mavlink.MESSAGE_ID)
    msgtype = Mavlink.eval(Mavlink.camelcase(msgname))
    arr = Mavlink.MavlinkMessage(UInt8)
    msg = msgtype()
    n = fieldcount(msgtype)

    # Change the first and last fields
    setfield!(msg, fieldname(msgtype,1), convert(fieldtype(msgtype,1), 2))
    setfield!(msg, fieldname(msgtype,n), convert(fieldtype(msgtype,n), 3))

    # encode message to byte array
    Mavlink.encode!(arr, msg)
    @test sum(arr) != 0

    # decode and make sure it's the same
    msg_ = msgtype() 
    Mavlink.decode!(arr, msg_)
    @test msg == msg_
end
