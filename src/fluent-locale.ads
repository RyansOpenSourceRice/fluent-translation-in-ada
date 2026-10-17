--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Locale — locale-services interface (ECMA-402 surface, pure Ada).
--  No ICU4C/host FFI: plural categories and number/date formatting are
--  implemented against a vendored CLDR subset in later milestones.
--  M0 exposes the interface + English-only fallback so the resolver
--  never pretends ASCII formatting is full internationalization.

package Fluent.Locale
  with SPARK_Mode => On
is

   Max_Locale_Tag_Length : constant := 32;
   subtype Locale_Tag_Length is Natural range 0 .. Max_Locale_Tag_Length;
   type Locale_Tag_Text is array (1 .. Max_Locale_Tag_Length) of Character;

   type Locale_Tag is record
      Text : Locale_Tag_Text := [others => ' '];
      Len  : Locale_Tag_Length := 0;
   end record;

   function Make_Tag (Text : String) return Locale_Tag
     with Pre => Text'Length <= Max_Locale_Tag_Length
       and then Text'First <= Positive'Last - Max_Locale_Tag_Length;

   --  CLDR plural categories used by Fluent select expressions.
   type Plural_Category is (Zero, One, Two, Few, Many, Other);

   --  Minimal English-only plural rule (M0 fallback). Full CLDR tables
   --  land in M3 behind this same function contract.
   function Plural_Of (Tag : Locale_Tag; N : Long_Long_Integer)
     return Plural_Category;

   function Tags_Equal (A, B : Locale_Tag) return Boolean;

end Fluent.Locale;
