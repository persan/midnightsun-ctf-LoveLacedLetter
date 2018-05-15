package Hide.File_Coder  is

   procedure Encode (Source_File_Name : Posix.C_String;
                     Output_File_Name : Posix.C_String;
                     Offset           : Natural;
                     Text             : String);

   function Decode (File_Name : Posix.C_String) return String;

end  Hide.File_Coder;
