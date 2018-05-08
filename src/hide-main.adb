with System.Storage_Elements;
procedure Hide.Main is

   use type Px.C_String;

   subtype Storage_Offset is System.Storage_Elements.Storage_Offset;

   package BMP is

      type Header is record
         Signature_1 : Integer_8;
         Signature_2 : Integer_8;

         Size      : Integer_32;
         -- File size in bytes

         Reserved1 : Integer_16;
         Reserved2 : Integer_16;

         Offset    : Integer_32;
         -- Start address in bytes where the image data can be found.
      end record with
        Pack => True;

      type Info is record
         Header        : BMP.Header;
         Struct_Size   : Integer_32;
         Width         : Integer_32; -- Image width in pixels
         Height        : Integer_32; -- Image hieght in pixels
         Planes        : Integer_16;
         Pixel_Size    : Integer_16; -- Bits per pixel
         Compression   : Integer_32; -- Zero means no compression
         Image_Size    : Integer_32; -- Size of the image data in bytes
         PPMX          : Integer_32; -- Pixels per meter in x led
         PPMY          : Integer_32; -- Pixels per meter in y led
         Palette_Size  : Integer_32; -- Number of colors
         Important     : Integer_32;
      end record with
        Pack => True;

      type Pixel_G8 is new Integer_8; -- 8 bit pixel grayscale
      type Image_G8 is array (Integer range <>) of Pixel_G8;

      type Byte_As_Bit_Array is array (1..8) of Boolean with
        Pack => True;

      type Pixel_ARGB32 is record -- 32 bit pixel (alpha, red, green, blue)
         A, R, G, B : Byte_As_Bit_Array; -- 8 bit * 4 = 32 bit
      end record;
      type Image_ARGB32 is array (Integer range <>) of Pixel_ARGB32;

   end BMP;

   File_Name : Px.C_String := +"d.bmp";
   File : Px.File;
   File_Status : Px.File_Status;

   Mmap : Px.Memory_Map;

begin

   File.Open (File_Name, Px.O_RDONLY, Px.S_IRUSR);
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

   File.Map_Memory (Address    => Px.Nil,
                    Len        => Px.unsigned_long (File_Status.Size),
                    Prot       => Px.PROT_READ,
                    Flags      => Px.MAP_SHARED,
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

      declare
         S : constant String := Px.Get_Line;
      begin
         Put_Line (S'Length'Image);
      end;
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
         File.Close;
         return;
      end if;

      declare
         Bytes : Px.Byte_Array (1..Storage_Offset (File_Status.Size)) with
           Import  => True,
           Address => MMap.Mapping;

         Pixels : BMP.Image_ARGB32 (1..Integer (Info.Width*Info.Height)) with
           Import  => True,
           Address => Bytes (138)'Address;

         Output_File : Px.File;
         Output_File_Name : constant Px.C_String := +"e.bmp";
         use type Px.O_FLag;
      begin
         Output_File.Open (Output_File_Name, Px.O_CREAT or Px.O_WRONLY, Px.S_IRUSR);
         if not Output_File.Is_Open then
            Put_Line ("Failed to open e.bmp for writing");
            return;
         end if;

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
