# Neutral and Controlled Unit Ability Reference

This document aggregates cast details for abilities used by dominated creeps and other controllable units.
Values are sourced from in-game tooltips, patch 7.35b data, and the GameTracking-Dota2 repository. Please double-check any entry
marked as _Needs verification_ before relying on it in automation logic.

## Data Format

| Ability | Unit(s) | Type | Cast Range / Radius | Conditions & Notes | Status |
| --- | --- | --- | --- | --- | --- |
| `mud_golem_hurl_boulder` | Mud Golem | Target (Enemy) | 800 range | 125 damage, 0.6s stun. Requires line of sight. | Confirmed |
| `ancient_rock_golem_hurl_boulder` | Ancient Rock Golem | Target (Enemy) | 950 range | 275 damage, 2s stun. Longer cast point than basic golem. | Needs verification |
| `dark_troll_warlord_ensnare` | Dark Troll Summoner | Target (Enemy / Neutral) | 550 range | 1.75s root, works on neutrals and heroes, pierces spell immunity. | Confirmed |
| `dark_troll_warlord_raise_dead` / `dark_troll_summoner_raise_dead` | Dark Troll Summoner | No target | 400 radius corpse search | Consumes 1-2 charges to summon skeleton warriors near the caster. Casts even without nearby enemies. | Confirmed |
| `dark_troll_priest_heal` | Dark Troll Priest | Ally target | 450 range | 15 HP/s heal over 15s (225 total). Prefer heroes under 85% HP. | Needs verification |
| `forest_troll_high_priest_heal` | Forest Troll High Priest | Ally target | 450 range | 30 HP/s heal over 15s (450 total). Prioritise heroes <90% HP; avoid overheal. | Needs verification |
| `forest_troll_berserker_envenomed_weapons` | Forest Troll Berserker | Toggle (Self) | Melee attacks apply poison | Enable before fighting; disable when idle to reduce HP drain. | Needs verification |
| `ogre_bruiser_ogre_smash` / `ogre_mauler_smash` | Ogre Bruiser / Mauler | Point leap | 350 leap range, 250 impact radius | Leap + slam that knocks up for 1s and deals 150 damage. Needs enemy within leap window. | Confirmed |
| `ogre_magi_frost_armor` | Ogre Frostmage | Ally target | 600 range | Grants +8 armor + attack slow for 15s. Refresh when remaining duration <2s. | Needs verification |
| `harpy_storm_chain_lightning` | Harpy Stormcrafter | Target (Enemy) | 700 range | Bounces 4 times, 140 damage first hit, 35% damage falloff. | Needs verification |
| `harpy_scout_chain_lightning` | Harpy Scout | Target (Enemy) | 600 range | Weaker chain lightning (90 base damage, 4 bounces). | Needs verification |
| `satyr_mindstealer_mana_burn` | Satyr Mindstealer | Target (Enemy Hero) | 600 range | Burns 120 mana, deals equal damage. Skip if target <75 mana. | Needs verification |
| `satyr_soulstealer_mana_burn` | Satyr Soulstealer | Target (Enemy Hero) | 600 range | Burns 150 mana, deals equal damage. Same restrictions as Mindstealer. | Needs verification |
| `satyr_hellcaller_shockwave` | Satyr Tormenter | Point (Enemy) | 800 travel distance, 150 width | 160 damage line nuke; aim when ≥1 enemy in path. | Needs verification |
| `satyr_trickster_purge` | Satyr Banisher | Target (Enemy / Ally) | 600 range | Dispel + 5s 100%→0% slow. Removes buffs from enemies or debuffs from allies. | Needs verification |
| `centaur_khan_war_stomp` | Centaur Conqueror / Khan | No target | 315 radius | 2s stun to enemies around the caster. Cast when ≥1 enemy in radius. | Confirmed |
| `polar_furbolg_ursa_warrior_thunder_clap` | Ursa Warrior | No target | 315 radius | 150 damage + 1.5s slow. Prefer ≥1 enemy in radius. | Confirmed |
| `hellbear_smasher_slam` | Hellbear Smasher | No target | 350 radius | 150 damage + 2s slow. | Confirmed |
| `ancient_thunderhide_frenzy` | Ancient Thunderhide | Ally target | 700 range | +75 attack speed, +10% move speed for 12s. Use on strongest melee core. | Needs verification |
| `ancient_thunderhide_slam` | Ancient Thunderhide | No target | 275 radius | 150 damage + 2s slow for 2s. Only cast in melee range. | Needs verification |
| `ancient_black_dragon_fireball` / `black_dragon_fireball` | Black Dragon | Point (Ground) | 750 range, 275 radius pool | Leaves burning ground for 10s, 80 DPS. Avoid overlapping pools. | Needs verification |
| `ancient_blue_dragon_frost_breath` | Blue Dragon | Cone (Enemy) | 800 attack range cone | Applies 30% move slow for 3s. Works via auto-cast toggle. | Needs verification |
| `enraged_wildkin_tornado` | Enraged Wildkin | Point (Ground) | 800 cast range | Spawns controllable tornado for 30s; sweep through enemies for 15 DPS + lift. | Needs verification |
| `enraged_wildkin_toughness_aura` | Enraged Wildkin | Aura (Passive) | 900 radius | +3 armor aura; ensure unit stays near allies. | Reference only |
| `alpha_wolf_howl` | Alpha Wolf | No target | 1200 radius | +30% base damage for allies for 15s. Shares cooldown with Lycan. | Needs verification |
| `ancient_prowler_shaman_crush` | Ancient Prowler Shaman | No target | 275 radius | 200 damage + 2s root. Requires enemy in melee range. | Needs verification |
| `ancient_prowler_shaman_fertile_ground` | Ancient Prowler Shaman | Point (Ground) | 400 range | Places trap that roots after 2s; combo with Crush. | Needs verification |
| `ghost_frost_attack` | Ghost | Target (Enemy) | 600 range | Auto-cast orb that slows attack and move speed by 30% for 4s. | Needs verification |
| `troll_priest_heal` | Hill Troll Priest | Ally target | 600 range | 25 HP/s heal over 10s (250 total). Prefer lowest-health hero. | Needs verification |
| `kobold_taskmaster_speed_aura` | Kobold Taskmaster | Aura (Passive) | 900 radius | +12% move speed to allies. Keep near melee units. | Reference only |
| `granite_golem_hp_aura` | Ancient Rock Golem | Aura (Passive) | 1200 radius | +15% max HP aura for allies. Maintain proximity to team. | Reference only |
| `tiny_golem_rock_throw` | Shard Mud Golem | Target (Enemy) | 700 range | 100 damage, 0.3s stun. Spawns after Mud Golem death. | Needs verification |
| `warpine_raider_seed_shot` | Warpine Raider | Point (Ground) | 600 range | 1.2s delay projectile; deals 200 damage + 40% slow for 2s. | Needs verification |
| `neutral_spell_tombstone_zombie` | Tombstone (Neutral Event) | Point (Ground) | 600 range | Summons zombies periodically; treat as high-threat objective. | Needs verification |

## Hero Control Notes

These hero abilities are relevant when the player dominates or temporarily controls an enemy hero.

| Ability | Hero | Type | Cast Range / Radius | Conditions & Notes | Status |
| --- | --- | --- | --- | --- | --- |
| `axe_berserkers_call` | Axe | No target | 300 radius | Taunts enemies for 2.4–3.2s, grants 30 bonus armor. Step into melee before casting. | Needs verification |
| `axe_battle_hunger` | Axe | Target (Enemy) | 700 range | 16 DPS + slow until target kills unit or duration ends. Avoid recasting on already affected enemies. | Needs verification |
| `axe_culling_blade` | Axe | Target (Enemy) | 150 melee range | Execute below threshold HP (275/325/375 + bonuses). Grants movement speed on kill. | Needs verification |
| `lich_frost_shield` | Lich | Ally target | 600 range | Reduces physical damage by 60% and damages attackers. | Needs verification |
| `shadow_shaman_shackles` | Shadow Shaman | Target (Enemy) | 400 range | Channel 2.75s disable. Interruptible; ensure safety before casting. | Needs verification |

## Pending Research

The following units still need detailed breakdowns:

- Ancient Thunderhide: confirm Frenzy/Slam numbers and cooldowns in 7.35b
- Alpha Wolf: verify Howl availability on neutral variant in current patch
- Enraged Wildkin: tornado micro timing and DPS confirmation
- Kobold Foreman / Vhoul Assassin: check if any active skills remain after reworks
- Neutral event units (e.g., Harpy Overlord, Warpine Raider) require spawn-conditional handling
- Siege units (Trebuchet, Catapult) and tormentors for potential automation hooks

Document findings here before wiring automation logic so the main script can consume a clean dataset.
