TARGET = poker
CFLAGS = -ggdb
CC = gcc
$(TARGET): $(TARGET).o
	$(CC) -o $@ $^
$(TARGET).o: $(TARGET).c
	$(CC) $(CFLAGS) -c -o $@ $<
.PHONY: clean debug
clean:
	$(RM) $(TARGET) $(TARGET).o
debug: CFLAGS += -DDEBUG
debug: $(TARGET)
