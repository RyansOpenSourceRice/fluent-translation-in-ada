# SPECIFICATION — fluent-translation-in-ada

## 0. Scope

Ada 2022 library implementing Project Fluent: FTL resource syntax, message
resolution with locale fallback, and ECMA-402-shaped locale services in pure
Ada (no ICU4C/host FFI). SPARK Silver throughout except `Fluent.Unicode`.

Upstream conformance: `https://github.com/projectfluent/fluent`
(`spec/fluent.ebnf`, `test/fixtures/*.ftl` + `*.json`).

## 1. Public API (M0 contracts)

- `Fluent` — version constants (`Version_Major/Minor/Patch` = 0.1.0).
- `Fluent.Errors` — `Error_Kind` (`None`, `Unknown_Message`,
  `Unknown_Attribute`, `Unknown_Term`, `Missing_Variable`,
  `Missing_Default_Variant`, `Cyclic_Reference`, `Parse_Error`,
  `Unsupported_Construct`), `Format_Error` (Kind/Code/Line/Column),
  `Max_Errors = 32`, `Error_List`.
- `Fluent.Syntax` — `Max_Identifier_Length = 128`,
  `Max_Pattern_Length = 4096`, `Max_Entries = 512`; `Entry_Kind`
  (Message/Term/Comment/Blank/Junk); `Entry_Node` discriminated record with
  `Source_Span`; `Count_Entries(Source) return Natural`
  (Pre `Source'Length <= 1_000_000`, Post `Result <= Max_Entries`);
  `Has_Cr_At_End_Of_Line(Source, Pos) return Boolean`.
- `Fluent.Locale` — `Max_Locale_Tag_Length = 32`; `Locale_Tag`;
  `Make_Tag(Text)` (Pre `Text'Length <= 32` and `Text'First` bounded);
  `Plural_Category` (Zero/One/Two/Few/Many/Other); `Plural_Of(Tag, N)`
  (M0: English-only `One` iff `N = ±1` else `Other`); `Tags_Equal`.
- `Fluent.Bundle` — `Max_Messages = 64`, `Max_Message_Length = 1024`
  (M0 stack-safe bounds; raised with heap design in M1/M2);
  `Message_Slot`, `Message_Table`, `Bundle(Tag, Slots, Count)`;
  `Empty_Bundle(Tag)`; `Resolve_Select(Selector, Keys, Has_Default,
  Default_Index)` (Pre `Keys'Length <= 64` and default in range; M0: default
  wins when present else `0` = render `{select}`).
- `Fluent.Resource` — `Max_Bundles = 8`; `Fallback_Chain`;
  `Empty_Chain`; `Best_Match(Chain, Tag)` (Post `Result <= Chain.Count`;
  exact tag match else first bundle else `0`).
- `Fluent.Unicode` (SPARK_Mode Off) — `To_Virtual(String)` /
  `From_Virtual(Virtual_String)` via `VSS.Strings.Conversions`.

## 2. Behavior

- Lenient entries: malformed entries become `Junk` nodes; parsing resumes at
  the next column-0 line (mirrors `fluent-rs` `fluent-syntax` posture).
- Resolution never raises: unknown message/attribute/term, missing variable,
  missing `*` default, and cycles render as locale-appropriate fallback
  (`{id}`, `{select}`, etc.) with a `Format_Error` value for inspection.
- Fallback M0: exact BCP-47 equality; M2 adds prefix fallback
  (`fr-CA → fr → en-US`) and resource loading.

## 3. Milestones

- M0: this file + contracts + Silver proof (37 checks) + repo floor.
- M1: full EBNF parser; entry/pattern/placeable coverage vs fixtures.
- M2: resolver (literals, variables `$x`, references, terms `-t`,
  `NUMBER`/`DATETIME`, select, attributes); `fluent-bundle` parity.
- M3: CLDR plural subset + `langneg`/`fallback` parity vs `Intl.*` goldens.

## 4. Non-goals (M0)

Full parser, resolver evaluation, number/date formatting, `localize`
tooling, `wit` bindings.
