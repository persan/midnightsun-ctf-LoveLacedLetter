with Hide.Value;
procedure Hide.File_Coder.Encode_Main is
   use all type Posix.C_String;
--     Source_File : constant String := Posix.Get_Line;
   Offset      : constant Natural := Value (Posix.Get_Line);
   Text        : constant String := Posix.Get_Line;
--     Output_File : constant String := Posix.Get_Line;
--     Source_File : constant String := "data/Gripen_Agressor_21082017__ISV1318.bmp";
--     Offset      : constant Natural := 5482;
--     Text        : constant String := "<SAAB>";
--     Output_File : constant String := "Gripen_Agressor_21082017__ISV1318.bmp";

begin
--        File_Coder.Encode ((+"data/Gripen_Agressor_21082017__ISV1318.bmp"), (+"Gripen_Agressor_21082017__ISV1318.bmp"), 71425, "<SAAB IS HUN_TING THE FLAG>");
      File_Coder.Encode ((+"data/Gripen_Agressor_21082017__ISV1318.bmp"), (+"Gripen_Agressor_21082017__ISV1318.bmp"), offset, Text );

--     Posix.Put_Line("Source_File => " & Source_File);
--     Posix.Put_Line ("Text => " & Text);
--     Posix.Put_Line ("Output_File => " & Output_File);
--     Encode ((+Source_File), (+Output_File), Offset , Text);
end Hide.File_Coder.Encode_Main;
