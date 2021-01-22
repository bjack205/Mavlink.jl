CC=gcc

SOURCES=mavlib.c
CFLAGS=-I ./c_library_v2/common
OBJECTS=$(SOURCES:.c=.o)

lib: $(SOURCES)
	$(CC) --shared -FPIC $(CFLAGS) -o libmavlink.so $(SOURCES)

main: $(SOURCES)
	$(CC) $(CFLAGS) -o main $(SOURCES)

sockets:
	$(CC) $(CFLAGS) -o sockets sockets.c

clean:
	rm *.so
