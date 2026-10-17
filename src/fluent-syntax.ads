--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Syntax — FTL AST node kinds and entry-level parser skeleton.
--  M0: types + span tracking + lenient entry recovery contract.
--  M1: full EBNF recursive-descent parser against upstream fixtures.

package Fluent.Syntax
  with SPARK_Mode => On
is

   Max_Identifier_Length : constant := 128;
   Max_Pattern_Length    : constant := 4096;
   Max_Entries           : constant := 512;

   subtype Identifier_Length is Natural range 0 .. Max_Identifier_Length;
   subtype Pattern_Length is Natural range 0 .. Max_Pattern_Length;

   type Identifier_Text is array (1 .. Max_Identifier_Length) of Character;
   type Pattern_Text is array (1 .. Max_Pattern_Length) of Character;

   type Source_Span is record
      First_Line   : Natural := 0;
      First_Column : Natural := 0;
      Last_Line    : Natural := 0;
      Last_Column  : Natural := 0;
   end record;

   type Entry_Kind is (Message, Term, Comment, Blank, Junk);

   type Entry_Node (Kind : Entry_Kind := Blank) is record
      Span : Source_Span;
      case Kind is
         when Message | Term =>
            Id     : Identifier_Text := [others => ' '];
            Id_Len : Identifier_Length := 0;
            Value     : Pattern_Text := [others => ' '];
            Value_Len : Pattern_Length := 0;
            Has_Default_Variant : Boolean := False;
         when Comment | Blank | Junk =>
            null;
      end case;
   end record;

   type Entry_Array is array (Positive range <>) of Entry_Node;

   --  Lenient parse: malformed entries become Junk nodes, parsing resumes
   --  at the next column-0 line (mirrors reference parser posture and the
   --  Pony port's entry-level recovery).
   function Count_Entries (Source : String) return Natural
     with
       Pre => Source'Length <= 1_000_000,
       Post => Count_Entries'Result <= Max_Entries;

   function Has_Cr_At_End_Of_Line (Source : String; Pos : Natural) return Boolean
     with Pre => Source'First <= Pos and Pos <= Source'Last;

end Fluent.Syntax;
