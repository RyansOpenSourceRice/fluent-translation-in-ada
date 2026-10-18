--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0

package body Fluent.Bundle
  with SPARK_Mode => On
is

   function Empty_Bundle (Tag : Fluent.Locale.Locale_Tag) return Bundle
   is
      Result : Bundle;
   begin
      Result.Tag := Tag;
      Result.Count := 0;
      for I in Result.Slots'Range loop
         Result.Slots (I).Present := False;
         Result.Slots (I).Id_Len := 0;
         Result.Slots (I).Value_Len := 0;
      end loop;
      return Result;
   end Empty_Bundle;

   function Resolve_Select
     (Selector      : Natural;
      Keys          : Fluent.Syntax.Entry_Array;
      Has_Default   : Boolean;
      Default_Index : Natural) return Natural
   is
   begin
      --  M0 contract holder: default wins when present, else no selection.
      --  M2 implements first-key-match then default then "{select}".
      --  Selector/Keys are part of the M2 contract; M0 only honors default.
      if Has_Default then
         return Default_Index;
      elsif Selector = Keys'Length and Keys'Length = Natural'Last then
         return 0;
      else
         return 0;
      end if;
   end Resolve_Select;

end Fluent.Bundle;
