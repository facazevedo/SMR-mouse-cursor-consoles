return PlaceObj('ModDef', {
    'title', "Mouse Cursor Consoles",
    'id', "MouseCursorConsoles",
    'author', "fredware",
    'version', 1,
    'lua_revision', 350453,
    'saved_with_revision', 405907,
    'description', "Toggle a left-stick mouse cursor with R3 / right-stick click. Cross / A: left click; Circle / B: right click; L1 / LB: wheel up; R1 / RB: wheel down; Options / Menu: Escape. R3 is reserved for the toggle while this mod is enabled in a colony. Uses a temporary PC interface and restores previous controls when switched off. PS5 and Xbox Series X|S runtime testing is still required; this release is not console-certified.",
    'last_changes', "Initial implementation: left-stick cursor, toggle, mouse buttons, wheel, and reversible lifecycle.",
    'code', {
        "Code/mcc_config.lua",
        "Code/mcc_debug.lua",
        "Code/mcc_cursor.lua",
        "Code/mcc_input.lua",
        "Code/mcc_lifecycle.lua",
        "Code/MouseCursorConsoles.lua",
    },
    'TagInterface', true,
})
