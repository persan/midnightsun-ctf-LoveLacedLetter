procedure Hide.Decode_generic is
   use all type Posix.C_String;
   Source_File :constant String:= Posix.Get_Line;
begin

   Put_Line (Decode ((+Source_File)));
end;
