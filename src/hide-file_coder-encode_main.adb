with Hide.Value;
procedure Hide.File_Coder.Encode_Main is
   use all type Posix.C_String;
   Source_File : constant String := Posix.Get_Line;
   Offset      : constant Natural := Value (Posix.Get_Line);
   Text        : constant String := Posix.Get_Line;
   Output_File : constant String := Posix.Get_Line;

begin


   Encode ((+Source_File), (+Output_File), Offset , Text);
end Hide.File_Coder.Encode_Main;
