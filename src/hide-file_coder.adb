with System.Storage_Elements;
with Hide.BMP;
package body Hide.file_coder is

   use type Posix.C_String;
   procedure Encode (Source_File_Name : Posix.C_String;
                     Output_File_Name : Posix.C_String;
                     Offset           : Natural;
                     Text             : String) is



      File        : Posix.File;
      File_Status : Posix.File_Status;

      Mmap : Posix.Memory_Map;

   begin

      File.Open (Source_File_Name, Posix.O_RDONLY, Posix.S_IRUSR);
      if File.Is_Closed then
         Put_Line ("Failed to open file: " & (-Source_File_Name));
         return;
      end if;

      File.Get_File_Status (File_Status);
      if not File_Status.Is_Valid then
         Put_Line ("Failed to read file status: " & (-Source_File_Name));
         return;
      end if;


      File.Map_Memory (Address    => Posix.Nil,
                       Len        => Posix.Unsigned_Long (File_Status.Size),
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

      end;

      declare
         Info : BMP.Info with
           Import  => True,
           Address => MMap.Mapping;
      begin


         if Info.Compression /= 0 then
            Put_Line ("Expected compression 0 was" & Info.Compression'Image);
            File.Close;
            return;
         end if;

         declare
            Src_Bytes : Posix.Byte_Array (1 .. System.Storage_Elements.Storage_Offset (File_Status.Size)) with
              Import  => True,
              Address => MMap.Mapping;
            Bytes     : Posix.Byte_Array := Src_Bytes; -- To get a read/write copy.
            Pixels    : BMP.Image_ARGB32 (1 .. Integer (Info.Width * Info.Height)) with
              Import  => True,
              Address => Bytes (138)'Address;

            Output_File      : Posix.File;
            use type Posix.O_FLag;
         begin
            Output_File.Open (Output_File_Name, Posix.O_CREAT or Posix.O_WRONLY, Posix.S_IRUSR);
            if not Output_File.Is_Open then
               Put_Line ("Failed to open " & (-Output_File_Name) & " for writing");
               return;
            end if;

            BMP.Encode (Info, Pixels, offset, Text);

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
   end;
   function Decode (File_Name : Posix.C_String) return String is

      File        : Posix.File;
      File_Status : Posix.File_Status;

      Mmap : Posix.Memory_Map;

   begin

      File.Open (File_Name, Posix.O_RDONLY, Posix.S_IRUSR);
      if File.Is_Closed then
         Put_Line ("Failed to open file: " & (-File_Name));
         return "";
      end if;

      File.Get_File_Status (File_Status);
      if not File_Status.Is_Valid then
         Put_Line ("Failed to read file status: " & (-File_Name));
         return "";
      end if;

      File.Map_Memory (Address    => Posix.Nil,
                       Len        => Posix.Unsigned_Long (File_Status.Size),
                       Prot       => Posix.PROT_READ,
                       Flags      => Posix.MAP_SHARED,
                       Offset     => 0,
                       Memory_Map => MMap);

      if not Mmap.Has_Mapping then
         Put_Line ("Failed to map memory");
         File.Close;
         return "";
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
         return "";
         end if;

         if Info.Size /= Integer_32 (File_Status.Size) then
            Put_Line ("Expected file size is" & File_Status.Size'Image);
            Put_Line ("Was specified in file" & Info.Size'Image);
            File.Close;
         return "";
         end if;

         if Info.Offset /= 138 then
            Put_Line ("Offset is expected to be 138 but was" & Info.Offset'Image);
            File.Close;
         return "";
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
--           Put_Line (Bmp.Image (Inf));

         if Info.Compression /= 0 then
            Put_Line ("Expected compression 0 was" & Info.Compression'Image);
            --           File.Close;
            --           return;
         end if;

         declare
            Src_Bytes : Posix.Byte_Array (1 .. System.Storage_Elements.Storage_Offset (File_Status.Size)) with
              Import  => True,
              Address => MMap.Mapping;
            Bytes     : Posix.Byte_Array := Src_Bytes; -- To get a read/write copy.
            Pixels    : BMP.Image_ARGB32 (1 .. Integer (Info.Width * Info.Height)) with
              Import  => True,
              Address => Bytes (138)'Address;

         begin
            return Ret : constant String := BMP.Decode (Info, Pixels) do
               declare
                  I : Integer;
               begin
                  I := MMap.Unmap_Memory;
                  if I /= 0 then
                     Put_Line ("Failed to unmap memory");
                  end if;
               end;

               File.Close;

            end return;
         end;

      end;
   end;
end hide.file_coder;
