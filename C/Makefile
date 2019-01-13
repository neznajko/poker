TARGET = poker
CFLAGS = -ggdb -Wall
#CFLAGS += -DDEBUG
CC = gcc
$(TARGET): $(TARGET).o
	$(CC) -o $@ $^
$(TARGET).o: $(TARGET).c
	$(CC) $(CFLAGS) -c -o $@ $<
.PHONY: clean
clean:
	$(RM) $(TARGET) $(TARGET).o
