# Neutral and Controlled Unit Ability Reference

This document aggregates cast details for abilities used by dominated creeps and other controllable units.  
Values are sourced from in-game tooltips, patch 7.35b data, and the GameTracking-Dota2 repository. Please double-check any entry marked as _Needs verification_ before relying on it in automation logic.

## Data Format

| Ability | Unit(s) | Type | Cast Range / Radius | Conditions & Notes | Status |
| --- | --- | --- | --- | --- | --- |
| `mud_golem_hurl_boulder` | Mud Golem | Target (Enemy) | 800 range | 125 damage, 0.6s stun. Requires line of sight. | Confirmed |
| `ancient_rock_golem_hurl_boulder` | Ancient Rock Golem | Target (Enemy) | 950 range | 275 damage, 2s stun. Longer cast point than basic golem. | Needs verification |
| `dark_troll_warlord_ensnare` | Dark Troll Summoner | Target (Enemy / Neutral) | 550 range | 1.75s root, works on neutrals and heroes, pierces spell immunity. | Confirmed |
| `dark_troll_warlord_raise_dead` / `dark_troll_summoner_raise_dead` | Dark Troll Summoner | No target | 400 radius corpse search | Consumes 1-2 charges to summon skeleton warriors near the caster. Casts even without nearby enemies. | Confirmed |
| `ogre_bruiser_ogre_smash` | Ogre Bruiser / Mauler | Point leap | 350 leap range, 250 impact radius | Leap + slam that knocks up for 1s and deals 150 damage. Requires enemy within leap window. | Needs verification |
| `forest_troll_high_priest_heal` | Forest Troll High Priest | Ally target | 450 range | Heals 180 HP over time, prefers heroes below 90% HP. | Needs verification |
| `harpy_storm_chain_lightning` | Harpy Stormcrafter | Target (Enemy) | 700 range | Bounces 4 times, 140 damage first hit, 35% damage falloff. | Needs verification |
| `satyr_mindstealer_mana_burn` | Satyr Mindstealer | Target (Enemy Hero) | 600 range | Burns 120 mana, deals equal damage. Won't cast on low-mana targets (<75 mana). | Needs verification |
| `satyr_soulstealer_mana_burn` | Satyr Soulstealer | Target (Enemy Hero) | 600 range | Burns 150 mana, deals equal damage. Same restrictions as Mindstealer. | Needs verification |
| `satyr_hellcaller_shockwave` | Satyr Tormenter | Point (Enemy) | 800 travel distance | 160 damage line nuke, 150 width. Prefer enemies not adjacent to allies. | Needs verification |
| `centaur_khan_war_stomp` | Centaur Courser / Khan | No target | 315 radius | 2s stun to enemies around the caster. Best when ≥1 enemy in radius. | Confirmed |
| `polar_furbolg_ursa_warrior_thunder_clap` | Ursa Warrior | No target | 315 radius | 150 damage + 1.5s slow. Prefer ≥1 enemy in radius. | Confirmed |
| `hellbear_smasher_slam` | Hellbear Smasher | No target | 350 radius | 150 damage + 2s slow. | Confirmed |
| `black_dragon_fireball` / `ancient_black_dragon_fireball` | Black Dragon | Point (Ground) | 750 cast range, 275 radius pool | Leaves burning ground for 10s, 80 DPS. Avoid stacking pools on same spot. | Needs verification |
| `ogre_magi_frost_armor` | Ogre Frostmage | Ally target | 600 range | Grants 8 armor + attack slow. Refresh if about to expire (<2s). | Needs verification |
| `forest_troll_berserker_envenomed_weapons` | Forest Troll Berserker | Toggle (Self) | Melee range attacks apply poison | Enable when approaching combat; disable out of combat to save HP regen. | Needs verification |
| `harpy_scout_chain_lightning` | Harpy Scout | Target (Enemy) | 600 range | Weaker version of chain lightning (90 damage). | Needs verification |

## Pending Research

The following units still need detailed breakdowns:

- Ancient Thunderhide (Frenzy, Slam)
- Alpha Wolf (Howl, Critical Strike aura interactions)
- Enraged Wildkin (Tornado)
- Satyr Banisher (Purge)
- Kobold Taskmaster (Speed Aura usage considerations)
- Hill Troll Priest (Heal, Mana Aura)
- Mud Golem split mechanics (Shard golems post-death)

Document findings here before wiring automation logic so the main script can consume a clean dataset.
