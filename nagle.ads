-- nagle.ads
-- Specification for Nagle's Algorithm and its variants.
-- Implements:
--   1. Original Nagle's Algorithm (RFC 896)
--   2. Minshall's Modification (sends full-sized packets immediately)
--   3. No Nagle (TCP_NODELAY behavior)
--   4. Interaction with Delayed ACK (simulated)

with Ada.Containers.Vectors;
with Ada.Exceptions;

package Nagle is
   -- Maximum Segment Size (default: 1460 bytes for Ethernet)
   type MSS_Type is range 1 .. 65_535 with Default => 1460;

   -- Window size (current TCP window in bytes)
   type Window_Size_Type is range 0 .. 65_535;

   -- Buffer to accumulate small packets
   type Buffer_Type is array (Positive range <>) of Byte;
   type Byte is mod 256;

   -- State of the sender
   type Sender_State is (Idle, Waiting_For_ACK, Sending);
   type Unacknowledged_Flag is (No_Unacked, Has_Unacked);

   -- Exception for invalid inputs
   Invalid_Input_Error : exception;

   -- Packet structure
   type Packet is record
      Data : Buffer_Type;
      Size : Natural;
   end record;

   -- Packet list (for buffering)
   package Packet_Vectors is new Ada.Containers.Vectors(
      Index_Type   => Natural,
      Element_Type => Packet
   );
   use Packet_Vectors;

   -- Main procedures for each variant
   -- Original Nagle: Strict buffering until MSS or ACK
   procedure Original_Nagle (
      MSS           : in     MSS_Type;
      Window_Size   : in     Window_Size_Type;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- Minshall's Nagle: Send if last packet is full-sized
   procedure Minshall_Nagle (
      MSS           : in     MSS_Type;
      Window_Size   : in     Window_Size_Type;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- No Nagle: Send immediately (TCP_NODELAY)
   procedure No_Nagle (
      New_Data      : in     Buffer_Type;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- Helper: Check if buffer has enough data for MSS
   function Has_Enough_Data (
      Buffer : Packet_Vectors.Vector;
      MSS    : MSS_Type
   ) return Boolean;

   -- Helper: Merge small packets into a single MSS-sized packet
   function Merge_Packets (
      Buffer : Packet_Vectors.Vector;
      MSS    : MSS_Type
   ) return Packet;

   -- Helper: Simulate Delayed ACK interaction
   procedure Simulate_Delayed_ACK (
      Unacked       : in out Unacknowledged_Flag;
      Time_Elapsed  : in     Natural;  -- Simulated time in ms
      ACK_Timeout   : in     Natural := 500  -- Default Delayed ACK timeout
   );

end Nagle;
