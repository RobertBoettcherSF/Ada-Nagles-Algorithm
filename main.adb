-- main.adb
-- Demo for Nagle's Algorithm

with Ada.Text_IO; use Ada.Text_IO;
with Nagle; use Nagle;

procedure Main is
   MSS : constant MSS_Type := 1460;
   Window_Size : constant Window_Size_Type := 2920;
   Unacked : Unacknowledged_Flag := No_Unacked;
   Buffer : Packet_Vectors.Vector;
   Send_Now : Boolean;
   Packet_To_Send : Packet;
   Data : Buffer_Type := (1 .. 10 => 0);  -- 10 bytes
begin
   Put_Line("=== Nagle's Algorithm Demo ===");
   New_Line;

   -- Original Nagle
   Put_Line("Original Nagle:");
   Nagle.Original_Nagle(MSS, Window_Size, Unacked, Data, Buffer, Send_Now, Packet_To_Send);
   Put_Line("  Send_Now: " & Boolean'Image(Send_Now));
   Put_Line("  Packet Size: " & Integer'Image(Packet_To_Send.Size));
   New_Line;

   -- Minshall Nagle
   Put_Line("Minshall Nagle:");
   Buffer.Clear;
   Unacked := Has_Unacked;
   Buffer.Append((Data => Data, Size => 10));
   Nagle.Minshall_Nagle(MSS, Window_Size, Unacked, Data, Buffer, Send_Now, Packet_To_Send);
   Put_Line("  Send_Now: " & Boolean'Image(Send_Now));
   Put_Line("  Packet Size: " & Integer'Image(Packet_To_Send.Size));
   New_Line;

   -- No Nagle
   Put_Line("No Nagle (TCP_NODELAY):");
   Nagle.No_Nagle(Data, Send_Now, Packet_To_Send);
   Put_Line("  Send_Now: " & Boolean'Image(Send_Now));
   Put_Line("  Packet Size: " & Integer'Image(Packet_To_Send.Size));
end Main;
