pragma Ada_2012;
package body Hide.BMP is
   MAX_TEXT_LENGTH : constant := 1024;
   ------------
   -- Encode --
   ------------
   type Bit_Vector is array (Natural range <>) of Boolean with Pack => True;
   function Encode (Src : Pixel_ARGB32; As : Boolean ) return Pixel_ARGB32 with Inline_Always;

   Chanel          : Chanels := Chanels'First;

   procedure NEXT is
   begin
      Chanel := (case Chanel is
                    when Alpha => Red,
                    when Red  => Gren,
                    when Gren => Blue,
                    when Blue => Red);
   end NEXT;


   function Encode (Src : Pixel_ARGB32; As : Boolean ) return Pixel_ARGB32 is
   begin

      return Ret : Pixel_ARGB32 := Src do
         Ret (Chanel) (8) := As;
         Next;
      end return;
   end;

   procedure Encode
     (Image      : in out Image_ARGB32;
      Text       : in String)
   is
      Source_Bits : Bit_Vector (1 .. Text'Length * Character'Size) with
        Import => True,
        Address => Text'Address;
      Cursor      : Natural :=  Image'First;
   begin
      if Image'Length < Source_Bits'Length then
         Put_Line ("Fail");
         raise Constraint_Error;
      end if;
      for Bit of Source_Bits loop
         Image (Cursor) := Encode (Image (Cursor), Bit);
      end loop;
   end Encode;


   procedure Encode
     (Image_Info : Info;
      Image      : in out Image_ARGB32;
      Offset     : Natural;
      Text       : in String)
   is
      Offset_Image : String  := Offset'Img;
   begin
      Chanel := Chanels'First;
      Encode (Image, Offset_Image);
      Encode (Image (Offset .. Image'Last), Offset_Image);
   end Encode;

   ------------
   -- Decode --
   ------------

   function Decode
     (Image_Info : Info;
      Image      : in Image_ARGB32)
      return String
   is
      Target_Bits : Bit_Vector (1 .. MAX_TEXT_LENGTH * Character'Size) := (others => False);
      Target_String : String (1 .. MAX_TEXT_LENGTH) with
        Address => Target_Bits'Address,
        Import => TRue;
   begin
      Chanel := Chanels'First;
      --  Generated stub: replace with real body!
      pragma Compile_Time_Warning (Standard.True, "Decode unimplemented");
      return raise Program_Error with "Unimplemented function Decode";
   end Decode;

end Hide.BMP;
