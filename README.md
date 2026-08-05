# Nagle's Algorithm in Ada

## Project Overview
This repository implements **Nagle's Algorithm** (RFC 896) and its variants in Ada. Nagle's algorithm improves TCP/IP network efficiency by buffering small packets and sending them in larger chunks to reduce overhead. The implementation includes:
- **Original Nagle's Algorithm**: Strict buffering until MSS or ACK.
- **Minshall's Modification**: Sends full-sized packets immediately.
- **No Nagle (TCP_NODELAY)**: Immediate sending for low-latency applications.
- **Delayed ACK Interaction**: Simulated behavior for testing.

## Features
✅ **Strong Typing**: Custom types for MSS, window size, and packets.
✅ **All Variants Implemented**: Original, Minshall, and No Nagle.
✅ **Helper Functions**: `Has_Enough_Data`, `Merge_Packets`, `Simulate_Delayed_ACK`.
✅ **Edge Case Handling**: Empty inputs, zero window size, large data.
✅ **Modular Design**: Separate procedures for each variant.

## Testing
### Test Philosophy
Tests assume the code is **broken** and aim to **disprove this assumption** (PASS = code works correctly). The suite includes **14 tests** covering:
1. **Functional Correctness**:
   - Original/Minshall/No Nagle logic.
   - Buffering and sending conditions.
2. **Edge Cases**:
   - Empty buffers, zero window size, large data.
3. **Error Handling**:
   - Invalid inputs (e.g., empty data).
4. **Delayed ACK Interaction**:
   - Timeout simulation.

### Why These Tests Matter
- **Verification**: Ensures code matches RFC 896 and variant specifications.
- **Validation**: Confirms the algorithm works for real-world TCP scenarios (e.g., Telnet, HTTP).
- **Reliability**: Catches regressions in buffering logic or packet merging.
- **Safety**: Prevents infinite buffering or incorrect packet drops.

### Test Execution
```bash
make test
```
Output will show `PASS`/`FAIL` for each assertion. Example:
```
TEST 1 - Original Nagle: No Unacked Data
  1.1 Send_Now = True: PASS
  1.2 Packet_To_Send.Size = 3: PASS
```

## Usage
### Compilation
1. **Compile with GNAT**:
   ```bash
   gnatmake -P nagle.gpr
   ```
   or use the Makefile:
   ```bash
   make
   ```

2. **Run Demo**:
   ```bash
   ./bin/nagle_demo
   ```

3. **Run Tests**:
   ```bash
   make test
   ```

### Input/Output
- **Inputs**: `MSS`, `Window_Size`, `Unacknowledged_Flag`, `New_Data` (byte array).
- **Outputs**: `Send_Now` (Boolean), `Packet_To_Send` (merged packet).

## File Structure
```
.
├── nagle.ads          # Package specification
├── nagle.adb          # Implementation
├── nagle.gpr          # GNAT Project File
├── tests.adb          # Test suite (14 tests)
├── main.adb           # Demo program
├── Makefile           # Build automation
├── obj/               # Object files
├── bin/               # Executables
└── README.md          # Documentation
```

## References
- [RFC 896: Congestion Control in IP/TCP Internetworks](https://tools.ietf.org/html/rfc896)
- [Wikipedia: Nagle's Algorithm](https://en.wikipedia.org/wiki/Nagle%27s_algorithm)
