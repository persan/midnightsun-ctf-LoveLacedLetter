package body Posix is


   procedure Open
     (File      : in out Posix.File;
      File_Name : in     C_String;
      Flags     : in     O_FLag;
      S_Flags   : in     S_FLag)
   is
   begin
      File.My_File_Descriptor := Px_Thin.Open (File_Name, Flags, S_Flags);
      File.My_Is_Open         := File.My_File_Descriptor /= 0;
   end Open;

   procedure Close (File : in out Posix.File) is
   begin
      Px_Thin.Close (File.My_File_Descriptor);
      File.My_Is_Open := False;
   end Close;

   procedure Get_File_Status
     (File   : in     Posix.File;
      Status : in out File_Status)
   is
      Result : constant Integer :=
        Px_Thin.Get_File_Status
          (Fd     => File.My_File_Descriptor,
           Status => Status.My_Status'Access);
   begin
      Status.My_Is_Valid := Result = 0;
   end Get_File_Status;

   procedure Write (File : Posix.File; Bytes : Byte_Array) is
      SSize : SSize_Type with Unreferenced;
   begin
      SSize :=
        Px_Thin.Write
          (File_Descriptor => File.My_File_Descriptor,
           Buffer          => Bytes,
           Count           => Bytes'Length);
   end Write;

   function Read (File : Posix.File; Bytes : in out Byte_Array) return SSize_Type is
   begin
      return Px_Thin.Read (File.My_File_Descriptor, Bytes, Bytes'Length);
   end Read;

   procedure Map_Memory
     (File    : in Posix.File;
      Address : Void_Ptr;
      Len     : Size_Type;
      Prot    : Prot_FLag;
      Flags   : int;
      Offset  : Posix.Offset;
      Memory_Map : in out Posix.Memory_Map) is
   begin
      Memory_Map.My_Mapping := Px_Thin.Mmap (Address,
                                             Len,
                                             Prot,
                                             Flags,
                                             File.My_File_Descriptor,
                                             Offset);
      Memory_Map.My_Length := Len;
   end Map_Memory;

   function Unmap_Memory (Map : in out Posix.Memory_Map) return Integer is
      R : Integer;
   begin
      R := Px_Thin.Munmap (Map.My_Mapping, Map.My_Length);
      if R = 0 then
         Map.My_Mapping := MAP_FAILED;
      end if;
      return R;
   end Unmap_Memory;

   function Memory_Unmap (Address : Void_Ptr;
                          Length  : Size_Type) return Integer is
   begin
      return Px_Thin.Munmap (Address, Length);
   end Memory_Unmap;

   New_Line : constant String := (1 => Character'Val (10));

   procedure Put_Line (Text : String) is
      SSize : SSize_Type;
      pragma Unreferenced (SSize);
   begin
      SSize := Px_Thin.Write (File_Descriptor => Px_Thin.STDOUT_FILENO,
                              Buffer          => Text,
                              Count           => Text'Length);
      SSize := Px_Thin.Write (File_Descriptor => Px_Thin.STDOUT_FILENO,
                              Buffer          => New_Line,
                              Count           => 1);
   end Put_Line;

   procedure Put (Text : String) is
      SSize : SSize_Type;
      pragma Unreferenced (SSize);
   begin
      SSize := Px_Thin.Write (File_Descriptor => Px_Thin.STDOUT_FILENO,
                              Buffer          => Text,
                              Count           => Text'Length);
   end Put;

   Max_Line_Length : constant := 1000;

   function Get_Line return String is
      SSize : SSize_Type with Unreferenced;
      B     : Byte_Array (1 .. Max_Line_Length);
      Cursor : System.Storage_Elements.Storage_Offset := B 'First;
      use all type System.Storage_Elements.Storage_Offset;
   begin
      while True loop
         SSize := Px_Thin.Read (File_Descriptor => Px_Thin.STDIN_FILENO,
                                Buffer          => B (Cursor .. Cursor),
                                Count           => 1);
         exit when B (Cursor) in Character'Pos (ASCII.LF) | Character'Pos (ASCII.CR);
         Cursor := Cursor + 1;
      end loop;
      Cursor := Cursor - 1;
      return  S : String (1..Integer (Cursor)) do
         for I in Integer range 1..Integer (Cursor) loop
            S (I) := Character'Val (B (System.Storage_Elements.Storage_Offset (I)));
         end loop;
      end return;
   end Get_Line;

   function "-" (Text : C_String) return String is
   begin
      return String (Text (Text'First .. Text'Last - 1));
   end "-";

   function "+" (Text : String) return C_String is
   begin
      return C_String (Text & Nul);
   end "+";

end Posix;
