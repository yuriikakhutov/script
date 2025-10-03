# Neutral and Controlled Unit Ability Reference

This document aggregates cast details for abilities used by dominated creeps and other controllable units.
Values are sourced from in-game tooltips, patch 7.35b data, and the GameTracking-Dota2 repository. Please double-check any entry
marked as _Needs verification_ before relying on it in automation logic.

## Data Format

| Ability | Unit(s) | Type | Cast Range / Radius | Conditions & Notes | Status |
| --- | --- | --- | --- | --- | --- |
| `mud_golem_hurl_boulder` | Mud Golem | Target (Enemy) | 800 range | 125 damage, 0.6s stun. Requires line of sight. | Confirmed |
| `ancient_rock_golem_hurl_boulder` | Ancient Rock Golem | Target (Enemy) | 950 range | 275 damage, 2s stun. 0.6s cast point; projectile speed 900. | Confirmed |
| `dark_troll_warlord_ensnare` | Dark Troll Summoner | Target (Enemy / Neutral) | 550 range | 1.75s root, works on neutrals and heroes, pierces spell immunity. | Confirmed |
| `dark_troll_warlord_raise_dead` / `dark_troll_summoner_raise_dead` | Dark Troll Summoner | No target | 400 radius corpse search | Consumes 1-2 charges to summon skeleton warriors near the caster. Casts even without nearby enemies. 2 charges, 40s replenish. | Confirmed |
| `dark_troll_priest_heal` | Dark Troll Priest | Ally target | 450 range | 15 HP/s heal over 15s (225 total). Prefer heroes under 85% HP. | Confirmed |
| `forest_troll_high_priest_heal` | Forest Troll High Priest | Ally target | 350–450 range | Instant 100 HP heal, 10/9/8/6 s CD. Keep autocast on; prioritise <90% HP heroes. | Confirmed |
| `forest_troll_berserker_envenomed_weapons` | Forest Troll Berserker | Toggle (Self) | Melee attacks apply poison | Enable before fighting; disable when idle to reduce HP drain. Costs 6 HP/s, adds 15 DPS for 3s. | Needs verification |
| `ogre_bruiser_ogre_smash` / `ogre_mauler_smash` | Ogre Bruiser / Mauler | Point leap | 350 leap range, 250 impact radius | Leap + slam that knocks up for 1s and deals 150 damage. Needs enemy within leap window. | Confirmed |
| `ogre_magi_frost_armor` | Ogre Frostmage | Ally target | 600 range | Grants +8 armor + 35 AS slow to attackers for 15s. Refresh when remaining duration <2s. | Confirmed |
| `ancient_ice_shaman_frost_armor` | Ancient Ice Shaman | Ally target | 600 range | Same frost armor as Ogre Frostmage; prefer front-line heroes and refresh under 3s remaining. | Needs verification |
| `harpy_storm_chain_lightning` | Harpy Stormcrafter | Target (Enemy) | 900 range | 140 base damage, 4 bounces within 500 range, 25% damage loss per bounce, 4 s CD. | Confirmed |
| `harpy_scout_chain_lightning` | Harpy Scout | Target (Enemy) | 600 range | Weaker chain lightning (90 base damage, 4 bounces). | Needs verification |
| `satyr_mindstealer_mana_burn` | Satyr Mindstealer | Target (Enemy Hero) | 600 range | Burns 120 mana, deals equal damage. Skip if target <75 mana. 20 s cooldown. | Confirmed |
| `satyr_soulstealer_mana_burn` | Satyr Soulstealer | Target (Enemy Hero) | 600 range | Burns 150 mana, deals equal damage. Same restrictions as Mindstealer. 20 s cooldown. | Confirmed |
| `satyr_hellcaller_shockwave` | Satyr Tormenter | Point (Enemy) | 800 travel distance, 150 width | 160 damage line nuke; cast when ≥1 enemy or neutral in path. 6 s CD, 100 mana. | Confirmed |
| `satyr_trickster_purge` | Satyr Banisher | Target (Enemy / Ally) | 600 range | Dispel + 5s 100%→0% slow. Removes buffs from enemies or debuffs from allies. 5 s cooldown. | Confirmed |
| `centaur_khan_war_stomp` | Centaur Conqueror / Khan | No target | 315 radius | 2s stun to enemies around the caster. Cast when ≥1 enemy in radius. | Confirmed |
| `polar_furbolg_ursa_warrior_thunder_clap` | Ursa Warrior | No target | 315 radius | 150 damage + 1.5s slow. Prefer ≥1 enemy in radius. | Confirmed |
| `hellbear_smasher_slam` | Hellbear Smasher | No target | 350 radius | 150 damage + 2s slow. | Confirmed |
| `ancient_thunderhide_frenzy` | Ancient Thunderhide | Ally target | 700 range | +75 attack speed, +15% move speed for 12s. 35s cooldown; prefer melee carries. | Confirmed |
| `ancient_thunderhide_slam` | Ancient Thunderhide | No target | 275 radius | 150 damage + 2s slow for 2s. 8s cooldown, only cast in melee range. | Confirmed |
| `ancient_thunderhide_roar` | Ancient Thunderhide | No target | 1200 radius | +50 attack speed +10% move speed to allies, 25s duration. Shares cooldown with Frenzy (same spell when dominated). | Confirmed |
| `ancient_thunderhide_blast` | Ancient Thunderhide (Event) | Point (Ground) | 900 range | Hurls boulder dealing 275 damage in 250 radius; appears in some event variants. | Needs verification |
| `ancient_black_dragon_fireball` / `black_dragon_fireball` | Black Dragon | Point (Ground) | 750 range, 275 radius pool | Leaves burning ground for 10s, 80 DPS. Avoid overlapping pools. | Needs verification |
| `ancient_blue_dragon_frost_breath` | Blue Dragon | Cone (Enemy) | 800 attack range cone | Applies 30% move slow for 3s. Works via auto-cast toggle. | Confirmed |
| `ancient_blue_dragon_frost_armor` | Blue Dragon | Ally target | 600 range | Same as Ogre Frost Armor: +8 armor, attack slow for 15s. Treat like single-target buff. | Needs verification |
| `enraged_wildkin_tornado` | Enraged Wildkin | Point (Ground) | 800 cast range | Spawns controllable tornado for 30s; sweep through enemies for 15 DPS + lift. Micro the tornado via sub-selection. | Needs verification |
| `enraged_wildkin_toughness_aura` | Enraged Wildkin | Aura (Passive) | 900 radius | +3 armor aura; ensure unit stays near allies. | Reference only |
| `enraged_wildkin_hurricane` | Enraged Wildkin | Point (Enemy) | 600 range pull | 2.4s channel that pulls enemies 200 units toward caster per second. Interruptible; use defensively. Cancel if target becomes spell-immune. | Needs verification |
| `enraged_wildkin_toughen` | Enraged Wildkin (Event) | Ally target | 600 range | Grants +6 armor and 10 HP regen for 15s. Appears only in Diretide/Winter events. | Needs verification |
| `alpha_wolf_howl` | Alpha Wolf | No target | 1200 radius | +30% base damage for allies for 15s. Shares cooldown with Lycan. | Confirmed |
| `giant_wolf_intimidate` | Alpha Wolf / Giant Wolf | No target | 300–500 radius | 60% enemy damage reduction for 4 s, 16 s CD, 50 mana. Use as defensive peel. | Confirmed |
| `alpha_wolf_critical_strike` | Alpha Wolf | Passive | 300 radius aura | 30% chance for 200% crit, allies within aura gain buff. Maintain proximity. | Reference only |
| `ancient_prowler_shaman_crush` | Ancient Prowler Shaman | No target | 275 radius | 200 damage + 2s root. Requires enemy in melee range. | Confirmed |
| `ancient_prowler_shaman_fertile_ground` | Ancient Prowler Shaman | Point (Ground) | 400 range | Places trap that roots after 2s; combo with Crush. 12 s cooldown, 50 mana. | Confirmed |
| `ancient_prowler_shaman_overgrowth` | Ancient Prowler Shaman | No target | 600 radius | 3s root + 100 DPS over duration. Long cooldown (45s); confirm availability in neutral kit. | Needs verification |
| `fel_beast_haunt` | Fel Beast | Target (Enemy) | 600 range | 3 s haunt slow, projectile 500 speed; CD 15/13/11/7 s, 75 mana. Stack on kiting targets. | Confirmed |
| `ice_shaman_incendiary_bomb` | Ancient Ice Shaman | Target (Enemy / Building) | 700–800 range | 50 DPS burn for 8 s, affects buildings for 25% damage. 30 s CD, 80–100 mana. | Confirmed |
| `ghost_frost_attack` | Ghost | Target (Enemy) | 600 range | Auto-cast orb that slows attack and move speed by 30% for 4s. | Confirmed |
| `ghost_invisibility` | Ghost | No target | Self invisibility | Grants permanent invisibility after 1.5s fade; break on attack. | Reference only |
| `troll_priest_heal` | Hill Troll Priest | Ally target | 600 range | 25 HP/s heal over 10s (250 total). Prefer lowest-health hero. | Needs verification |
| `kobold_taskmaster_speed_aura` | Kobold Taskmaster | Aura (Passive) | 900 radius | +12% move speed to allies. Keep near melee units. | Reference only |
| `granite_golem_hp_aura` | Ancient Rock Golem | Aura (Passive) | 1200 radius | +15% max HP aura for allies. Maintain proximity to team. | Reference only |
| `tiny_golem_rock_throw` | Shard Mud Golem | Target (Enemy) | 700 range | 100 damage, 0.3s stun. Spawns after Mud Golem death. | Confirmed |
| `tiny_golem_hurl_boulder` | Shard Mud Golem (Ancient) | Target (Enemy) | 800 range | 150 damage, 0.4s stun. Appears in camps with ancient shards. | Needs verification |
| `warpine_raider_seed_shot` | Warpine Raider | Target (Enemy) | 575 range | 100 damage seed that bounces 4–12 times within 500 range, 100% slow for 1 s on each hit. 15 s CD, 100 mana. | Confirmed |
| `neutral_spell_tombstone_zombie` | Tombstone (Neutral Event) | Point (Ground) | 600 range | Summons zombies periodically; treat as high-threat objective. | Needs verification |
| `neutral_spell_thunderhide_stampede` | Event Thunderhide | No target | 900 radius | Grants allies 20% move speed and 20% attack speed for 8s. Appears in jungle events. | Confirmed |
| `ancient_rumblehide_shockwave` | Rumblehide (Diretide) | Point (Enemy) | 900 travel distance | 220 damage line wave; treat similar to Satyr Shockwave. | Needs verification |
| `ancient_rumblehide_bellow` | Rumblehide (Diretide) | No target | 600 radius | +60 attack speed, +12 armor to allies for 12s. Shares charges with Frenzy variants. | Needs verification |
| `primal_satyr_thunderstrike` | Primal Satyr (Event) | No target | 500 radius | 200 magical damage + 1.5s stun. 18 s cooldown. | Needs verification |
| `granite_golem_bash` | Ancient Rock Golem | Passive proc | 25% chance, 1.5s stun | Works on attacks; no action required but note for threat evaluation. | Reference only |
| `neutral_spell_primal_beast_pulverize` | Primal Beast (Event) | Channel (Enemy) | 250 grab radius | 2.3s channel dealing 45 DPS + slam damage. Must stay in melee range. | Needs verification |
| `neutral_warpine_snare` | Warpine Raider | Point (Ground) | 400 range | Plants a trap that roots for 2.5s after 1s arming time. Use defensively. | Needs verification |
| `neutral_warpine_overgrowth` | Warpine Raider | No target | 450 radius | 2s root + 80 DPS. Appears in Aghanim events only. | Needs verification |
| `neutral_stone_form` | Granite Golem (Event) | No target | Self | Gains 50% damage reduction and pulses 80 damage for 6s. 30s cooldown. | Needs verification |

### Additional Neutral Spells Requiring Data

- `warpine_raider_root`: determine if ability still exists or was folded into Seed Shot in current patch.
- `neutral_centaur_enrage`: confirm duration and bonus damage values for Centaur camp enrages.
- `neutral_golem_shield`: investigate if neutral shield golems retain activatable barrier skills in seasonal events.
- `dark_troll_priest_weaken`: gather data on armor-reduction debuff applied via auto attacks.
- `primal_satyr_thunderstrike`: confirm damage scaling between event waves and whether stun pierces spell immunity.
- `neutral_warpine_overgrowth`: capture exact damage ticks and root duration for Aghanim variants.
- `ancient_rumblehide_bellow`: verify buff values against Diretide patch notes and in-game tooltips.

## Hero Control Notes

These hero abilities are relevant when the player dominates or temporarily controls an enemy hero.

| Ability | Hero | Type | Cast Range / Radius | Conditions & Notes | Status |
| --- | --- | --- | --- | --- | --- |
| `axe_berserkers_call` | Axe | No target | 300 radius | Taunts enemies for 2.4–3.2s, grants 30 bonus armor. Step into melee before casting. | Confirmed |
| `axe_battle_hunger` | Axe | Target (Enemy) | 700 range | 16 DPS + slow until target kills unit or duration ends. Avoid recasting on already affected enemies. | Confirmed |
| `axe_culling_blade` | Axe | Target (Enemy) | 150 melee range | Execute below threshold HP (275/325/375 + bonuses). Grants movement speed on kill. | Confirmed |
| `centaur_double_edge` | Centaur Warrunner | No target | 190 radius | 300/400/500 damage, self-damage reduced by 50%. Step into melee before casting. | Confirmed |
| `centaur_hoof_stomp` | Centaur Warrunner | No target | 315 radius | 2/2.5/3s stun with 100/150/200 damage. Requires close range. | Confirmed |
| `legion_commander_duel` | Legion Commander | Target (Enemy) | 150 melee range | 4/4.5/5s duel; ensure allies nearby. Cast when target HP <50% ideally. | Confirmed |
| `legion_commander_press_the_attack` | Legion Commander | Ally target | 700 range | Purges debuffs, grants 65/85/105 AS and regen for 5s. Prioritize stunned allies. | Confirmed |
| `lich_frost_shield` | Lich | Ally target | 600 range | Reduces physical damage by 60% and damages attackers. | Confirmed |
| `shadow_shaman_shackles` | Shadow Shaman | Target (Enemy) | 400 range | Channel 2.75s disable. Interruptible; ensure safety before casting. | Confirmed |
| `centaur_stampede` | Centaur Warrunner | Global | Global | Grants 550 move speed + unit-walk for 4s; deals 100/150/200 damage on contact. Use for engages or saves. | Needs verification |
| `lich_sinister_gaze` | Lich | Channel (Enemy) | 550 range | Channel up to 2.5s dragging enemy towards Lich, draining mana. Cancel if danger. | Needs verification |
| `shadow_shaman_voodoo` | Shadow Shaman | Target (Enemy) | 500 range | Hex for 1.25/2/2.75s; no channel. Use before Shackles. | Needs verification |

## Pending Research

The following units still need detailed breakdowns:

- Ancient Thunderhide: verify Roar buff stacking and event-only Blast behaviour
- Alpha Wolf: monitor aura radius changes in future patches
- Enraged Wildkin: tornado micro timing and DPS confirmation
- Kobold Foreman / Vhoul Assassin: check if any active skills remain after reworks
- Neutral event units (e.g., Harpy Overlord, Warpine Raider) require spawn-conditional handling
- Siege units (Trebuchet, Catapult) and tormentors for potential automation hooks
- Dark Troll Priest: confirm Weaken armour reduction values for documentation

Document findings here before wiring automation logic so the main script can consume a clean dataset.
