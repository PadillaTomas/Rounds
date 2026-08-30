# Localization

**English only, built the native way.** Adding a language is adding a column, no code.

## Where the copy lives

**`Rounds/Resources/Localizable.xcstrings`** — a String Catalog (Xcode 15+). Plain
JSON you can hand-edit, plus a dedicated editor in Xcode (one row per string, one
column per language, translation-state flags, comments).

Keys are explicit dotted paths (`setup.start`, `timer.roundOfTotal`). Call sites
never touch the catalog directly — they go through the typed `Copy.*` accessors in
**`Rounds/Resources/Copy.swift`**, thin `String(localized:)` calls. The reason for
the wrapper: the UIWorkouts components take plain `String`, not
`LocalizedStringKey`, so a call site has to resolve the string itself.

**Never hard-code a user-facing string in a view.** Add a key to the catalog and a
`Copy.*` accessor. (DEBUG-only developer UI is exempt — there is none yet.)

**To revise copy:** edit the `value` for the `en` localization of a key (or use
Xcode's editor). Nothing else changes.

Interpolated entries (`"Round %1$lld of %2$lld"`) carry a matching `defaultValue`
in `Copy.swift` — that English is a *fallback*; the catalog value wins at runtime.

## Adding a language

1. Open `Localizable.xcstrings` in Xcode → **+** language.
2. Fill the values (in Xcode, or export `.xcloc`, translate, import back).
3. Nothing in Swift changes — the system resolves the user's language at runtime
   and falls back to English.

## Not covered

Number / time formatting is already locale-aware (`WKTimeFormat`, `String(format:)`
for the wheel digits).
