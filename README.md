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
2. Outside combat: no number. Solo without a pet: no number.
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
`dist/PlateThreatNumber-1.0.0.zip`, containing only the addon distribution files.
