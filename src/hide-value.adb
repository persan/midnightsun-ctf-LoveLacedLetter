function Hide.Value (Data : String ) return Integer is
   Map  : constant array (Character'('0') .. Character'('9')) of Integer := (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
begin
   return Ret : Integer := 0 do
      for Cursor in Data'Range loop
         Ret := Ret + Map (Data (Cursor));
         if Cursor /=  Data'Last then
            Ret := Ret * 10;
         end if;
      end loop;
   end return;
end;
