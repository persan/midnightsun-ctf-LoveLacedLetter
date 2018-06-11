function Hide.Value (Data : String ) return Integer with
  Pre => (for all I in Data'Range => Data (I) in '0' .. '9');
