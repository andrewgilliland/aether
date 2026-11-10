## Every number that decides how the game feels, in one place.
extends RefCounted

## Hero walking speed, pixels per second.
const HERO_WALK_SPEED := 72.0

## Hero health when unhurt.
const HERO_HEALTH := 50
## Length of the Mercy Window after the Hero is struck.
const MERCY_SECONDS := 1.0
## How long the Hero lies Fallen before he Respawns.
const HERO_FALLEN_SECONDS := 1.5

## Loudness of the music, in decibels below full.
const MUSIC_VOLUME_DB := -18.0
## How much higher an empty-gauge Swing sounds than a Full-Strength one.
const WEAK_SWING_PITCH := 1.5

## How long a Transition takes to fade out, and again to fade in.
const TRANSITION_FADE_SECONDS := 0.25

## Knockback, for the Hero and for Enemies alike: how fast and for how long.
const KNOCKBACK_SPEED := 150.0
const KNOCKBACK_SECONDS := 0.15

## Puffhop health when unhurt, and the Contact Damage it deals.
const PUFFHOP_HEALTH := 25
const PUFFHOP_CONTACT_DAMAGE := 5
## A Puffhop notices the Hero within the first distance and gives up the
## chase beyond the second, in pixels (5 and 8 tiles).
const PUFFHOP_NOTICE_DISTANCE := 80.0
const PUFFHOP_GIVE_UP_DISTANCE := 128.0
## How long a struck Puffhop is Stunned.
const PUFFHOP_STUN_SECONDS := 0.4
## One hop: seconds in the air, how high it looks, and speed over the ground
## when chasing and when wandering.
const PUFFHOP_HOP_SECONDS := 0.35
const PUFFHOP_HOP_HEIGHT := 6.0
const PUFFHOP_CHASE_SPEED := 70.0
const PUFFHOP_WANDER_SPEED := 36.0
## Rest on the ground between hops: fixed when chasing, random when wandering.
const PUFFHOP_CHASE_REST_SECONDS := 0.45
const PUFFHOP_WANDER_REST_MIN_SECONDS := 0.8
const PUFFHOP_WANDER_REST_MAX_SECONDS := 2.2

## Seconds for the Recharge Gauge to climb from 0% to 100%.
const RECHARGE_SECONDS := 1.5
## Damage of a Full-Strength Swing.
const FULL_STRENGTH_DAMAGE := 10
## The least a Swing can do, however empty the Recharge Gauge.
const MINIMUM_SWING_DAMAGE := 1

## How long a Swing roots the Hero, start to finish.
const SWING_SECONDS := 0.3
## How far into a Swing the blade starts to land.
const SWING_WINDUP_SECONDS := 0.1
## The area a Swing lands in, for a Swing to the right: how far ahead of the
## Hero its centre is, how deep it is along the Swing, and how wide across.
const SWING_REACH_AHEAD := 14.0
const SWING_REACH_DEPTH := 20.0
const SWING_REACH_WIDTH := 30.0
