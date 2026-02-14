# System Blueprints - Dark Side MVP

## 1) World + Match Flow
- `Main.tscn` owns match state and references subsystems.
- `GameManager` controls start, win/lose, and objective timer.
- Tick flow: input -> simulation update -> UI refresh.

## 2) Command + Camera
- RTS camera supports pan/zoom.
- Selection starts with single flagship selection, then box-selection extension.
- Orders: move, attack-move (phase 2), build command (constructor only).

## 3) Economy + Territory
- Resource nodes are world entities with owner + extraction rate.
- Outpost establishes influence radius.
- Buildings require placement inside owned influence.

## 4) Production
- Production queues on Outpost/Factory-like structures.
- Costs paid on queue start; refunds optional (phase 2).
- Spawn rally point defaults near producer.

## 5) Combat + Damage
- Health + armor-lite model for MVP.
- Projectile and hitscan both supported; start with projectile for readability.
- Threat model: AI prioritizes nearest high-value targets (silo, flagship, outpost).

## 6) Missile Silo Ability
- Requires lock timer + cooldown + energy spike.
- Targeting via world click.
- Warning indicator appears before impact.

## 7) AI (Skirmish Bot)
- Finite-state loop: Expand -> Defend -> Attack.
- Expands when economy threshold reached.
- Attacks when local force value exceeds player frontier estimate.

## 8) Data-Driven Tuning
- Unit/building values stored as JSON in `data/`.
- Runtime loaders convert dictionaries into typed config objects.
- Allows rapid balance passes without touching gameplay logic.
