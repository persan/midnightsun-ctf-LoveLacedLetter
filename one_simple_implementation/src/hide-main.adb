with System.Storage_Elements;

procedure Hide.Main is

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

   end BMP;

   type Bit_Array is array (Integer range 1..8) of Boolean with
     Pack => True;

   procedure Query_User_For_BMP_File_Name;
   procedure Open_File (File_Name : Px.C_String);
   procedure Get_File_Size;
   procedure Map_BMP_File_Into_Memory;
   procedure Validate_BMP_File_Header;
   procedure Validate_BMP_File_Info;
   procedure View_BMP_File_Contents_As_Byte_Array;
   procedure Count_Max_Message_Size (Bytes : in out Px.Byte_Array);
   procedure Save_New_BMP_File (Secret : in     String;
                                Bytes  : in out Px.Byte_Array);

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
   begin
      Count_Max_Message_Size (Bytes);
   end View_BMP_File_Contents_As_Byte_Array;

   procedure Count_Max_Message_Size (Bytes : in out Px.Byte_Array) is
      Count : Natural := 0;

      procedure Calculate_Max_Characters is
         Max_Characters : constant Natural := Count / 8 - 1;

         procedure Enter_Secret_Message is
            Secret : constant String := Px.Get_Line;
         begin
            if Secret'Length <= Max_Characters then
               Save_New_BMP_File (Secret, Bytes);
            else
               Put_Line ("Error, secret message too long!");
            end if;
         end Enter_Secret_Message;
      begin
         Put_Line ("Maximum secret message length:" & Max_Characters'Image);
         Put ("Enter secret message: ");
         Enter_Secret_Message;
      end Calculate_Max_Characters;

   begin
      for I in Storage_Offset range 139..Bytes'Last - 1 loop
         declare
            Left_Byte  : Px.Byte := Bytes (I - 1);
            Right_Byte : Px.Byte := Bytes (I + 1);

            Left_Bits : Bit_Array with
              Import  => True,
              Address => Left_Byte'Address;

            Right_Bits : Bit_Array with
              Import  => True,
              Address => Right_Byte'Address;
         begin
            Left_Bits (8)  := False;
            Right_Bits (8) := False;

            if Left_Byte /= Right_Byte then
               Count := Count + 1;
            end if;
         end;
      end loop;

      if Count >= 16 then
         Calculate_Max_Characters;
      else
         Put_Line ("Not enough space in BMP to hide message");
      end if;
   end Count_Max_Message_Size;

   procedure Save_New_BMP_File
     (
      Secret : in     String;
      Bytes  : in out Px.Byte_Array
     )
   is
      Length : constant Integer := Secret'Length;

      I : Storage_Offset := 139;

      Buffer : Px.Byte_Array (1..10_000);

      Current_Buffer_Index : Storage_Offset := 0;

      Output_File : Px.File;

      procedure Flush_Buffer is
      begin
         if Current_Buffer_Index > 0 then
            Output_File.Write (Buffer (1..Current_Buffer_Index));
            Current_Buffer_Index := 0;
         end if;
      end Flush_Buffer;

      procedure Write_Byte_To_Buffer (Byte : Px.Byte) is
      begin
         if Current_Buffer_Index >= Buffer'Length then
            Output_File.Write (Buffer (1..Current_Buffer_Index));
            Current_Buffer_Index := 0;
         end if;

         Current_Buffer_Index := Current_Buffer_Index + 1;
         Buffer (Current_Buffer_Index) := Byte;
      end Write_Byte_To_Buffer;

      procedure Write_Length;
      procedure Write_Message;
      procedure Write_The_Rest_Of_The_Image;

      procedure Write_Length is
         Length_Bits : constant Bit_Array with
           Import  => True,
           Address => Length'Address;

         Bit_Index : Integer := 1;
      begin
         while I <= Bytes'Last - 1 loop
            declare
               Left_Byte  : Px.Byte := Bytes (I - 1);
               Right_Byte : Px.Byte := Bytes (I + 1);

               Left_Bits : Bit_Array with
                 Import  => True,
                 Address => Left_Byte'Address;

               Right_Bits : Bit_Array with
                 Import  => True,
                 Address => Right_Byte'Address;
            begin
               Left_Bits (8)  := False;
               Right_Bits (8) := False;

               if Left_Byte /= Right_Byte then
                  declare
                     Temp      : Px.Byte := Bytes (I);
                     Temp_Bits : Bit_Array with
                       Import  => True,
                       Address => Temp'Address;
                  begin
                     Temp_Bits (8) := Length_Bits (Bit_Index);

--                     Put_Line ("Index" & I'Image & ", bit" & Temp_Bits (8)'Image);

                     Write_Byte_To_Buffer (Temp);

                     Bit_Index := Bit_Index + 1;
                  end;
               else
                  Write_Byte_To_Buffer (Bytes (I));
               end if;

               I := I + 1;
               exit when Bit_Index > 8;
            end;
         end loop;
         Write_Message;
      end Write_Length;

      procedure Write_Message is
         Current_Character_Index : Integer := Secret'First;
         Bit_Index : Integer := 1;
      begin
         while I <= Bytes'Last - 1 loop
            declare
               Left_Byte  : Px.Byte := Bytes (I - 1);
               Right_Byte : Px.Byte := Bytes (I + 1);

               Left_Bits : Bit_Array with
                 Import  => True,
                 Address => Left_Byte'Address;

               Right_Bits : Bit_Array with
                 Import  => True,
                 Address => Right_Byte'Address;
            begin
               Left_Bits (8)  := False;
               Right_Bits (8) := False;

               if Left_Byte /= Right_Byte then
                  declare
                     Temp      : Px.Byte := Bytes (I);
                     Temp_Bits : Bit_Array with
                       Import  => True,
                       Address => Temp'Address;

                     Current_Character_Bits : Bit_Array with
                       Import  => True,
                       Address => Secret (Current_Character_Index)'Address;
                  begin
                     Temp_Bits (8) := Current_Character_Bits (Bit_Index);

                     Write_Byte_To_Buffer (Temp);

                     Bit_Index := Bit_Index + 1;
                     if Bit_Index > 8 then
                        Bit_Index := 1;
                        Current_Character_Index := Current_Character_Index + 1;
                     end if;
                  end;
               else
                  Write_Byte_To_Buffer (Bytes (I));
               end if;

               I := I + 1;
               exit when Current_Character_Index > Secret'Last;
            end;
         end loop;
         Write_The_Rest_Of_The_Image;
      end Write_Message;

      Ada_Output_File_Name : String := "e.bmp";

      procedure Write_The_Rest_Of_The_Image is
      begin
         while I <= Bytes'Last - 1 loop
            Write_Byte_To_Buffer (Bytes (I));
            I := I + 1;
         end loop;
         Write_Byte_To_Buffer (Bytes (Bytes'Last));
         Flush_Buffer;
         Output_File.Close;
         Put_Line ("Successfully created " & Ada_Output_File_Name);
      end Write_The_Rest_Of_The_Image;

      Output_File_Name : constant Px.C_String := +Ada_Output_File_Name;
   begin
      Output_File.Open (Output_File_Name,
                        Px.O_WRONLY or Px.O_TRUNC or Px.O_CREAT,
                        Px.S_IRUSR or Px.S_IWUSR or Px.S_IROTH);
      if not Output_File.Is_Open then
         Put_Line ("Failed to open e.bmp for writing");
         return;
      end if;

      Output_File.Write (Bytes (1..138));

      Write_Length;
   end Save_New_BMP_File;

begin
   Query_User_For_BMP_File_Name;
end Hide.Main;
