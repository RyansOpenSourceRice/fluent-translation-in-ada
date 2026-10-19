--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Parse example: parse a small FTL document and list entry kinds,
--  identifiers, and line spans. Run from the repository root.

with Ada.Text_IO;
with Fluent.Syntax;

procedure Parse is
   use Ada.Text_IO;
   use Fluent.Syntax;

   Source : constant String :=
     "# Greeting" & ASCII.LF
     & "hello = Hello, { $name }!" & ASCII.LF
     & "-brand = Aurora" & ASCII.LF
     & "broken entry" & ASCII.LF;

   Entries : Entry_Array (1 .. 16);
   Count   : Natural := 0;
   Junks   : Natural := 0;

   function Image (K : Entry_Kind) return String is
   begin
      case K is
         when Message          => return "Message";
         when Term             => return "Term";
         when Comment          => return "Comment";
         when Group_Comment    => return "GroupComment";
         when Resource_Comment => return "ResourceComment";
         when Blank            => return "Blank";
         when Junk             => return "Junk";
      end case;
   end Image;
begin
   Parse_Resource (Source, Entries, Count, Junks);
   for I in 1 .. Count loop
      Put (Image (Entries (I).Kind));
      if Entries (I).Kind = Message or Entries (I).Kind = Term then
         Put (" ");
         for C in 1 .. Entries (I).Id_Len loop
            Put (Entries (I).Id (C));
         end loop;
      end if;
      Put_Line ("  lines" & Entries (I).Span.First_Line'Image
                & ".." & Entries (I).Span.Last_Line'Image);
   end loop;
   Put_Line ("junk entries:" & Junks'Image);
end Parse;
