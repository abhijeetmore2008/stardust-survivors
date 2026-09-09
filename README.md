# Signal Radius

You walk a dirt path at dusk with a lamp that isn't really a lamp. It's a cone of radio. Whatever sits in that cone can hear you, and most of it would rather you stopped talking.

Twenty roads. Pick a kit, light the lanterns as you go, and hold the beam on the gate long enough for the lock to take. Bushes lie. Giants sit on the arch until you put their heart in the signal. If you go dark, that's the run.

Godot 4.7. Open `project.godot` and press Play. First launch may sit a few seconds importing textures.

## How it actually plays

WASD to walk, mouse to aim. The cone is always on; you are not waiting for a cooldown to see.

| | |
|---|---|
| Click / Space | fire |
| Hold F | broadcast. drains battery. ticks whatever is in the cone, lights nearby lamps, pops hidden bushes |
| Tap F | spend 1 combo to ping bushes. at 8 combo, tap F again for a 7s overcharge |
| Shift or Q | dash |
| Right-click | throw a spark (light puddle, ~6.5s cooldown) |
| G | plant a signal puck. costs 3 motes |
| E at a waystone | rewind to the last lamp you lit. hold E to drop a turret. both cost 4 combo, once per road |

Broadcast while standing near a cold lantern or it stays cold. The gate wants the beam swept across the arch, not a glance. If a Giant is up, the lock won't start until its heart is in the cone.

Road 1 talks you through this if you haven't cleared an arch before. After that it stays out of the way.

## Kits

You pick one at the title (two, if you bought Second kit at the Outpost). Each has a broadcast pair that only shows up while F is down.

- **Pulse Rifle** — steady cyan bolts. Resonance: the rifle keeps firing cone targets for you.
- **Shard Bow** — slow glass, punches through. Glass Echo: a pierce line off the far edge of the cone.
- **Ember Scatter** — five-ember face-shot. Floodlight: huge cone, weaker tick. moths notice.
- **Coil Lance** — a bolt that curves toward anything the cone has already painted.

## A road

Meadow is the kind one. After you lock a gate you pick an upgrade, then a fork: Gold hour, Deep grove, Harvest, Static dusk. They change cone width, how mean the bushes are, whether the gun jams outside a lit radius. Daily seed is on the title if you want the same twenty miles as everyone else that day.

Dust from a run stays. Spend it at the Outpost between attempts — spare dash, a lamp that's already lit, a hound that barks at mimics.

## Notes

Sprites, audio, and scenes all live in this folder. Don't strip the `.import` files next to the pngs and wavs; Godot wants them.

If the cone looks square, you moved the camera. Leave it top-down.
