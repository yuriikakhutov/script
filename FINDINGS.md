# Improvement Suggestions

## 1. Force Staff/Hurricane Pike escapes don't lock player input
The escape queue issues a move order via `Player.PrepareUnitOrders`, but it never blocks manual commands while the hero is turning. Any user input during the delay can instantly cancel the queued facing, so the item still fires toward the player's latest direction rather than the computed escape vector.【F:script.lua†L825-L854】

**Suggested fix:** wrap the queuing logic with an input-lock helper (using `Input.Block`/`Engine.ExecuteCommand` per the UCZone API) and release it in every exit path so the hero keeps the desired orientation until the cast executes or is cancelled.

## 2. Escape queue doesn't refresh orientation while waiting
Once the pending entry is created, no additional move/facing orders are sent. If the enemy moves or the hero gets bumped, the hero may end up facing the wrong way when the cast fires. Reissuing the escape-facing command each update until the ability is cast would keep the hero aligned with the escape direction.【F:script.lua†L825-L878】

**Suggested fix:** store the target escape position in the pending state and resend the `PrepareUnitOrders` call while the entry remains active, stopping once the cast succeeds or is aborted.
