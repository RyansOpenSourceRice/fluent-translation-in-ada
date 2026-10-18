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

   function Is_Id_Start (C : Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z');

   function Is_Id_Char (C : Character) return Boolean is
     (Is_Id_Start (C) or else C in '0' .. '9' | '_' | '-');

   function Is_Entry_Start (C : Character) return Boolean is
     (Is_Id_Start (C) or else C = '-' or else C = '#');

   --  Source length bound with headroom: Len + 1 never overflows.
   subtype Len_Bound is Natural range 0 .. Max_Source_Length + 1;

   --  Hard line ending at Pos: LF, CRLF, or EOF. A lone CR is content,
   --  except a CR at EOF which ends the line (stripped).
   function At_Hard_EOL (Source : String; Pos : Natural; Len : Len_Bound) return Boolean
   is (Pos > Len
       or else Source (Pos) = ASCII.LF
       or else (Source (Pos) = ASCII.CR
                and then (Pos = Len or else Source (Pos + 1) = ASCII.LF)))
     with Pre => Source'First = 1
       and then Source'Length = Len
       and then Pos in 1 .. Len + 1;

   --  Index of the first hard-EOL character at or after Pos, or Len + 1.
   function Line_Ends_At (Source : String; Pos : Natural; Len : Len_Bound) return Natural
     with Pre => Source'First = 1
       and then Source'Length = Len
       and then Pos in 1 .. Len + 1,
       Post => Line_Ends_At'Result in Pos .. Len + 1
         and then (Line_Ends_At'Result > Len
                   or else At_Hard_EOL (Source, Line_Ends_At'Result, Len))
   is
      P : Natural := Pos;
   begin
      while P <= Len and then not At_Hard_EOL (Source, P, Len) loop
         pragma Loop_Invariant (P in Pos .. Len);
         pragma Loop_Variant (Increases => P);
         P := P + 1;
      end loop;
      return P;
   end Line_Ends_At;

   function Line_Is_Blank (Source : String; Pos : Natural; Len : Len_Bound) return Boolean
     with Pre => Source'First = 1
       and then Source'Length = Len
       and then Pos in 1 .. Len + 1
   is
      L : Natural := Pos;
   begin
      while L <= Len and then Source (L) = ' ' loop
         pragma Loop_Invariant (L in Pos .. Len);
         pragma Loop_Variant (Increases => L);
         L := L + 1;
      end loop;
      return At_Hard_EOL (Source, L, Len);
   end Line_Is_Blank;

   --  True when an attribute (indent "." Identifier "=") starts at the
   --  indented line beginning at Pos. Never consumes input.
   function Attribute_Starts_At
     (Source : String; Pos : Natural; Len : Len_Bound) return Boolean
     with Pre => Source'First = 1
       and then Source'Length = Len
       and then Pos in 1 .. Len
       and then Source (Pos) = ' '
   is
      P : Natural := Pos;
   begin
      while P <= Len and then Source (P) = ' ' loop
         pragma Loop_Invariant (P in Pos .. Len);
         pragma Loop_Variant (Increases => P);
         P := P + 1;
      end loop;
      if P > Len or else Source (P) /= '.' then
         return False;
      end if;
      P := P + 1;
      if P > Len or else not Is_Id_Start (Source (P)) then
         return False;
      end if;
      while P <= Len and then Is_Id_Char (Source (P)) loop
         pragma Loop_Invariant (P in Pos .. Len);
         pragma Loop_Variant (Increases => P);
         P := P + 1;
      end loop;
      while P <= Len and then Source (P) = ' ' loop
         pragma Loop_Invariant (P in Pos .. Len);
         pragma Loop_Variant (Increases => P);
         P := P + 1;
      end loop;
      return P <= Len and then Source (P) = '=';
   end Attribute_Starts_At;

   --  First non-space character of the line at Pos; NUL when the line has
   --  no content (blank, EOL, or EOF).
   function First_Content_Char
     (Source : String; Pos : Natural; Len : Len_Bound) return Character
     with Pre => Source'First = 1
       and then Source'Length = Len
       and then Pos in 1 .. Len + 1
   is
      P : Natural := Pos;
   begin
      while P <= Len and then Source (P) = ' ' loop
         pragma Loop_Invariant (P in Pos .. Len);
         pragma Loop_Variant (Increases => P);
         P := P + 1;
      end loop;
      if P > Len or else At_Hard_EOL (Source, P, Len) then
         return ASCII.NUL;
      end if;
      return Source (P);
   end First_Content_Char;

   procedure Parse_Resource
     (Source     : String;
      Entries    : out Entry_Array;
      Count      : out Natural;
      Junk_Count : out Natural)
   is
      Len        : constant Len_Bound := Source'Length;
      Pos        : Natural;
      Line       : Natural;
      Line_Start : Natural;
      N          : Natural;
      J          : Natural;

      --  Placeable nesting depth for raw value spans. Braces inside
      --  string literals do not count; strings never span lines.
      subtype Depth_Count is Natural range 0 .. Max_Source_Length;

      procedure Skip_Spaces is
      begin
         while Pos <= Len and then Source (Pos) = ' ' loop
            pragma Loop_Invariant (Pos in 1 .. Len + 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Variant (Increases => Pos);
            Pos := Pos + 1;
         end loop;
      end Skip_Spaces;

      --  Consume the line ending at E (a Line_Ends_At result for Pos).
      procedure Consume_Line (E : Natural)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then E in Pos .. Len + 1
          and then (E > Len or else At_Hard_EOL (Source, E, Len))
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos > Pos'Old
               and then Pos <= Len + 1
               and then Line_Start = Pos
               and then Line_Start <= Pos
               and then Line >= 1
      is
      begin
         if E > Len then
            Pos := Len + 1;
         elsif Source (E) = ASCII.LF then
            Pos := E + 1;
         elsif E = Len then
            --  Lone CR at EOF: consume the single character.
            Pos := Len + 1;
         else
            Pos := E + 2;
         end if;
         Line_Start := Pos;
         if Pos <= Len and then Line < Natural'Last then
            Line := Line + 1;
         end if;
      end Consume_Line;

      procedure Skip_Blank_Lines
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len + 1
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then Pos >= Pos'Old
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
               and then Line_Start <= Pos
      is
         E : Natural;
      begin
         while Pos <= Len and then Line_Is_Blank (Source, Pos, Len) loop
            pragma Loop_Invariant (Pos in 1 .. Len + 1);
            pragma Loop_Invariant (Line >= 1);
            pragma Loop_Invariant (Line_Start in 1 .. Len + 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Variant (Increases => Pos);
            E := Line_Ends_At (Source, Pos, Len);
            Consume_Line (E);
         end loop;
      end Skip_Blank_Lines;

      procedure Parse_Identifier
        (Id     : out Identifier_Text;
         Id_Len : out Identifier_Length;
         Ok     : out Boolean)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then Is_Id_Start (Source (Pos))
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then Pos > Pos'Old
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
               and then Line_Start <= Pos
               and then (if Ok then Id_Len >= 1)
      is
         Buf : Identifier_Text := [others => ' '];
         L   : Identifier_Length := 0;
      begin
         Id := Buf;
         Id_Len := L;
         while Pos <= Len
           and then Is_Id_Char (Source (Pos))
           and then L < Max_Identifier_Length
         loop
            pragma Loop_Invariant (Pos >= 1);
            pragma Loop_Variant (Increases => Pos);
            L := L + 1;
            Buf (L) := Source (Pos);
            Pos := Pos + 1;
         end loop;
         if Pos <= Len and then Is_Id_Char (Source (Pos)) then
            Ok := False;
         else
            Ok := True;
            Id := Buf;
            Id_Len := L;
         end if;
      end Parse_Identifier;

      --  Scan First .. Last, tracking placeable nesting depth. Double
      --  quotes toggle string mode; a backslash skips the next character.
      procedure Scan_Depth
        (First, Last : Natural;
         Depth      : in out Depth_Count)
        with Pre => Source'First = 1
          and then Source'Length = Len
          and then First in 1 .. Len + 1
          and then Last in 0 .. Len
      is
         In_Str    : Boolean := False;
         Skip_Next : Boolean := False;
         C         : Character;
      begin
         for I in First .. Last loop
            C := Source (I);
            if Skip_Next then
               Skip_Next := False;
            elsif In_Str then
               if C = '\' then
                  Skip_Next := True;
               elsif C = '"' then
                  In_Str := False;
               end if;
            elsif C = '"' then
               In_Str := True;
            elsif C = '{' then
               if Depth < Depth_Count'Last then
                  Depth := Depth + 1;
               end if;
            elsif C = '}' then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            end if;
         end loop;
      end Scan_Depth;

      --  Consume the non-blank line at Pos into Span, updating End_Line /
      --  End_Col and scanning brace depth over the whole line. Tolerant of
      --  blank lines (yields an absent span); callers only pass content.
      procedure Consume_Content_Line
        (Span     : in out Text_Span;
         Depth    : in out Depth_Count;
         End_Line : in out Natural;
         End_Col  : in out Natural)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then Pos > Pos'Old
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
      is
         P2 : Natural := Pos;
         E  : Natural;
      begin
         while P2 <= Len and then Source (P2) = ' ' loop
            pragma Loop_Invariant (P2 in Pos .. Len);
            P2 := P2 + 1;
         end loop;
         if not Is_Present (Span) then
            Span.First := P2;
         end if;
         E := Line_Ends_At (Source, Pos, Len);
         Span.Last := E - 1;
         End_Line := Line;
         End_Col := (if E >= Line_Start then E - Line_Start else 0);
         Scan_Depth (Pos, E - 1, Depth);
         Consume_Line (E);
      end Consume_Content_Line;

      --  Consume indented continuation lines into Span, stopping before
      --  attributes, dot-lines, dedents, comments inside placeables, and
      --  EOF. A "{" line at column 0 joins the span (reference behavior
      --  for multi-line placeables); while brace depth is open, every
      --  line but a column-0 comment joins. Gap blank lines are consumed
      --  but never touch the span.
      procedure Consume_Continuation
        (Span     : in out Text_Span;
         Depth    : in out Depth_Count;
         End_Line : in out Natural;
         End_Col  : in out Natural;
         Moved    : out Boolean)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len + 1
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then (if Moved then Pos > Pos'Old else Pos >= Pos'Old)
               and then (if not Moved then Span = Span'Old)
          and then (if not Moved then Depth = Depth'Old)
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
      is
         Entry_Pos  : constant Natural := Pos;
         Work_Span  : Text_Span := Span;
         Work_Depth : Depth_Count := Depth;
         C          : Character;
      begin
         Moved := False;
         loop
            pragma Loop_Invariant (Pos in Entry_Pos .. Len + 1);
            pragma Loop_Invariant (Line >= 1);
            pragma Loop_Invariant (Line_Start in 1 .. Len + 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Invariant (if Moved then Pos > Entry_Pos);
            pragma Loop_Variant (Increases => Pos);
            Skip_Blank_Lines;
            exit when Pos > Len;
            if Work_Depth = 0 then
               exit when Source (Pos) /= ' '
                 and then Source (Pos) /= '{';
               exit when Source (Pos) = ' '
                 and then Attribute_Starts_At (Source, Pos, Len);
               --  Block text cannot start with ".", "[", or "*" (EBNF
               --  indented_char); those lines end the value. Placeable
               --  lines inside selects are covered by Depth > 0 instead.
               C := First_Content_Char (Source, Pos, Len);
               exit when C = '.' or else C = '[' or else C = '*'
                 or else C = ASCII.NUL;
            else
               exit when Source (Pos) = '#';
            end if;
            Consume_Content_Line (Work_Span, Work_Depth,
                                  End_Line, End_Col);
            Moved := True;
         end loop;
         if Moved then
            Span := Work_Span;
            Depth := Work_Depth;
         end if;
      end Consume_Continuation;

      procedure Parse_Attribute
        (Attr     : out Attribute_Node;
         End_Line : in out Natural;
         End_Col  : in out Natural;
         Ok       : out Boolean)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then Attribute_Starts_At (Source, Pos, Len)
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then (if Ok then Pos > Pos'Old)
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
      is
         Buf       : Identifier_Text := [others => ' '];
         L         : Identifier_Length := 0;
         Span      : Text_Span := (First => 0, Last => 0);
         Depth     : Depth_Count := 0;
         Moved     : Boolean;
         Progress  : Boolean := False;
      begin
         Ok := False;
         Attr := (Id      => [others => ' '],
                  Id_Len  => 0,
                  Value   => (First => 0, Last => 0));
         while Pos <= Len and then Source (Pos) = ' ' loop
            pragma Loop_Invariant (Pos in 1 .. Len);
            pragma Loop_Invariant (Line_Start <= Pos);
            Pos := Pos + 1;
         end loop;
         --  Pre guarantees the shape below; re-check defensively.
         if Pos > Len or else Source (Pos) /= '.' then
            return;
         end if;
         Pos := Pos + 1;
         if Pos > Len or else not Is_Id_Start (Source (Pos)) then
            return;
         end if;
         while Pos <= Len
           and then Is_Id_Char (Source (Pos))
           and then L < Max_Identifier_Length
         loop
            pragma Loop_Invariant (Pos >= 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Variant (Increases => Pos);
            L := L + 1;
            Buf (L) := Source (Pos);
            Pos := Pos + 1;
         end loop;
         if Pos <= Len and then Is_Id_Char (Source (Pos)) then
            return;
         end if;
         Skip_Spaces;
         if Pos > Len or else Source (Pos) /= '=' then
            return;
         end if;
         Pos := Pos + 1;
         Skip_Spaces;
         if not At_Hard_EOL (Source, Pos, Len) then
            Consume_Content_Line (Span, Depth, End_Line, End_Col);
            Progress := True;
         end if;
         Consume_Continuation (Span, Depth, End_Line, End_Col, Moved);
         if Moved then
            Progress := True;
         end if;
         if not Progress then
            --  No input consumed: cannot be a valid attribute.
            return;
         end if;
         if Depth /= 0 then
            --  Unclosed placeable: the attribute value is invalid.
            return;
         end if;
         if not Is_Present (Span) then
            return;
         end if;
         Attr := (Id => Buf, Id_Len => L, Value => Span);
         Ok := True;
      end Parse_Attribute;

      procedure Try_Entry
        (Is_Term : Boolean;
         Attach  : Text_Span;
         Node    : out Entry_Node;
         Ok      : out Boolean)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos
          and then not Node'Constrained
          and then (if Is_Term then
                      Source (Pos) = '-'
                      and then Pos < Len
                      and then Is_Id_Start (Source (Pos + 1))
                    else Is_Id_Start (Source (Pos))),
             Post => Pos in 1 .. Len + 1
               and then (if Ok then Pos > Pos'Old)
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
      is
         Start_Pos   : constant Natural := Pos;
         Start_Line  : constant Natural := Line;
         End_Line    : Natural := Line;
         End_Col     : Natural := 1;
         Buf         : Identifier_Text := [others => ' '];
         L           : Identifier_Length := 0;
         Id_Ok       : Boolean;
         Value       : Text_Span := (First => 0, Last => 0);
         Depth       : Depth_Count := 0;
         Local_Attrs : Attribute_Array (1 .. Max_Attributes_Per_Entry);
         AC          : Natural range 0 .. Max_Attributes_Per_Entry := 0;
         Attr        : Attribute_Node;
         Attr_Ok     : Boolean;
         Moved       : Boolean;
         Progress    : Boolean := False;
      begin
         Ok := False;
         if Is_Term then
            Pos := Pos + 1;
         end if;
         Parse_Identifier (Buf, L, Id_Ok);
         if not Id_Ok then
            return;
         end if;
         Skip_Spaces;
         if Pos > Len or else Source (Pos) /= '=' then
            return;
         end if;
         Pos := Pos + 1;
         Skip_Spaces;
         if not At_Hard_EOL (Source, Pos, Len) then
            Consume_Content_Line (Value, Depth, End_Line, End_Col);
            Progress := True;
         end if;
         loop
            pragma Loop_Invariant (Pos in Start_Pos .. Len + 1);
            pragma Loop_Invariant (Line >= 1);
            pragma Loop_Invariant (Line_Start in 1 .. Len + 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Variant (Increases => Pos);
            Consume_Continuation (Value, Depth, End_Line, End_Col, Moved);
            if Moved then
               Progress := True;
            end if;
            exit when Pos > Len;
            exit when Source (Pos) /= ' ';
            exit when not Attribute_Starts_At (Source, Pos, Len);
            if AC = Max_Attributes_Per_Entry then
               return;
            end if;
            Parse_Attribute (Attr, End_Line, End_Col, Attr_Ok);
            if not Attr_Ok then
               return;
            end if;
            AC := AC + 1;
            Local_Attrs (AC) := Attr;
            Progress := True;
         end loop;
         if not Progress then
            --  No input consumed: cannot be a valid entry.
            return;
         end if;
         if Depth /= 0 then
            --  Unclosed placeable: the pattern is invalid.
            return;
         end if;
         if not Is_Present (Value) and then (Is_Term or else AC = 0) then
            return;
         end if;
         Node :=
           (Kind       => Message_Kind'(if Is_Term then Term else Message),
            Span       => (Start_Line, 1, End_Line, End_Col),
            Id         => Buf,
            Id_Len     => L,
            Value      => Value,
            Attached_Comment => Attach,
            Attrs      => Local_Attrs,
            Attr_Count => AC);
         Ok := True;
      end Try_Entry;

      procedure Parse_Comments
        (G_Kind    : out Comment_Kind;
         G_Text    : out Text_Span;
         G_First   : out Natural;
         G_End     : out Natural;
         G_End_Col : out Natural;
         Ok        : out Boolean)
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then Source (Pos) = '#'
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then (if Ok then Pos > Pos'Old else Pos = Pos'Old)
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
      is
         H  : Natural := 0;
         Q  : Natural;
         H2 : Natural;
         Q2 : Natural;
         E  : Natural;
      begin
         Ok := False;
         G_Kind := Comment;
         G_Text := (First => 0, Last => 0);
         G_First := 0;
         G_End := 0;
         G_End_Col := 0;
         while H < 4 and then Pos + H <= Len
           and then Source (Pos + H) = '#'
         loop
            pragma Loop_Invariant (H <= 4);
            H := H + 1;
         end loop;
         if H = 0 or else H > 3 then
            return;
         end if;
         Q := Pos + H;
         if Q <= Len
           and then not At_Hard_EOL (Source, Q, Len)
           and then Source (Q) /= ' '
         then
            return;
         end if;
         G_Text.First := Pos;
         G_First := Line;
         E := Line_Ends_At (Source, Pos, Len);
         G_Text.Last := E - 1;
         G_End := Line;
         G_End_Col := (if E >= Line_Start then E - Line_Start else 0);
         Consume_Line (E);
         G_Kind :=
           (if H = 1 then Comment
            elsif H = 2 then Group_Comment
            else Resource_Comment);
         while Pos <= Len and then Source (Pos) = '#' loop
            pragma Loop_Invariant (Pos in 1 .. Len);
            pragma Loop_Invariant (Line >= 1);
            pragma Loop_Invariant (Line_Start in 1 .. Len + 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Variant (Increases => Pos);
            H2 := 0;
            while H2 < 4 and then Pos + H2 <= Len
              and then Source (Pos + H2) = '#'
            loop
               pragma Loop_Invariant (H2 <= 4);
               H2 := H2 + 1;
            end loop;
            exit when H2 /= H;
            Q2 := Pos + H2;
            exit when Q2 <= Len
              and then not At_Hard_EOL (Source, Q2, Len)
              and then Source (Q2) /= ' ';
            E := Line_Ends_At (Source, Pos, Len);
            G_Text.Last := E - 1;
            G_End := Line;
            G_End_Col := (if E >= Line_Start then E - Line_Start else 0);
            Consume_Line (E);
         end loop;
         Ok := True;
      end Parse_Comments;

      procedure Emit_Junk
        with Pre  => Source'First = 1
          and then Pos in 1 .. Len
          and then N < Entries'Length
          and then J <= N
          and then Line >= 1
          and then Line_Start in 1 .. Len + 1
          and then Line_Start <= Pos,
             Post => Pos in 1 .. Len + 1
               and then Pos > Pos'Old
               and then N = N'Old + 1
               and then J = J'Old + 1
               and then Line >= 1
               and then Line_Start in 1 .. Len + 1
      is
         E       : Natural;
         J_First : constant Natural := Line;
         J_Col   : Natural;
      begin
         E := Line_Ends_At (Source, Pos, Len);
         J_Col := (if E >= Line_Start then E - Line_Start else 0);
         Consume_Line (E);
         while Pos <= Len loop
            pragma Loop_Invariant (Pos in 1 .. Len + 1);
            pragma Loop_Invariant (Line >= 1);
            pragma Loop_Invariant (Line_Start in 1 .. Len + 1);
            pragma Loop_Invariant (Line_Start <= Pos);
            pragma Loop_Variant (Increases => Pos);
            if Line_Is_Blank (Source, Pos, Len) then
               E := Line_Ends_At (Source, Pos, Len);
               J_Col := (if E >= Line_Start then E - Line_Start else 0);
               Consume_Line (E);
            elsif Is_Entry_Start (Source (Pos)) then
               exit;
            else
               E := Line_Ends_At (Source, Pos, Len);
               J_Col := (if E >= Line_Start then E - Line_Start else 0);
               Consume_Line (E);
            end if;
         end loop;
         N := N + 1;
         J := J + 1;
         Entries (N) := (Kind => Junk, Span => (J_First, 1, Line, J_Col));
      end Emit_Junk;

      C        : Character;
      Node     : Entry_Node;
      Entry_Ok : Boolean;
      G_Kind   : Comment_Kind;
      G_Text   : Text_Span;
      G_First  : Natural;
      G_End    : Natural;
      G_Col    : Natural;
      G_Ok     : Boolean;
      S_Pos    : Natural;
      S_Line   : Natural;
      S_Start  : Natural;
   begin
      for I in Entries'Range loop
         Entries (I) := (Kind => Blank, Span => (0, 0, 0, 0));
      end loop;
      N := 0;
      J := 0;
      Pos := 1;
      Line := 1;
      Line_Start := 1;
      Skip_Blank_Lines;
      while Pos <= Len loop
         pragma Loop_Invariant (Pos in 1 .. Len);
         pragma Loop_Invariant (Line >= 1);
         pragma Loop_Invariant (Line_Start in 1 .. Len + 1);
         pragma Loop_Invariant (Line_Start <= Pos);
         pragma Loop_Invariant (N <= Entries'Length);
         pragma Loop_Invariant (J <= N);
         pragma Loop_Variant (Increases => Pos);
         exit when N = Entries'Length;
         C := Source (Pos);
         if C = '#' then
            Parse_Comments (G_Kind, G_Text, G_First, G_End, G_Col, G_Ok);
            if not G_Ok then
               Emit_Junk;
            elsif G_Kind = Comment
              and then Pos <= Len
              and then (Is_Id_Start (Source (Pos))
                        or else Source (Pos) = '-')
            then
               if Source (Pos) = '-'
                 and then (Pos = Len
                           or else not Is_Id_Start (Source (Pos + 1)))
               then
                  N := N + 1;
                  Entries (N) :=
                    (Kind => G_Kind,
                     Span => (G_First, 1, G_End, G_Col),
                     Text => G_Text);
                  exit when N = Entries'Length;
                  Emit_Junk;
               else
                  S_Pos := Pos;
                  S_Line := Line;
                  S_Start := Line_Start;
                  Try_Entry
                    (Is_Term => Source (Pos) = '-',
                     Attach  => G_Text,
                     Node    => Node,
                     Ok      => Entry_Ok);
                  if Entry_Ok then
                     N := N + 1;
                     Entries (N) := Node;
                  else
                     Pos := S_Pos;
                     Line := S_Line;
                     Line_Start := S_Start;
                     N := N + 1;
                     Entries (N) :=
                       (Kind => G_Kind,
                        Span => (G_First, 1, G_End, G_Col),
                        Text => G_Text);
                     exit when N = Entries'Length;
                     Emit_Junk;
                  end if;
               end if;
            else
               N := N + 1;
               Entries (N) :=
                 (Kind => G_Kind,
                  Span => (G_First, 1, G_End, G_Col),
                  Text => G_Text);
            end if;
         elsif Is_Id_Start (C) then
            S_Pos := Pos;
            S_Line := Line;
            S_Start := Line_Start;
            Try_Entry
              (Is_Term => False, Attach => (First => 0, Last => 0),
               Node    => Node, Ok => Entry_Ok);
            if Entry_Ok then
               N := N + 1;
               Entries (N) := Node;
            else
               Pos := S_Pos;
               Line := S_Line;
               Line_Start := S_Start;
               Emit_Junk;
            end if;
         elsif C = '-'
           and then Pos < Len
           and then Is_Id_Start (Source (Pos + 1))
         then
            S_Pos := Pos;
            S_Line := Line;
            S_Start := Line_Start;
            Try_Entry
              (Is_Term => True, Attach => (First => 0, Last => 0),
               Node    => Node, Ok => Entry_Ok);
            if Entry_Ok then
               N := N + 1;
               Entries (N) := Node;
            else
               Pos := S_Pos;
               Line := S_Line;
               Line_Start := S_Start;
               Emit_Junk;
            end if;
         else
            Emit_Junk;
         end if;
         Skip_Blank_Lines;
      end loop;
      Count := N;
      Junk_Count := J;
   end Parse_Resource;

end Fluent.Syntax;
