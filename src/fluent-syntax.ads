--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Syntax — FTL entry-level AST + entry parser (M1a).
--  Entries, identifiers, attributes, comments and junk per
--  upstream spec/fluent.ebnf. Patterns are stored as source spans;
--  M1b parses pattern contents (text elements, placeables).

package Fluent.Syntax
  with SPARK_Mode => On
is

   Max_Identifier_Length    : constant := 128;
   Max_Attributes_Per_Entry : constant := 16;
   Max_Entries              : constant := 512;
   Max_Source_Length        : constant := 1_000_000;

   subtype Identifier_Length is Natural range 0 .. Max_Identifier_Length;
   type Identifier_Text is array (1 .. Max_Identifier_Length) of Character;

   --  Inclusive source indices (Source'First = 1 is required by
   --  Parse_Resource); First = 0 means absent.
   type Text_Span is record
      First : Natural := 0;
      Last  : Natural := 0;
   end record;

   function Is_Present (Span : Text_Span) return Boolean is
     (Span.First >= 1 and then Span.First <= Span.Last);

   type Source_Span is record
      First_Line   : Natural := 0;
      First_Column : Natural := 0;
      Last_Line    : Natural := 0;
      Last_Column  : Natural := 0;
   end record;

   type Entry_Kind is
     (Message, Term, Comment, Group_Comment, Resource_Comment, Blank, Junk);

   subtype Comment_Kind is Entry_Kind range Comment .. Resource_Comment;
   subtype Message_Kind is Entry_Kind range Message .. Term;

   type Attribute_Node is record
      Id      : Identifier_Text := [others => ' '];
      Id_Len  : Identifier_Length := 0;
      Value   : Text_Span;
   end record;

   type Attribute_Array is array (Positive range <>) of Attribute_Node;

   type Entry_Node (Kind : Entry_Kind := Blank) is record
      Span : Source_Span;
      case Kind is
         when Message | Term =>
            Id      : Identifier_Text := [others => ' '];
            Id_Len  : Identifier_Length := 0;
            Value      : Text_Span;
            Attached_Comment : Text_Span;
            Attrs      : Attribute_Array (1 .. Max_Attributes_Per_Entry);
            Attr_Count : Natural range 0 .. Max_Attributes_Per_Entry := 0;
         when Comment | Group_Comment | Resource_Comment =>
            Text : Text_Span;
         when Blank | Junk =>
            null;
      end case;
   end record;

   type Entry_Array is array (Positive range <>) of Entry_Node;

   --  Lenient parse: malformed entries become Junk nodes, parsing resumes
   --  at the next entry-looking line (mirrors the reference parser posture
   --  and the Pony port's entry-level recovery).
   function Count_Entries (Source : String) return Natural
     with
       Pre => Source'Length <= 1_000_000,
       Post => Count_Entries'Result <= Max_Entries;

   function Has_Cr_At_End_Of_Line (Source : String; Pos : Natural) return Boolean
     with Pre => Source'First <= Pos and Pos <= Source'Last;

   --  Parse a whole resource. Entries are appended in source order.
   --  Junk_Count tallies Junk entries. A lone "-" or non-identifier start
   --  at column 0, an over-long identifier (> Max_Identifier_Length), a
   --  missing "=", a missing value (terms always need one; messages need
   --  a value or at least one valid attribute), or an invalid attribute
   --  turns the entry into Junk. Single-# comment groups directly
   --  preceding a successful message/term attach to its Comment span.
   --  Callers size Entries for the input; parsing stops when full.
   procedure Parse_Resource
     (Source     : String;
      Entries    : out Entry_Array;
      Count      : out Natural;
      Junk_Count : out Natural)
     with
       Pre  => Source'Length <= Max_Source_Length
         and then Source'First = 1
         and then Entries'First = 1
         and then Entries'Length in 1 .. Max_Entries,
       Post => Count <= Entries'Length
         and then Junk_Count <= Count;

end Fluent.Syntax;
