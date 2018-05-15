with Hide.File_Coder;

with Gnat.Exception_Traces;
with Gnat.Traceback.Symbolic;

procedure Hide.Main is
   use all type Posix.C_String;
begin
   Gnat.Exception_Traces.Trace_On (Gnat.Exception_Traces.Every_Raise);
   Gnat.Exception_Traces.Set_Trace_Decorator (Gnat.Traceback.Symbolic.Symbolic_Traceback'Access);
   File_Coder.Encode ((+"data/Gripen_Agressor_21082017__ISV1318.bmp"), (+"e.bmp"), 7125, "<SAAB IS HUNTING THE FLAG>");
   Put_Line (File_Coder.Decode ((+"e.bmp")));


 end Hide.Main;
