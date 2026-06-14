BIN_NAME=packet_sender
DEFAULT_ETH=enp2s0

SRC_C := $(wildcard *.c)
SRC_CPP := $(wildcard *.cpp)

OBJ:=$(SRC_C:.c=.c.o) $(SRC_CPP:.cpp=.cpp.o)

$(info obj $(OBJ))

.PHONY: build clean trace run

# implicit rules 
# all c objects 
%.c.o: %.c
	gcc $(C_FLAGS) -o $@ -c $<

%.cpp.o: %.cpp
	g++ -std=c++23 -o $@ -c $< 

$(BIN_NAME): $(OBJ) 
	gcc -o $@ -lstdc++ -lm $(OBJ)

build: $(BIN_NAME) 

#debug network socket/connection failures
trace: build 
	strace ${BIN_NAME} ${ARGS}

run: build
	sudo ./${BIN_NAME} ${DEFAULT_ETH}
 
clean:
	rm -f ./${BIN_NAME}
	rm -f ./vgcore*
	rm -f ./*.o
