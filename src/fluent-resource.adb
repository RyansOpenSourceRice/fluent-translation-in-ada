--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0

package body Fluent.Resource
  with SPARK_Mode => On
is

   function Empty_Chain return Fallback_Chain
   is
      Result : Fallback_Chain;
   begin
      Result.Count := 0;
      return Result;
   end Empty_Chain;

   function Best_Match
     (Chain : Fallback_Chain;
      Tag   : Fluent.Locale.Locale_Tag) return Natural
   is
   begin
      for I in 1 .. Chain.Count loop
         pragma Loop_Invariant (I <= Chain.Count);
         if Fluent.Locale.Tags_Equal (Chain.Bundles (I).Tag, Tag) then
            return I;
         end if;
      end loop;
      if Chain.Count > 0 then
         return 1;
      else
         return 0;
      end if;
   end Best_Match;

end Fluent.Resource;
