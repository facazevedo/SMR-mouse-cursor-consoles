# Mouse Cursor Consoles

A Surviving Mars: Relaunched Lua mod that toggles a left-stick mouse cursor on consoles.

| Action | PS5 | Xbox Series X/S |
| --- | --- | --- |
| Mouse mode on / off | R3 | Right-stick click |
| Move cursor | Left stick | Left stick |
| Hold for 2.5x cursor speed | Hold L3 | Hold left-stick click (LS) |
| Left click / hold to drag | Cross | A |
| Right click | Circle | B |
| Wheel up | L1 | LB |
| Wheel down | R1 | RB |
| Menu / Escape | Options | Menu |

Activate the mod and press R3 on any interactive game screen, including the first
main menu with Tutorial, New Game and Load Game. No colony needs to be loaded.
A second press of the same toggle restores the previous control style. The cursor starts in the
screen center on first activation and remembers its last position within the session
by default. Disable Remember cursor position to recenter on every activation. The right stick does not move it. Both native camera
sticks are locked while mouse mode is active; move to the screen edge for the
game's PC camera behavior. Other controller actions are suppressed in mouse mode
to avoid triggering both a mouse action and its original controller action.

By default, press and hold L3 / Xbox left-stick click while moving the left stick to move 2.5 times faster. Release it
to return to normal speed (optional smoothing makes the transition gradual). This is a hold modifier, not a
toggle; it does not change click or wheel behavior. It has no effect outside
mouse mode or the settings preview. Holding it before entering mouse mode also enables the boost.
Existing L2/LT-default preferences migrate to left-stick click unless that button is
already assigned. Custom bindings remain available; an explicit L2/LT choice saved
in version 12 or later is retained.

**R3 normally pauses the game in a colony.** This mod reserves it for the toggle on all screens,
including while mouse mode is off. Use the HUD's pause control, or configure a
different toggle. Turning off the feature or unloading the mod restores R3 too.

This is an unfinished console-targeted implementation, **not a console-tested release**.
