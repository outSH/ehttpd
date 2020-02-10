# ehttp makefile

AS = as
LD = ld
ASFLAGS = -32
LDFLAGS = -melf_i386
TEST_DIR = test
TEST_CONTENT_DIR = test/web-content
SRC_DIR = src
OUT_DIR = bin

EHTTP_SOURCES = \
	$(SRC_DIR)/ehttpd.s \
	$(SRC_DIR)/linux.s \
	$(SRC_DIR)/io_helpers.s \
	$(SRC_DIR)/errors.s \
	$(SRC_DIR)/request.s

# Targets
.DEFAULT_GOAL := ehttpd

all: ehttpd ehttpd_test

debug: ASFLAGS += -g --defsym _DEBUG=1 -defsym _DEBUG_MESSAGE_BUF=1 
debug: all

ehttpd: ehttpd.o
	$(LD) $(OUT_DIR)/$^ -o $(OUT_DIR)/$@ $(LDFLAGS)

ehttpd.o: $(EHTTP_SOURCES)
	$(AS) $^ -o $(OUT_DIR)/$@ $(ASFLAGS)

# Test
ehttpd_test: $(TEST_CONTENT_DIR)
	cp -fr $(TEST_CONTENT_DIR)/* $(OUT_DIR)

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)/*
