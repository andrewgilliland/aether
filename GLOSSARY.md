# Aether

A solo, top-down action RPG in the visual tradition of 16-bit SNES games, set in a hand-made world the player may explore in any order.

## Language

### World

**World**:
The whole explorable space of the game, made up of Zones joined at their Entrances.
_Avoid_: Map, overworld, level

**Zone**:
One hand-made, self-contained area of the World, larger than the screen, that the Hero occupies at a time.
_Avoid_: Level, room, screen, area, map, scene

**Entrance**:
A place on a Zone's boundary where the Hero arrives from, or leaves to, a neighbouring Zone.
_Avoid_: Exit, door, portal, warp, spawn point

**Start**:
The place in the first Zone where the Hero stands when the game begins; it stands in for an Entrance until he has come through one.
_Avoid_: Spawn point, origin

**Thicket**:
Dense, impassable undergrowth that bounds a Zone and divides it into ways through.
_Avoid_: Wall, forest border, bushes

**Forest Clearing**:
The first Zone: open grass beside a river, with a path east over a bridge.

**Deep Woods**:
The second Zone, east of the Forest Clearing: a path winding through Thicket to a glade.

**Transition**:
The Hero's passage from one Zone to a neighbouring Zone through a pair of matching Entrances.
_Avoid_: Load, warp, teleport

### Characters

**Hero**:
The single player-controlled character: a sword-wielding human man.
_Avoid_: Player, protagonist, character, avatar

**Facing**:
Which of four directions (down, up, left, right) a character looks toward; movement is free, Facing is not.
_Avoid_: Direction, orientation, heading

**Enemy**:
A hostile creature that lives in a Zone and can harm, and be harmed by, the Hero.
_Avoid_: Monster, mob, NPC

**Puffhop**:
A kind of Enemy: a round, yellow-furred, long-eared creature that moves by hopping.
_Avoid_: Rabite, bunny, slime, blob

### Combat

**Swing**:
One committed sword attack in the direction the Hero is facing.
_Avoid_: Attack, slash, strike, hit

**Recharge Gauge**:
The Hero's readiness to Swing, from 0% just after a Swing up to 100%; a Swing's strength is proportional to it.
_Avoid_: Stamina, cooldown, power meter, charge

**Full-Strength Swing**:
A Swing made while the Recharge Gauge is at 100%.
_Avoid_: Charged attack, full hit

**Knockback**:
The shove away from the attacker that a struck Enemy or Hero suffers.

**Health**:
How much more harm the Hero or an Enemy can take before he is Fallen or it is Defeated.
_Avoid_: HP, hit points, life, lives

**Stun**:
The short period after an Enemy is struck by a Swing during which it cannot move or deal Contact Damage.
_Avoid_: Stagger, hitstun, freeze

**Defeated**:
What an Enemy is once its Health runs out; it is gone until its Zone is next entered.
_Avoid_: Killed, dead, destroyed

**Fallen**:
What the Hero is from the moment his Health runs out until his Respawn.
_Avoid_: Dead, killed, game over, knocked out

**Contact Damage**:
Harm the Hero takes from touching an Enemy.
_Avoid_: Touch damage, collision damage

**Mercy Window**:
The short period after the Hero is struck during which he cannot be harmed again.
_Avoid_: Invincibility frames, i-frames, invulnerability

**Respawn**:
The Fallen Hero's return, at full Health, to the Entrance through which he entered the current Zone; the Zone's Enemies return with him.
_Avoid_: Game over, revive, continue
