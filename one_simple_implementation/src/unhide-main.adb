with System.Storage_Elements;
with Utilities;
procedure Unhide.Main is

   package U renames Utilities;

   subtype Storage_Offset is System.Storage_Elements.Storage_Offset;

   use type Storage_Offset;
   use type Px.C_String;
   use type Px.Byte;
   use type Px.O_FLag;
   use type Px.S_FLag;

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

--      type Pixel_G8 is new Integer_8; -- 8 bit pixel grayscale
--      type Image_G8 is array (Integer range <>) of Pixel_G8;

--        type Byte_As_Bit_Array is array (1..8) of Boolean with
--          Pack => True;

--        type Pixel_ARGB32 is record -- 32 bit pixel (alpha, red, green, blue)
--           A, R, G, B : Byte_As_Bit_Array; -- 8 bit * 4 = 32 bit
--        end record;
--      type Image_ARGB32 is array (Integer range <>) of Pixel_ARGB32;

   end BMP;

   procedure Query_User_For_BMP_File_Name;
   procedure Open_File (File_Name : Px.C_String);
   procedure Get_File_Size;
   procedure Map_BMP_File_Into_Memory;
   procedure Validate_BMP_File_Header;
   procedure Validate_BMP_File_Info;
   procedure View_BMP_File_Contents_As_Byte_Array;
   procedure Extract_Message (Bytes  : in out Px.Byte_Array);

   procedure Query_User_For_BMP_File_Name is

      procedure Get_File_Name is
         File_Name : constant String := Px.Get_Line;
      begin
         Open_File (+File_Name);
      end Get_File_Name;

   begin
      Put ("Enter BMP-file name:");
      Get_File_Name;
   end Query_User_For_BMP_File_Name;

   File : Px.File;

   procedure Open_File (File_Name : Px.C_String) is
   begin
      File.Open (File_Name, Px.O_RDONLY, Px.S_IRUSR);
      if File.Is_Open then
         Get_File_Size;
         File.Close;
      else
         Put_Line ("Failed to open file: " & (-File_Name));
      end if;
   end Open_File;

   pragma Unmodified (File);

   File_Status : Px.File_Status;
   -- Used to get file size

   procedure Get_File_Size is
   begin
      File.Get_File_Status (File_Status);
      if File_Status.Is_Valid then
         Map_BMP_File_Into_Memory;
      else
         Put_Line ("Failed to read file status");
      end if;
   end Get_File_Size;

   pragma Unmodified (File_Status);

   Mmap : Px.Memory_Map;

   procedure Map_BMP_File_Into_Memory is
      I : Integer;
   begin
      File.Map_Memory (Address    => Px.Nil,
                       Len        => Px.unsigned_long (File_Status.Size),
                       Prot       => Px.PROT_READ,
                       Flags      => Px.MAP_SHARED,
                       Offset     => 0,
                       Memory_Map => MMap);

      if Mmap.Has_Mapping then
         Validate_BMP_File_Header;

         I := MMap.Unmap_Memory;
         if I /= 0 then
            Put_Line ("Failed to unmap memory");
         end if;
      else
         Put_Line ("Failed to map memory");
      end if;
   end Map_BMP_File_Into_Memory;

   pragma Unmodified (Mmap);

   procedure Validate_BMP_File_Header is
      Info : BMP.Header with
        Import  => True,
        Address => MMap.Mapping;

      procedure Check_Signature;
      procedure Validate_File_Size;
      procedure Validate_Offset;

      procedure Check_Signature is
      begin
         if
           Info.Signature_1 = Character'Pos ('B') and
           Info.Signature_2 = Character'Pos ('M')
         then
            Validate_File_Size;
         else
            Put_Line ("Expected signature is 'BM'");
         end if;
      end Check_Signature;

      procedure Validate_File_Size is
      begin
         if Info.Size = Integer_32 (File_Status.Size) then
            Validate_Offset;
         else
            Put_Line ("Expected file size is" & File_Status.Size'Image);
            Put_Line ("Was specified in file" & Info.Size'Image);
         end if;
      end Validate_File_Size;

      procedure Validate_Offset is
      begin
         if Info.Offset = 138 then
            Validate_BMP_File_Info;
         else
            Put_Line ("Offset is expected to be 138 but was" & Info.Offset'Image);
         end if;
      end Validate_Offset;

   begin
      Check_Signature;
   end Validate_BMP_File_Header;

   procedure Validate_BMP_File_Info is
      Info : BMP.Info with
        Import  => True,
        Address => MMap.Mapping;

      procedure Validate_Compression is
      begin
         if Info.Compression = 3 then
            View_BMP_File_Contents_As_Byte_Array;
         else
            Put_Line ("Expected compression 3 was" & Info.Compression'Image);
         end if;
      end Validate_Compression;

   begin
--        Put_Line("Struct_Size " & Info.Struct_Size'Img);
--        Put_Line("Width " & Info.Width'Img);
--        Put_Line("Height " & Info.Height'Img);
--        Put_Line("Planes " & Info.Planes'Img);
--        Put_Line("Pixel_Size " & Info.Pixel_Size'Img);
--        Put_Line("Compression " & Info.Compression'Img);
--        Put_Line("Image_Size " & Info.Image_Size'Img);
--        Put_Line("PPMX " & Info.PPMX'Img);
--        Put_Line("PPMY " & Info.PPMY'Img);
--        Put_Line("Palette_Size " & Info.Palette_Size'Img);
--        Put_Line("Important " & Info.Important'Img);
--        Put_Line("");

      Validate_Compression;
   end Validate_BMP_File_Info;

   procedure View_BMP_File_Contents_As_Byte_Array is
      Bytes : Px.Byte_Array (1..Storage_Offset (File_Status.Size)) with
        Import  => True,
        Address => MMap.Mapping;

      --           Pixels : BMP.Image_ARGB32 (1..Integer (Info.Width*Info.Height)) with
      --             Import  => True,
      --             Address => Bytes (138)'Address;
   begin
      Extract_Message (Bytes);
   end View_BMP_File_Contents_As_Byte_Array;

   procedure Extract_Message
     (
      Bytes  : in out Px.Byte_Array
     )
   is
      Length : Integer := 0;

      I : Storage_Offset := 139;

      procedure Read_Length;
      procedure Read_Message;

      procedure Read_Length is
         Length_Bits : U.Bit_Array with
           Import  => True,
           Address => Length'Address;

         Bit_Index : Integer := 1;
      begin
         while I <= Bytes'Last - 1 loop
            if U.Shall_Adjust_Byte (Bytes, I) then
               declare
                  Temp      : Px.Byte_Array (1..1) := Bytes (I..I);
                  Temp_Bits : U.Bit_Array with
                    Import  => True,
                    Address => Temp (1)'Address;
               begin
                  Length_Bits (Bit_Index) := Temp_Bits (8);

                  Bit_Index := Bit_Index + 1;
               end;
            end if;

            I := I + 1;
            exit when Bit_Index > 8;
         end loop;
         Put_Line ("Secret message length:" & Length'Image);
         Read_Message;
      end Read_Length;

      procedure Read_Message is
         Secret : String (1..100) := (others => ' ');
         Current_Character_Index : Integer := Secret'First;
         Bit_Index : Integer := 1;
      begin
         while I <= Bytes'Last - 1 loop
            if U.Shall_Adjust_Byte (Bytes, I) then
               declare
                  Temp      : Px.Byte_Array (1..1) := Bytes (I..I);
                  Temp_Bits : U.Bit_Array with
                    Import  => True,
                    Address => Temp (1)'Address;

                  Current_Character_Bits : U.Bit_Array with
                    Import  => True,
                    Address => Secret (Current_Character_Index)'Address;
               begin
                  Current_Character_Bits (Bit_Index) := Temp_Bits (8);

                  Bit_Index := Bit_Index + 1;
                  if Bit_Index > 8 then
                     Put (Secret (Current_Character_Index..Current_Character_Index));
                     Bit_Index := 1;
                     Current_Character_Index := Current_Character_Index + 1;
                  end if;
               end;
            end if;

            I := I + 1;
            exit when Current_Character_Index > Length;
         end loop;
         Put_Line ("");
      end Read_Message;

   begin
      Read_Length;
   end Extract_Message;

begin
   Query_User_For_BMP_File_Name;
end Unhide.Main;
