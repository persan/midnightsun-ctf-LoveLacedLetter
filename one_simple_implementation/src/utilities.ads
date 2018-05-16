with Posix;
with System.Storage_Elements;

package Utilities is

   package Px renames Posix;

   subtype Storage_Offset is System.Storage_Elements.Storage_Offset;

   type Bit_Array is array (Integer range 1..8) of Boolean with
     Pack => True;

   function Shall_Adjust_Byte (Bytes : Px.Byte_Array;
                               Index : Storage_Offset) return Boolean;

end Utilities;
