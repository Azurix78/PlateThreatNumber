# PlateThreatNumber

A standalone addon for **WoW Forever**, interface **16001**. Displays your threat
lead or deficit to the right of Blizzard nameplates, compared with the highest
threat of another party or raid member, including pets.

## Installation

1. Close WoW.
2. Extract the distribution ZIP into:
   `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Check that the folder structure is:
   `Interface/AddOns/PlateThreatNumber/PlateThreatNumber.toc`.
4. Enable **PlateThreatNumber** in the addon list and log in.
5. Type **`/ptn`** to open the native game settings panel.

To install from source, copy the `.lua` files, the `.toc` file and this README
into the `PlateThreatNumber` folder. The `tests`, `scripts`, `.tools` and `dist`
folders are not needed in game. No external addon libraries are required.
The addon does not change game settings: enemy nameplates must already be enabled.

### One-click deployment on Windows

Double-click **`Deploy.cmd`** in the project folder to deploy the current source
files to:

```text
C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\PlateThreatNumber
```

The launcher works regardless of your current working directory and keeps its
window open so you can see the result. If Windows denies write access,
right-click `Deploy.cmd` and select **Run as administrator**.

Deployment copies only the TOC, README and files listed in the TOC. It overwrites
those addon files without deleting other files or touching saved settings.
Development tools, tests and ZIP archives are excluded. Restart WoW after the
first installation; use `/reload` after updating an already loaded addon.

To preview deployment or use a different AddOns folder, run PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -AddOnsPath 'D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns'
```

## Display

`Difference = your rawThreat - the highest rawThreat of another participant`

Example: `1116 - 1000 = +116`. Values use the API's native units, without dividing
by 100 or converting to a percentage. The difference is rounded to the nearest
integer, with halfway values rounded away from zero. The sign and color follow
the displayed integer.

| Displayed difference | Tank | DPS / healer |
| --- | --- | --- |
| Positive | Green | Red |
| Zero or negative | Red | Green |

- You must be alive, in combat and present on the threat table of a living,
  attackable NPC that is in combat and has a visible nameplate.
- Other participants are party or raid members and their pets, including your
  own pet. Players outside your group and summons without an accessible pet
  unit token are not tracked.
- Nothing is displayed unless another living, connected participant has
  strictly positive threat. Your own pet can therefore enable the display
  while playing solo.
- Pet threat is not combined with its owner's threat.
- A raw threat lead does not guarantee that you hold aggro: aggro thresholds,
  taunts and special encounter mechanics are not represented.
- A restricted or invalid value, or a read error, hides the number. If the API
  reports no participation for a particular unit, only that unit is excluded.
  Restricted threat data is never treated as zero threat.

## Settings

`/ptn` opens **Options > AddOns > PlateThreatNumber**.

| Setting | Default |
| --- | --- |
| Enabled | On |
| Debug / solo test | Off |
| Role | Automatic |
| Text size | 16 |
| Horizontal / vertical offset | 0 / 0 |

Automatic mode uses your assigned group role. If no role is assigned, it uses
the DPS / healer colors. You can override this with **Tank** or **DPS / healer**.
The role is saved per character; other settings are shared across characters.
The text uses the native font with an outline and an initial 8-pixel gap beyond
the right edge of the nameplate and its level indicator. Position offsets are
added to this gap.

Supported locales: English (US/GB), French, German, Spanish (ES/MX), Italian,
Brazilian Portuguese, Russian, Korean, Simplified Chinese and Traditional
Chinese. Unknown locales fall back to English.

## Debugging and solo testing

Enable **Debug / solo test** in `/ptn`, or type `/ptn debug on`.
Fight an enemy while you are not in a party or raid. If you have a readable
threat entry and no rival has positive threat, the addon shows your own threat
with an asterisk, for example **`+116*`**. With a pet or group rival, the normal
threat difference is used. The asterisk is a diagnostic indicator, not an aggro
margin against another participant.

Debug mode still requires combat and an eligible enemy. It does not bypass
restricted data, invent threat values or read threat outside combat. Use
`/ptn debug off` to restore normal behavior; `/ptn debug` toggles the option.
The setting is saved and is off by default.

Use **`/ptn status`** during or after a test to print a local chat report:

- Version, enabled/combat/debug flags, visible and tracked nameplate counts,
  received threat events and refresh counts since debug was enabled or reloaded.
- The last display or blocking reason for each tracked token: no player threat,
  no rival, client-restricted data, invalid data, API failure, combat filter,
  unavailable frame or hidden health bar.
- A unit token and API name where relevant, such as
  `[party1/UnitDetailedThreatSituation.rawThreat]`. `[ANCHOR_FALLBACK]` means the display
  uses direct anchoring because exact nameplate coordinates were unavailable.

If a death or filter event replaces a combat result, the previous combat result
is also included. Results remain available after combat and nameplate removal.
Only the latest 40 nameplate tokens are kept in memory; a reused token starts a
new record. Turning debug off or reloading clears the report. The command reads
recorded results and does not perform extra threat scans. It never logs secret
values, raw API error messages or player names, and does not broadcast anything.

If no number appears, run `/ptn status` after testing with debug enabled and
include its output in a bug report. Zero tracked plates points to frame setup;
zero threat events during a fight points to event delivery; a restricted-data
reason identifies a client limitation rather than a display error.

Since version 1.0.2, a readable `rawThreat` value is used even if the API's aggro
status is protected, because that status is not needed for the subtraction.
A restricted-data report ending in `.rawThreat` specifically means that the
number needed for the calculation is protected. In that situation this addon
cannot calculate the threat difference, and solo debug does not remove that
restriction. A 1.0.1 report without the field suffix could mean that either the
status or the numeric threat was protected.

## Performance and compatibility

Nameplate tracking is event-driven. Threat events batch updates over 200 ms.
Only nameplates marked for refresh are recalculated; a roster change or a member
event that does not identify an enemy may mark all visible nameplates for
refresh. Ordinary health changes do not trigger threat reads; deaths trigger
a display update.

No threat values are read outside combat or while the addon is disabled. There
is no `OnUpdate` handler, combat log processing, addon network messaging or
world-wide unit scanning. The one-shot timer is cancelled when combat ends.
Text elements are reused when nameplates are recycled.

The addon adds its own text and runs hooks after Blizzard functions. It does
not modify names, name colors or faction icons, and is designed to coexist with
**PlateFaction**. Full nameplate replacement addons are not supported in this
version.

Version 1.0.1 adds a direct-anchor fallback when exact frame coordinates are
unavailable, and retries tracking when Blizzard finishes assigning a nameplate
unit. These address reproducible suppression cases in the simulated tests;
they do not establish which condition caused a particular live dungeon failure.

## Validation status

- Local client build identified during development: **1.60.1.70124**.
- A user test of `UnitDetailedThreatSituation("player", "target")` returned a
  numeric value. This does not establish access to other players' threat or
  untargeted nameplates in every combat context.
- Automated Lua 5.1 tests with simulated WoW APIs cover calculations, colors,
  filtering, restrictions, events, frame reuse, settings and translations.
- **Live rendering, group threat access in dungeons and visual coexistence with
  PlateFaction still require in-game validation.** Simulated tests cannot
  validate a real client's security restrictions, rendering or event behavior.

### In-game verification

1. With PlateFaction enabled, open `/ptn` and check the labels and settings.
2. Outside combat: no number. Solo without a pet: no number with debug disabled;
   with debug enabled, readable personal threat should appear with `*` in combat.
3. In a group, attack an enemy with another player. Test a threat lead, a deficit
   and a manual role change. Check the colors against the table above.
4. Fight multiple enemies. Check targeted and untargeted nameplates, as well as
   a nearby enemy fighting only another group.
5. Let a pet take aggro, then dismiss it. Test a death, a member leaving the
   group and a change to your assigned group role.
6. Move away and return to recycle nameplates. No old number should appear on
   a different unit. Check spacing after the level indicator and ensure the
   text does not overlap PlateFaction's display.
7. Repeat in a dungeon and, if possible, a raid. Restricted values should hide
   the number without causing Lua errors.
8. Leave combat: the number should disappear immediately. Use `/reload`, then
   log out and back in to check settings persistence. Check BugSack for errors
   if that addon is enabled.

Optional diagnostic command for your selected target during combat:

```lua
/run local _,_,_,_,v=UnitDetailedThreatSituation("player","target"); if issecretvalue and issecretvalue(v) then print("PTN: secret") else print("PTN:",type(v),v) end
```

## Development

Python and the `lupa` package are required only for running the tests:

```text
python -m pip install --target .tools/lua lupa==2.8
python tests/run.py
python scripts/package.py
```

The tests use Lupa's **Lua 5.1** runtime and load the same files as the game
client, including the settings panel. The packaging script creates
`dist/PlateThreatNumber-1.0.2.zip`, containing only the addon distribution files.
