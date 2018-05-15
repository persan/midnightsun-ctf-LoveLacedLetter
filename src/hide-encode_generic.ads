with Posix;
generic
   with procedure Encode (Source_File_Name : Posix.C_String;
                          Output_File_Name : Posix.C_String;
                          Offset           : Natural;
                          Text             : String) is <>;

procedure Hide.Encode_Generic;
