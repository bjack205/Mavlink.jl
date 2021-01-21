#include <mavlink.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>

typedef struct __attribute__((packed)) _mavlink_message {
	uint16_t checksum;      ///< sent at end of packet
	uint8_t magic;          ///< protocol magic marker
	uint8_t len;            ///< Length of payload
	uint8_t incompat_flags; ///< flags that must be understood
	uint8_t compat_flags;   ///< flags that can be ignored if not understood
	uint8_t seq;            ///< Sequence of packet
	uint8_t sysid;          ///< ID of message sender system/aircraft
	uint8_t compid;         ///< ID of the message sender component
	uint32_t msgid:24;      ///< ID of message in payload
	uint64_t payload64[(MAVLINK_MAX_PAYLOAD_LEN+MAVLINK_NUM_CHECKSUM_BYTES+7)/8];
	uint8_t ck[2];          ///< incoming checksum bytes
	uint8_t signature[MAVLINK_SIGNATURE_BLOCK_LEN];
} mavlink_message;

mavlink_message gen_msg() {
    mavlink_message msg;
    // msg.seq = 10;
    // msg.sysid = 11;
    // msg.msgid = 12;
    // msg.payload64[0] = 1;
    // msg.payload64[1] = 2;
    // msg.payload64[2] = 4;
    return msg;
}

void set_msg(mavlink_message* msg) {
    msg->checksum = 12;
    msg->magic= 13;
    msg->len = 123;
    msg->incompat_flags= 14;
    msg->compat_flags= 15;
    msg->seq= 16;
    msg->sysid= 17;
    msg->compid= 17;
    msg->msgid= 70000;
    msg->payload64[0] = 300;
    msg->payload64[1] = 20;
    msg->payload64[32] = 50;
    msg->ck[0] = 101;
    msg->ck[1] = 101;
    msg->signature[1] = 51;
    msg->signature[12] = 51;
}


uint16_t local_position_ned_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               mavlink_local_position_ned_t* data) {
    return mavlink_msg_local_position_ned_encode(system_id, component_id, msg, data);
}


uint16_t heartbeat_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg, 
                               mavlink_heartbeat_t* data) {
    return mavlink_msg_heartbeat_encode(system_id, component_id, msg, data);
}

uint16_t sys_status_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               mavlink_sys_status_t* data) {
    mavlink_msg_sys_status_encode(system_id, component_id, msg, data);
}

uint16_t attitude_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               mavlink_attitude_t* data) {
    mavlink_msg_attitude_encode(system_id, component_id, msg, data);
}

uint16_t to_send_buffer(uint8_t *buf, const mavlink_message_t *msg) {
    return mavlink_msg_to_send_buffer(buf, msg);
}


int foo() {
    return 10;
}

int bar(int a) {
    return 2*a;
}

int main() {
    printf("Size of uint32: %ld, Original size: %ld, New Size: %ld\n", 
        sizeof(uint32_t), sizeof(mavlink_message_t), sizeof(mavlink_message));
    printf("Buffer size: %d\n", (MAVLINK_MAX_PAYLOAD_LEN+MAVLINK_NUM_CHECKSUM_BYTES+7)/8);
    mavlink_message msg;
    mavlink_msg_local_position_ned_pack(10, 11, &msg, 10, 1, 2, 3, 4, 5, 6);
    printf(" checksum = %d\n magic = %d\n compat_flags = %d\n msgid = %d\n", msg.checksum, msg.magic, msg.compat_flags, msg.msgid);
    printf(" p0 = %ld\n p1 = %ld\n p3 = %ld\n", msg.payload64[0], msg.payload64[1], msg.payload64[2]);
    printf(" ck0 = %d\n ch1 = %d\n sig0 = %d\n sig2 = %d\n", msg.ck[0], msg.ck[1], msg.signature[0], msg.signature[2]);

    uint8_t buf[2041];
    mavlink_msg_to_send_buffer(buf, &msg);
    printf("\nSerial Out\n");
    for (int i = 0; i < 10; i++) {
        printf("  %d\n", buf[i]);
    }


    return 0;
}
