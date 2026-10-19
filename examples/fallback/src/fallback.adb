--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fallback example: pick the best bundle for a requested locale tag.
--  Run from the repository root.

with Ada.Text_IO;
with Fluent.Bundle;
with Fluent.Locale;
with Fluent.Resource;

procedure Fallback is
   use Ada.Text_IO;

   En_US : constant Fluent.Locale.Locale_Tag :=
     Fluent.Locale.Make_Tag ("en-US");
   Fr    : constant Fluent.Locale.Locale_Tag :=
     Fluent.Locale.Make_Tag ("fr");

   Chain : Fluent.Resource.Fallback_Chain :=
     Fluent.Resource.Empty_Chain;
   Pick  : Natural;
begin
   Chain.Bundles (1) := Fluent.Bundle.Empty_Bundle (En_US);
   Chain.Bundles (2) := Fluent.Bundle.Empty_Bundle (Fr);
   Chain.Count := 2;
   Pick := Fluent.Resource.Best_Match (Chain, Fr);
   Put_Line ("bundles:" & Chain.Count'Image & " best:" & Pick'Image);
end Fallback;
