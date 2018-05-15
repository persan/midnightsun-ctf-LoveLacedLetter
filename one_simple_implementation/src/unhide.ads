with Posix;

package Unhide is

   package Px renames Posix;

   procedure Put_Line (Text : String) renames Px.Put_Line;

   procedure Put (Text : String) renames Px.Put;

   type Integer_8  is range -2 **  7 .. 2 **  7 - 1;
   for Integer_8'Size use  8;

   type Integer_16 is range -2 ** 15 .. 2 ** 15 - 1;
   for Integer_16'Size use 16;

   type Integer_32 is range -2 ** 31 .. 2 ** 31 - 1;
   for Integer_32'Size use 32;

--     subtype Integer_16 is Interfaces.Integer_16;
--     subtype Integer_32 is Interfaces.Integer_32;

end Unhide;
