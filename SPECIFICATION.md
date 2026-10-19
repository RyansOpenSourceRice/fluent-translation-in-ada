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
  `Max_Attributes_Per_Entry = 16`, `Max_Entries = 512`,
  `Max_Source_Length = 1_000_000`; `Entry_Kind`
  (Message/Term/Comment/Group_Comment/Resource_Comment/Blank/Junk);
  `Entry_Node` discriminated record with `Source_Span` and, for
  messages/terms, identifier text, raw pattern `Text_Span`
  (`First`/`Last` source indices, `0` = absent), an optional attached
  `#`-comment span, and up to 16 attributes (identifier plus value
  span); `Message_Kind`/`Comment_Kind` subtypes;
  `Count_Entries(Source) return Natural`
  (Pre `Source'Length <= 1_000_000`, Post `Result <= Max_Entries`);
  `Has_Cr_At_End_Of_Line(Source, Pos) return Boolean`;
  `Parse_Resource(Source, Entries, Count, Junk_Count)`
  (Pre source length bound, `Source'First = 1`, non-empty caller-sized
  `Entries`; Post `Count <= Entries'Length`, `Junk_Count <= Count`).
  Identifiers over 128 characters, a missing `=`, a missing value
  (terms always require one; messages require a value or at least one
  valid attribute), or an invalid attribute turns the entry into Junk.
  A single-`#` comment group directly preceding a successfully parsed
  message/term attaches to its `Attached_Comment` span. Patterns are
  raw spans in M1a: a value starts on the `=` line or on following
  lines; indented continuation lines join unless they start an
  attribute, start with `.`, `[`, or `*`, or are blank; a `{` line at
  column 0 joins the span; while brace depth is open every line joins
  except a column-0 `#` comment; string literals (with `\` escapes) do
  not affect depth and never span lines. Callers size `Entries` for the
  input; parsing stops when full.
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
- M1a: entry-level parser; entry/attribute/comment structure vs 21
  all-valid upstream fixtures (entry-kind + identifier sequences);
  18 pattern-semantic fixtures deferred with reasons, re-enabled in M1b.
- M1b: full EBNF patterns; entry/pattern/placeable coverage with full
  structural AST-vs-JSON comparison; invalid patterns become Junk;
  discontinued variant-list syntax explicitly rejected.
- M2: resolver (literals, variables `$x`, references, terms `-t`,
  `NUMBER`/`DATETIME`, select, attributes); `fluent-bundle` parity.
- M3: CLDR plural subset + `langneg`/`fallback` parity vs `Intl.*` goldens.

## 4. Non-goals (M1a)

Full pattern parsing and validation, resolver evaluation, number/date
formatting, `localize` tooling, WebAssembly interface-type bindings.
