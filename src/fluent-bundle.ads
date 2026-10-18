--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Bundle — single-locale message collection + resolver contract.
--  M0: table types + select-default resolution helper (pure, provable).
--  M1/M2: full pattern resolver, references, variables, call expressions.

with Fluent.Locale;
with Fluent.Syntax;

package Fluent.Bundle
  with SPARK_Mode => On
is

   Max_Messages       : constant := 64;
   Max_Message_Length : constant := 1_024;

   subtype Message_Index is Natural range 0 .. Max_Messages;
   subtype Message_Length is Natural range 0 .. Max_Message_Length;
   type Message_Text is array (1 .. Max_Message_Length) of Character;

   type Message_Slot is record
      Id     : Fluent.Syntax.Identifier_Text := [others => ' '];
      Id_Len : Fluent.Syntax.Identifier_Length := 0;
      Value     : Message_Text := [others => ' '];
      Value_Len : Message_Length := 0;
      Present   : Boolean := False;
   end record;

   type Message_Table is array (1 .. Max_Messages) of Message_Slot;

   type Bundle is record
      Tag     : Fluent.Locale.Locale_Tag;
      Slots   : Message_Table;
      Count   : Message_Index := 0;
   end record;

   function Empty_Bundle (Tag : Fluent.Locale.Locale_Tag) return Bundle;

   --  Select resolution: first variant whose key equals the selector wins,
   --  else the default variant; empty selection renders as "{select}".
   --  Keys/values are modeled as small integer ids in M0; M2 lifts this
   --  to full string keys without changing the contract shape.
   function Resolve_Select
     (Selector      : Natural;
      Keys          : Fluent.Syntax.Entry_Array;
      Has_Default   : Boolean;
      Default_Index : Natural) return Natural
     with Pre => Keys'Length <= 64
       and then (not Has_Default or else Default_Index in Keys'Range);

end Fluent.Bundle;
