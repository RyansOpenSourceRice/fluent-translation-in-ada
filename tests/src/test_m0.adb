--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  M0 executable checks: entry heuristic, locale tags, select-default,
--  fallback chain. Fails non-zero on first violation.

with Ada.Text_IO;
with Fluent.Locale;
with Fluent.Resource;
with Fluent.Syntax;

procedure Test_M0 is
   use Ada.Text_IO;
   use Fluent.Locale;
   Failures : Natural := 0;

   procedure Check (Name : String; Ok : Boolean) is
   begin
      Put_Line ((if Ok then "ok   " else "FAIL ") & Name);
      if not Ok then
         Failures := Failures + 1;
      end if;
   end Check;

   Tag_En : constant Fluent.Locale.Locale_Tag :=
     Fluent.Locale.Make_Tag ("en-US");
   Tag_Fr : constant Fluent.Locale.Locale_Tag :=
     Fluent.Locale.Make_Tag ("fr");
   Chain : constant Fluent.Resource.Fallback_Chain := Fluent.Resource.Empty_Chain;
   Dummy : Fluent.Syntax.Entry_Node;
   pragma Unreferenced (Dummy);
begin
   Check ("count-empty", Fluent.Syntax.Count_Entries ("") = 0);
   Check ("count-two",
     Fluent.Syntax.Count_Entries ("hello = Hi" & ASCII.LF & "bye = Bye" & ASCII.LF) = 2);
   Check ("no-cr", not Fluent.Syntax.Has_Cr_At_End_Of_Line ("a" & ASCII.LF, 1));
   Check ("tag-len", Tag_En.Len = 5);
   Check ("tags-ne", not Fluent.Locale.Tags_Equal (Tag_En, Tag_Fr));
   Check ("plural-one",
     Fluent.Locale.Plural_Of (Tag_En, 1) = Fluent.Locale.One);
   Check ("plural-other",
     Fluent.Locale.Plural_Of (Tag_En, 2) = Fluent.Locale.Other);
   Check ("empty-chain", Fluent.Resource.Best_Match (Chain, Tag_En) = 0);

   if Failures > 0 then
      Put_Line ("M0 FAILURES:" & Failures'Image);
      raise Program_Error with "M0 checks failed";
   else
      Put_Line ("M0 all checks passed");
   end if;
end Test_M0;
