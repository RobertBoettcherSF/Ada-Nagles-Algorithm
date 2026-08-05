-- nagle.adb
-- Implementation of Nagle's Algorithm and its variants.

with Ada.Containers.Vectors;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Nagle is
   -- Helper: Free memory for a Packet
   procedure Free_Packet (Pkg : in out Packet) is
      procedure Free is new Ada.Unchecked_Deallocation(Buffer_Type, Buffer_Access);
   begin
      if Pkg.Data /= null then
         Free(Pkg.Data);
         Pkg.Data := null;
      end if;
   end Free_Packet;

   -- Helper: Calculate total buffered data size
   function Total_Buffered_Size (Buffer : Packet_Vectors.Vector) return Natural is
      Total : Natural := 0;
   begin
      for Pkg of Buffer loop
         if Pkg.Data /= null then
            Total := Total + Pkg.Size;
         end if;
      end loop;
      return Total;
   end Total_Buffered_Size;

   -- Helper: Check if buffer has enough data for MSS
   function Has_Enough_Data (
      Buffer : Packet_Vectors.Vector;
      MSS    : MSS_Type
   ) return Boolean is
   begin
      return Total_Buffered_Size(Buffer) >= MSS;
   end Has_Enough_Data;

   -- Helper: Merge buffered packets into a single MSS-sized packet
   function Merge_Packets (
      Buffer : Packet_Vectors.Vector;
      MSS    : MSS_Type
   ) return Packet is
      Merged_Data : Buffer_Access := new Buffer_Type(1 .. MSS);
      Current_Index : Positive := 1;
      Remaining : Natural := MSS;
   begin
      for Pkg of Buffer loop
         if Pkg.Data /= null and then Pkg.Size > 0 then
            if Pkg.Size <= Remaining then
               Merged_Data(Current_Index .. Current_Index + Pkg.Size - 1) := 
                  Pkg.Data(1 .. Pkg.Size);
               Current_Index := Current_Index + Pkg.Size;
               Remaining := Remaining - Pkg.Size;
            else
               -- Copy only the remaining needed bytes
               Merged_Data(Current_Index .. Current_Index + Remaining - 1) := 
                  Pkg.Data(1 .. Remaining);
               exit;
            end if;
         end if;
      end loop;
      return (Data => Merged_Data, Size => MSS - Remaining);
   end Merge_Packets;

   -- Original Nagle's Algorithm (RFC 896)
   procedure Original_Nagle (
      MSS           : in     MSS_Type;
      Window_Size   : in     Window_Size_Type;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   ) is
      New_Packet : Packet;
   begin
      -- If there is new data to send
      if New_Data'Length > 0 then
         -- If window size >= MSS and buffered data >= MSS, send now
         if Window_Size >= MSS and then Has_Enough_Data(Buffer, MSS) then
            Send_Now := True;
            Packet_To_Send := Merge_Packets(Buffer, MSS);
            Buffer.Clear;  -- Clear buffer after sending
         else
            -- If there is unacknowledged data, buffer the new data
            if Unacked = Has_Unacked then
               New_Packet.Data := new Buffer_Type(New_Data'Range);
               New_Packet.Data.all := New_Data;
               New_Packet.Size := New_Data'Length;
               Buffer.Append(New_Packet);
               Send_Now := False;
            else
               -- No unacked data: send immediately
               Send_Now := True;
               Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
               Packet_To_Send.Data.all := New_Data;
               Packet_To_Send.Size := New_Data'Length;
            end if;
         end if;
      else
         -- No new data: do not send
         Send_Now := False;
         Packet_To_Send := (Data => null, Size => 0);
      end if;
   exception
      when others =>
         raise Invalid_Input_Error with "Invalid input in Original_Nagle";
   end Original_Nagle;

   -- Minshall's Modification: Send if last packet is full-sized
   procedure Minshall_Nagle (
      MSS           : in     MSS_Type;
      Window_Size   : in     Window_Size_Type;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   ) is
      Last_Packet_Full : Boolean := False;
      New_Packet : Packet;
   begin
      -- Check if the last buffered packet is full-sized (MSS)
      if not Buffer.Is_Empty then
         declare
            Last_Pkg : Packet := Buffer.Last_Element;
         begin
            Last_Packet_Full := (Last_Pkg.Size = MSS);
         end;
      end if;

      -- If there is new data to send
      if New_Data'Length > 0 then
         -- If last packet is full-sized, send immediately
         if Last_Packet_Full then
            Send_Now := True;
            Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
            Packet_To_Send.Data.all := New_Data;
            Packet_To_Send.Size := New_Data'Length;
         -- Otherwise, follow Original Nagle logic
         elsif Window_Size >= MSS and then Has_Enough_Data(Buffer, MSS) then
            Send_Now := True;
            Packet_To_Send := Merge_Packets(Buffer, MSS);
            Buffer.Clear;
         elsif Unacked = Has_Unacked then
            New_Packet.Data := new Buffer_Type(New_Data'Range);
            New_Packet.Data.all := New_Data;
            New_Packet.Size := New_Data'Length;
            Buffer.Append(New_Packet);
            Send_Now := False;
         else
            Send_Now := True;
            Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
            Packet_To_Send.Data.all := New_Data;
            Packet_To_Send.Size := New_Data'Length;
         end if;
      else
         Send_Now := False;
         Packet_To_Send := (Data => null, Size => 0);
      end if;
   exception
      when others =>
         raise Invalid_Input_Error with "Invalid input in Minshall_Nagle";
   end Minshall_Nagle;

   -- No Nagle: Send immediately (TCP_NODELAY)
   procedure No_Nagle (
      New_Data      : in     Buffer_Type;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   ) is
   begin
      if New_Data'Length > 0 then
         Send_Now := True;
         Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
         Packet_To_Send.Data.all := New_Data;
         Packet_To_Send.Size := New_Data'Length;
      else
         Send_Now := False;
         Packet_To_Send := (Data => null, Size => 0);
      end if;
   end No_Nagle;

   -- Simulate Delayed ACK interaction
   procedure Simulate_Delayed_ACK (
      Unacked       : in out Unacknowledged_Flag;
      Time_Elapsed  : in     Natural;
      ACK_Timeout   : in     Natural := 500
   ) is
   begin
      if Unacked = Has_Unacked and then Time_Elapsed >= ACK_Timeout then
         Unacked := No_Unacked;  -- ACK received after timeout
      end if;
   end Simulate_Delayed_ACK;

end Nagle;
