--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Errors — formatting/parse error kinds.
--  Errors are values, never raised exceptions (Pony reference pattern:
--  resolution returns a fallback rendering, caller inspects errors).

package Fluent.Errors
  with SPARK_Mode => On
is

   type Error_Kind is
     (None,
      Unknown_Message,
      Unknown_Attribute,
      Unknown_Term,
      Missing_Variable,
      Missing_Default_Variant,
      Cyclic_Reference,
      Parse_Error,
      Unsupported_Construct);

   type Format_Error is record
      Kind    : Error_Kind := None;
      Code    : Natural := 0;
      --  Line/column of the offending entry when known (0 = unknown).
      Line    : Natural := 0;
      Column  : Natural := 0;
   end record;

   Max_Errors : constant := 32;

   type Error_List is array (Positive range <>) of Format_Error;

end Fluent.Errors;
