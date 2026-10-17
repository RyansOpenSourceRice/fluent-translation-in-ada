--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Resource — multi-bundle fallback chain (BCP-47 negotiation stub).
--  M0: chain type + best-match lookup over exact tag equality.
--  M2: prefix fallback (fr-CA -> fr -> en-US) + resource loading.

with Fluent.Bundle;
with Fluent.Locale;

package Fluent.Resource
  with SPARK_Mode => On
is

   Max_Bundles : constant := 8;

   type Bundle_Array is array (1 .. Max_Bundles) of Fluent.Bundle.Bundle;

   type Fallback_Chain is record
      Bundles : Bundle_Array;
      Count   : Natural range 0 .. Max_Bundles := 0;
   end record;

   function Empty_Chain return Fallback_Chain;

   function Best_Match
     (Chain : Fallback_Chain;
      Tag   : Fluent.Locale.Locale_Tag) return Natural
     with Post => Best_Match'Result <= Chain.Count;

end Fluent.Resource;
