-- nagle.ads
-- Specification for Nagle's Algorithm and its variants.
-- Implements:
--   1. Original Nagle's Algorithm (RFC 896)
--   2. Minshall's Modification (sends full-sized packets immediately)
--   3. No Nagle (TCP_NODELAY behavior)
--   4. Interaction with Delayed ACK (simulated)

with Ada.Containers.Vectors;

package Nagle is
   -- Maximum Segment Size (default: 1460 bytes for Ethernet)
   Default_MSS : constant Natural := 1460;

   -- Byte type for packet data
   type Byte is mod 256;

   -- Buffer to accumulate small packets (dynamic array)
   type Buffer_Type is array (Positive range <>) of Byte;

   -- Access type for dynamic buffer data
   type Buffer_Access is access Buffer_Type;

   -- State of the sender
   type Unacknowledged_Flag is (No_Unacked, Has_Unacked);

   -- Exception for invalid inputs
   Invalid_Input_Error : exception;

   -- Packet structure (using access type for unconstrained array)
   type Packet is record
      Data : Buffer_Access;
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
      MSS           : in     Natural;
      Window_Size   : in     Natural;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- Minshall's Nagle: Send if last packet is full-sized
   procedure Minshall_Nagle (
      MSS           : in     Natural;
      Window_Size   : in     Natural;
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
      MSS    : Natural
   ) return Boolean;

   -- Helper: Merge small packets into a single MSS-sized packet
   function Merge_Packets (
      Buffer : Packet_Vectors.Vector;
      MSS    : Natural
   ) return Packet;

   -- Helper: Simulate Delayed ACK interaction
   procedure Simulate_Delayed_ACK (
      Unacked       : in out Unacknowledged_Flag;
      Time_Elapsed  : in     Natural;  -- Simulated time in ms
      ACK_Timeout   : in     Natural := 500  -- Default Delayed ACK timeout
   );

   -- Helper: Free memory for a Packet
   procedure Free_Packet (Pkg : in out Packet);

end Nagle;
