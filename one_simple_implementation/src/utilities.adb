package body Utilities is

   use type Storage_Offset;
   use type Px.Byte;

   function Shall_Adjust_Byte
     (Bytes : Px.Byte_Array;
      Index : Storage_Offset)
      return Boolean
   is
      Left_Byte  : Px.Byte := Bytes (Index - 1);
      Right_Byte : Px.Byte := Bytes (Index + 1);

      Left_Bits : Bit_Array with
        Import  => True,
        Address => Left_Byte'Address;

      Right_Bits : Bit_Array with
        Import  => True,
        Address => Right_Byte'Address;
   begin
      Left_Bits (8)  := False;
      Right_Bits (8) := False;

      return Left_Byte /= Right_Byte and Bytes (Index) >= 2;
   end Shall_Adjust_Byte;

end Utilities;
