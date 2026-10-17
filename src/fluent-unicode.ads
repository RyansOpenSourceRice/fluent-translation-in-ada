--  Copyright 2026 Ryan
--  SPDX-License-Identifier: Apache-2.0
--
--  Fluent.Unicode — VSS boundary (SPARK_Mode Off by design).
--  Core logic stays in SPARK-compatible String/Wide_Wide types; all VSS
--  Virtual_String conversions happen here so GNATprove Silver covers
--  every unit except this explicitly documented edge adapter.

with VSS.Strings;

package Fluent.Unicode
  with SPARK_Mode => Off
is

   function To_Virtual (Text : String) return VSS.Strings.Virtual_String;
   function From_Virtual (Text : VSS.Strings.Virtual_String) return String;

end Fluent.Unicode;
