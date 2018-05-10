
package Hide.BMP is

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

   function Image ( Item : Info ) return String ;

   type Pixel_G8 is new Integer_8; -- 8 bit pixel grayscale
   type Image_G8 is array (Integer range <>) of Pixel_G8;

   type Byte_As_Bit_Array is array (1 .. 8) of Boolean with
     Pack => True;

   type Chanels is (Alpha, Red, Gren, Blue);
   type Pixel_ARGB32 is array (Chanels) of Byte_As_Bit_Array with Pack => True;
   type Image_ARGB32 is array (Integer range <>) of Pixel_ARGB32;

   procedure Encode (Image_Info : Info;
      Image      : in out Image_ARGB32;
      Offset     : Natural;
                     Text       : in String);
   function Decode (Image_Info : Info;
                    Image      : in Image_ARGB32) return String;

end Hide.BMP;
