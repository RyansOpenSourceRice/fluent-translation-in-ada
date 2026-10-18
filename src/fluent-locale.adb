--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0

package body Fluent.Locale
  with SPARK_Mode => On
is

   function Make_Tag (Text : String) return Locale_Tag
   is
      Result : Locale_Tag;
      Len    : constant Natural := Natural'Min (Text'Length, Max_Locale_Tag_Length);
   begin
      Result.Len := Len;
      for K in 1 .. Len loop
         pragma Loop_Invariant (Len <= Max_Locale_Tag_Length);
         pragma Loop_Invariant (Result.Len = Len);
         pragma Loop_Invariant (Text'First <= Positive'Last - Max_Locale_Tag_Length);
         Result.Text (K) := Text (Text'First + (K - 1));
      end loop;
      return Result;
   end Make_Tag;

   function Tags_Equal (A, B : Locale_Tag) return Boolean
   is
   begin
      if A.Len /= B.Len then
         return False;
      end if;
      for I in 1 .. A.Len loop
         pragma Loop_Invariant (I <= A.Len);
         if A.Text (I) /= B.Text (I) then
            return False;
         end if;
      end loop;
      return True;
   end Tags_Equal;

   function Plural_Of (Tag : Locale_Tag; N : Long_Long_Integer)
     return Plural_Category
   is
      pragma Unreferenced (Tag);
   begin
      --  M0 English-only fallback: one vs other. Documented as incomplete
      --  in SPECIFICATION.md; M3 adds per-locale CLDR tables.
      if N = 1 or N = -1 then
         return One;
      else
         return Other;
      end if;
   end Plural_Of;

end Fluent.Locale;
