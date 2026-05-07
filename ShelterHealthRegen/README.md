# Shelter Health Regen

Slowly heals afflictions and regenerates health while the player is inside a shelter:
- If the player has one or more afflictions*, a random healable affliction (see below) will be removed every 60 seconds.
- If the player does not have any afflictions*, the player will regenerate 0.2 HP per second.

The following afflictions will be healed:
- Bleeding
- Fracture
- Burn
- Poisoning
- Rupture
- Headshot

Any other afflictions will not be removed. Health will not regenerate until all afflictions* are removed.

\* except for overweight
