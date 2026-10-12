# SwarmRide firmware: host build and test against the MATLAB vectors.
#   make test        build both number types and run the host test
#   make strict      extra warnings + static analyzer on both number types (review build)
# On Windows with MSYS2:  mingw32-make test   (or: make CC=gcc test)
CC     ?= gcc
CFLAGS ?= -std=c99 -O2 -Wall -Wextra -pedantic
SRC     = src/sr_preview.c src/sr_lpv.c src/sr_semiactive.c src/sr_drive.c src/sr_bank.c src/sr_ctrl.c

all: host_test host_test_float

host_test: $(SRC) test/host_test.c include/*.h
	$(CC) $(CFLAGS) -Iinclude -o $@ $(SRC) test/host_test.c -lm

host_test_float: $(SRC) test/host_test.c include/*.h
	$(CC) $(CFLAGS) -DSR_USE_FLOAT -Iinclude -o $@ $(SRC) test/host_test.c -lm

test: all
	./host_test test/vectors
	./host_test_float test/vectors

# strict review build: extra warnings and GCC's static analyzer, both number types (must print nothing)
STRICT = -std=c99 -O2 -Wall -Wextra -pedantic -Wshadow -Wconversion -Wdouble-promotion -Wfloat-equal          -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes -fanalyzer
strict:
	$(CC) $(STRICT) -Iinclude -c $(SRC)
	$(CC) $(STRICT) -DSR_USE_FLOAT -Iinclude -c $(SRC)
	rm -f *.o

clean:
	rm -f host_test host_test_float host_test.exe host_test_float.exe

.PHONY: all test strict clean
