--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  M1a fixture driver: parses every vendored upstream .ftl fixture and
--  checks entry-kind + identifier sequences against the generated
--  Fixture_Expectations table. Deferred (M1b) fixtures are skipped.
--  Fails non-zero on first mismatch.

with Ada.Streams.Stream_IO;
with Ada.Streams;
with Ada.Text_IO;
with Fixture_Expectations;
with Fluent.Syntax;

procedure Test_M1a is
   use Ada.Text_IO;
   use Fluent.Syntax;

   Failures : Natural := 0;
   Skipped  : Natural := 0;
   Passed   : Natural := 0;

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

   procedure Check_Fixture (I : Positive) is
      Name : constant String := Fixture_Expectations.Fixture_Name (I);
      Path : constant String := "tests/fixtures/" & Name & ".ftl";
      F    : Ada.Streams.Stream_IO.File_Type;
      File_Size : Natural;
   begin
      if not Fixture_Expectations.Fixture_Active (I) then
         Skipped := Skipped + 1;
         Put_Line ("skip " & Name & " ("
                   & Fixture_Expectations.Fixture_Reason (I) & ")");
         return;
      end if;
      Ada.Streams.Stream_IO.Open (F, Ada.Streams.Stream_IO.In_File, Path);
      File_Size := Natural (Ada.Streams.Stream_IO.Size (F));
      if File_Size > Max_Source_Length then
         Put_Line ("FAIL " & Name & ": fixture too large");
         Failures := Failures + 1;
         Ada.Streams.Stream_IO.Close (F);
         return;
      end if;
      declare
         Buf     : String (1 .. Natural'Max (File_Size, 1));
         Actual  : Natural := 0;
         Entries : Entry_Array (1 .. Max_Entries);
         Count   : Natural := 0;
         Junks   : Natural := 0;
         Want    : Natural;
      begin
         if File_Size > 0 then
            declare
               Data : Ada.Streams.Stream_Element_Array
                 (1 .. Ada.Streams.Stream_Element_Offset (File_Size));
               Last : Ada.Streams.Stream_Element_Offset;
            begin
               Ada.Streams.Stream_IO.Read (F, Data, Last);
               for K in 1 .. File_Size loop
                  Buf (K) :=
                    Character'Val (Data (Ada.Streams.Stream_Element_Offset (K)));
               end loop;
            end;
         end if;
         Ada.Streams.Stream_IO.Close (F);
         Parse_Resource (Buf (1 .. File_Size), Entries, Count, Junks);
         Want := Fixture_Expectations.Fixture_Length (I);
         if Count /= Want then
            Put_Line ("FAIL " & Name & ": entry count" & Count'Image
                      & " /= expected" & Want'Image);
            for K in 1 .. Count loop
               Put_Line ("  got" & K'Image & ": " & Image (Entries (K).Kind)
                         & " lines" & Entries (K).Span.First_Line'Image
                         & ".." & Entries (K).Span.Last_Line'Image);
            end loop;
            Failures := Failures + 1;
            return;
         end if;
         for K in 1 .. Count loop
            Actual := K;
            declare
               EK : constant Entry_Kind :=
                 Fixture_Expectations.Fixture_Kind (I, K);
               EI : constant String :=
                 Fixture_Expectations.Fixture_Id (I, K);
            begin
               if Entries (K).Kind /= EK then
                  Put_Line ("FAIL " & Name & ": entry" & K'Image
                            & " kind " & Image (Entries (K).Kind)
                            & " /= expected " & Image (EK));
                  Failures := Failures + 1;
                  return;
               end if;
               if (EK = Message or EK = Term) and then EI /= "" then
                  declare
                     L   : constant Natural := Entries (K).Id_Len;
                     Got : String (1 .. L);
                  begin
                     for C in 1 .. L loop
                        Got (C) := Entries (K).Id (C);
                     end loop;
                     if Got /= EI then
                        Put_Line ("FAIL " & Name & ": entry" & K'Image
                                  & " id """ & Got & """ /= """ & EI & """");
                        Failures := Failures + 1;
                        return;
                     end if;
                  end;
               end if;
            end;
         end loop;
         Passed := Passed + 1;
         Put_Line ("ok   " & Name & " (" & Count'Image & " entries )");
      end;
   end Check_Fixture;

begin
   for I in 1 .. Fixture_Expectations.Fixture_Count loop
      Check_Fixture (I);
   end loop;
   Put_Line ("M1a:" & Passed'Image & " passed,"
             & Skipped'Image & " skipped," & Failures'Image & " failed");
   if Failures > 0 then
      raise Program_Error with "M1a fixture checks failed";
   end if;
end Test_M1a;
