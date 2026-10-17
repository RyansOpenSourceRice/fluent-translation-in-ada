--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0

with VSS.Strings.Conversions;

package body Fluent.Unicode
  with SPARK_Mode => Off
is

   function To_Virtual (Text : String) return VSS.Strings.Virtual_String is
   begin
      return VSS.Strings.Conversions.To_Virtual_String (Text);
   end To_Virtual;

   function From_Virtual (Text : VSS.Strings.Virtual_String) return String is
   begin
      return VSS.Strings.Conversions.To_UTF_8_String (Text);
   end From_Virtual;

end Fluent.Unicode;
