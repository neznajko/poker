TARGET = poker
$(TARGET): $(TARGET).o
	ld -m elf_i386 $^ -o $@
$(TARGET).o: $(TARGET).asm communism.asm
	nasm -f elf -gdwarf -o $@ $< $(ASFLAGS)
.PHONY: clean debug
clean:
	$(RM) $(TARGET) $(TARGET).o
debug: ASFLAGS = -DDEBUG
debug: $(TARGET)
