--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0

with Ada.Text_IO;
with Fluent.Locale;
with Fluent.Syntax;

procedure Hello is
   Tag : constant Fluent.Locale.Locale_Tag :=
     Fluent.Locale.Make_Tag ("en-US");
   N : constant Natural :=
     Fluent.Syntax.Count_Entries ("hello = Hello, world!" & ASCII.LF);
begin
   Ada.Text_IO.Put_Line ("locales:" & Tag.Len'Image & " entries:" & N'Image);
end Hello;
