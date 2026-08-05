# Makefile for Nagle's Algorithm
.PHONY: all test clean

GNAT = gnatmake
OBJ_DIR = obj
BIN_DIR = bin

all: $(BIN_DIR)/nagle_demo $(BIN_DIR)/tests

$(BIN_DIR)/nagle_demo: nagle.gpr nagle.ads nagle.adb main.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P nagle.gpr -o $(BIN_DIR)/nagle_demo

$(BIN_DIR)/tests: tests.adb nagle.ads nagle.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb nagle.ads nagle.adb

test: $(BIN_DIR)/tests
	@echo "Running tests..."
	@$(BIN_DIR)/tests

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*
