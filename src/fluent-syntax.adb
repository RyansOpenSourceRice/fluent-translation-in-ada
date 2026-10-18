--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0

package body Fluent.Syntax
  with SPARK_Mode => On
is

   function Has_Cr_At_End_Of_Line (Source : String; Pos : Natural) return Boolean
   is
   begin
      if Pos < Source'First or Pos > Source'Last then
         return False;
      end if;
      return Source (Pos) = ASCII.CR;
   end Has_Cr_At_End_Of_Line;

   function Count_Entries (Source : String) return Natural
   is
      Count   : Natural := 0;
      At_Col0 : Boolean := True;
   begin
      for I in Source'Range loop
         pragma Loop_Invariant (Count <= Max_Entries);
         if Source (I) = ASCII.LF then
            At_Col0 := True;
         elsif At_Col0
           and then Source (I) /= ' '
           and then Source (I) /= ASCII.HT
           and then Source (I) /= ASCII.CR
         then
            --  A non-indented, non-blank line starts a new entry candidate.
            if Count < Max_Entries then
               Count := Count + 1;
            end if;
            At_Col0 := False;
         elsif Source (I) /= ASCII.LF and Source (I) /= ASCII.CR then
            At_Col0 := False;
         end if;
      end loop;
      return Count;
   end Count_Entries;

end Fluent.Syntax;
