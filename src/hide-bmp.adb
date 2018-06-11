pragma Ada_2012;
with Hide.Value;
package body Hide.BMP is
   MAX_TEXT_LENGTH : constant := 1024;
   ------------
   -- Encode --
   ------------

   type Bit_Vector is array (Natural range <>) of Boolean with Pack => True;
   function Encode (Src : Pixel_ARGB32; As : Boolean ) return Pixel_ARGB32 with Inline_Always;

   Chanel          : Chanels := Chanels'First;
   Terminator      : constant Character := ASCII.Nul;

   procedure NEXT is
   begin
      Chanel := (case Chanel is
                    when Alpha => Red,
                    when Red  => Gren,
                    when Gren => Blue,
                    when Blue => Red);
   end NEXT;



   -- Store a boolean value in a Pixel.
   function Encode (Src : Pixel_ARGB32; As : Boolean ) return Pixel_ARGB32 is
   begin
      return Ret : Pixel_ARGB32 := Src do
         Ret (Chanel) (8) := As;
         pragma Debug (Posix.Put (if As then "1" else "0"));
         Next;
      end return;
   end;

   -- Store an ASCII string in the image and termiat the string
   -- with the Terminator character
   procedure Encode
     (Image      : in out Image_ARGB32;
      Text       : in String)
   is
      type mod8 is mod 8;
      Src         : constant String := Text & Terminator;
      Source_Bits : Bit_Vector (1 .. Src'Length * Character'Size) with
        Import => True,
        Address => Src'Address;
      Cursor      : Natural :=  Image'First;
      M           : mod8 := 0;
   begin
      if Image'Length < Source_Bits'Length then
         Put_Line ("Fail");
         raise Constraint_Error;
      end if;
      for Bit of Source_Bits loop
         Image (Cursor) := Encode (Image (Cursor), Bit);
         Cursor := Cursor + 1;
         M := M + 1;
         if M = 0 then
            pragma Debug (Put_Line (""));
         end if;
      end loop;
   end Encode;

   -- Stores an integer as an ASCII string in the Image.
   procedure Encode
     (Image      : in out Image_ARGB32;
      Data       : in Integer)
   is
      S : constant String := Data'Img;
   begin
      Encode (Image, S (S'First + 1 .. S'Last));
   end Encode;


   procedure Encode
     (Image_Info : Info;
      Image      : in out Image_ARGB32;
      Offset     : Natural;
      Text       : in String)
   is
      pragma Unreferenced (Image_Info);
   begin
      pragma Debug (Posix.Put_Line ("Encode"));
      -- Reset The chanel
      Chanel := Chanels'First;
      -- Store the index to the string in the beginning of the image.
      Encode (Image, Offset);
      -- Finally store the string at index.
      Encode (Image (Offset .. Image'Last), Text);
   end Encode;

   ------------
   -- Decode --
   ------------

   --  =========================================================================
   --  Read the boolean value stored in the pixel
   --  And step to next channel.
   function Decode
     (Image      : in Pixel_ARGB32) return Boolean is
   begin
      return Ret : constant Boolean := Image (Chanel) (8) do
         pragma Debug (Posix.Put (if Ret then "1" else "0"));
         Next;
      end return;
   end;

   --  =========================================================================
   --  Read the null terminated string stored in the begining of the pixel-vector
   --
   function Decode
     (Image      : in Image_ARGB32)
      return String is
      Output_Buffer : String (1 .. MAX_TEXT_LENGTH);

      Output_Cursor : Natural := Output_Buffer'First;
      Input_Cursor : Natural := Image'First;

      type Character_Bit_Vector (Part : Boolean := False) is record
         case Part is
            when True => As_Character   : Character;
            when False => As_Bit_Vector : Bit_Vector (1 .. Character'Size);
         end case;
      end record with
        Unchecked_Union => True;

      Input         : Character_Bit_Vector;
   begin
      pragma Debug (Posix.Put_Line ("Decode"));
      loop
         -- Read 8 consecutive bits to form one byte
         -- and exit when the String termination charrater is found.
         for I in Input.As_Bit_Vector'Range loop
            Input.As_Bit_Vector (I) := Decode (Image (Input_Cursor));
            Input_Cursor := Input_Cursor + 1;
         end loop;
         exit when Input.As_Character = Terminator;
         pragma Debug (Posix.Put_Line (""));


         Output_Buffer (Output_Cursor) := Input.As_Character;
         Output_Cursor := Output_Cursor + 1;
      end loop;

      Output_Cursor := Output_Cursor - 1;
      pragma Debug (Posix.Put_Line(""));
      pragma Debug (Posix.Put_Line (Output_Buffer (Output_Buffer'First .. Output_Cursor)));
      return Output_Buffer (Output_Buffer'First .. Output_Cursor);
   end;


   function Decode
     (Image      : in Image_ARGB32)
      return Natural is
   begin
      return value(Decode (Image));
   end;


   --  ========================================================================
   -- Read a string stored in the Pixel-array by first
   -- reading a string contanit the offset to the real data
   -- and then return the real data.
   function Decode
     (Image_Info : Info;
      Image      : in Image_ARGB32)
      return String
   is
      pragma Unreferenced (Image_Info);
   begin
      -- Reset the channel.
      Chanel := Chanels'First;
      -- get the index to where the actual string is stored and then
      -- Return the string.
      return Decode (Image (Decode (Image) .. Image'Last));
   end Decode;


   -- Convinient image function.
   function Image ( Item : Info ) return String is
   begin
      return
        "Struct_Size  => " & Item.Struct_Size'Img & ASCII.LF & "," &
        "Width        => " & Item.Width'Img & ASCII.LF & "," &
        "Height       => " & Item.Height'Img & ASCII.LF & "," &
        "Planes       => " & Item.Planes'Img & ASCII.LF & "," &
        "Pixel_Size   => " & Item.Pixel_Size'Img & ASCII.LF & "," &
        "Compression  => " & Item.Compression'Img & ASCII.LF & "," &
        "Image_Size   => " & Item.Image_Size'Img & ASCII.LF & "," &
        "PPMX         => " & Item.PPMX'Img & ASCII.LF & "," &
        "PPMY         => " & Item.PPMY'Img & ASCII.LF & "," &
        "Palette_Size => " & Item.Palette_Size'Img & ASCII.LF & "," &
        "Important    => " & Item.Important'Img;
   end;
end Hide.BMP;
