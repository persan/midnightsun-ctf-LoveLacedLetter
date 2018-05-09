with System.Storage_Elements;
with Hide.BMP;
procedure Hide.Main is

   use type Posix.C_String;

   subtype Storage_Offset is System.Storage_Elements.Storage_Offset;


   File_Name : Posix.C_String := +"data/C0000775.bmp";
   File : Posix.File;
   File_Status : Posix.File_Status;

   Mmap : Posix.Memory_Map;

begin

   File.Open (File_Name, Posix.O_RDONLY, Posix.S_IRUSR);
   if File.Is_Closed then
      Put_Line ("Failed to open file: " & (-File_Name));
      return;
   end if;

   File.Get_File_Status (File_Status);
   if not File_Status.Is_Valid then
      Put_Line ("Failed to read file status: " & (-File_Name));
      return;
   end if;

   Put_Line (File_Status.Size'Image);

   File.Map_Memory (Address    => Posix.Nil,
                    Len        => Posix.unsigned_long (File_Status.Size),
                    Prot       => Posix.PROT_READ,
                    Flags      => Posix.MAP_SHARED,
                    Offset     => 0,
                    Memory_Map => MMap);

   if not Mmap.Has_Mapping then
      Put_Line ("Failed to map memory");
      File.Close;
      return;
   end if;

   declare
      Info : BMP.Header with
        Import  => True,
        Address => MMap.Mapping;
   begin
      if
      not (Info.Signature_1 = Character'Pos ('B') and
             Info.Signature_2 = Character'Pos ('M'))
      then
         Put_Line ("Expected signature is 'BM'");
         File.Close;
         return;
      end if;

      if Info.Size /= Integer_32 (File_Status.Size) then
         Put_Line ("Expected file size is" & File_Status.Size'Image);
         Put_Line ("Was specified in file" & Info.Size'Image);
         File.Close;
         return;
      end if;

      if Info.Offset /= 138 then
         Put_Line ("Offset is expected to be 138 but was" & Info.Offset'Image);
         File.Close;
         return;
      end if;

--        declare
--           S : constant String := Posix.Get_Line;
--        begin
--           Put_Line (S'Length'Image);
--        end;
   end;

   declare
      Info : BMP.Info with
        Import  => True,
        Address => MMap.Mapping;
   begin
      Put_Line("Struct_Size " & Info.Struct_Size'Img);
      Put_Line("Width " & Info.Width'Img);
      Put_Line("Height " & Info.Height'Img);
      Put_Line("Planes " & Info.Planes'Img);
      Put_Line("Pixel_Size " & Info.Pixel_Size'Img);
      Put_Line("Compression " & Info.Compression'Img);
      Put_Line("Image_Size " & Info.Image_Size'Img);
      Put_Line("PPMX " & Info.PPMX'Img);
      Put_Line("PPMY " & Info.PPMY'Img);
      Put_Line("Palette_Size " & Info.Palette_Size'Img);
      Put_Line("Important " & Info.Important'Img);
      Put_Line("");

      if Info.Compression /= 3 then
         Put_Line ("Expected compression 3 was" & Info.Compression'Image);
--           File.Close;
--           return;
      end if;

      declare
         Src_Bytes : Posix.Byte_Array (1..Storage_Offset (File_Status.Size)) with
           Import  => True,
           Address => MMap.Mapping;
         Bytes     : Posix.Byte_Array := Src_Bytes; -- To get a read/write copy.
         Pixels : BMP.Image_ARGB32 (1..Integer (Info.Width*Info.Height)) with
           Import  => True,
           Address => Bytes (138)'Address;

         Output_File : Posix.File;
         Output_File_Name : constant Posix.C_String := +"e.bmp";
         use type Posix.O_FLag;
      begin
         Output_File.Open (Output_File_Name, Posix.O_CREAT or Posix.O_WRONLY, Posix.S_IRUSR);
         if not Output_File.Is_Open then
            Put_Line ("Failed to open e.bmp for writing");
            return;
         end if;

         BMP.Encode (Info,Pixels, 10, "test");

         Output_File.Write (Bytes);

         Output_File.Close;
      end;
   end;

   declare
      I : Integer;
   begin
      I := MMap.Unmap_Memory;
      if I /= 0 then
         Put_Line ("Failed to unmap memory");
      end if;
   end;

   File.Close;
end Hide.Main;
