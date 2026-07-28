-- direction_base.applescript
-- Exp 11 (direction): transition DIRECTION, the one remaining transition
-- unknown. Transition effect/duration/delay/automatic ARE scriptable, but
-- direction is NOT in the Keynote dictionary (the `transition settings` record
-- exposes only those four; see duration_direction.md). So this scripts a
-- 2-slide deck with a MOVE IN transition on slide 2 at its DEFAULT direction;
-- a human duplicates it and changes ONLY the Direction dropdown for the B
-- variant, isolating the `animationAttributes.direction` int (Exp 7 showed
-- Move In carries direction: 13).
--
-- NOTE: `move in` is a two-word enumerator, valid only INSIDE a
-- `tell application "Keynote"` block (used directly below, not passed as an
-- argument) — see the HANDOFF gotcha.
--
--   argv 1: output path for the base deck (default direction)

on run argv
    set outPath to item 1 of argv
    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                set t1 to make new text item with properties {object text:"Alpha"}
                set position of t1 to {200, 200}
            end tell
            set slide2 to make new slide with properties {base slide:blankMaster}
            tell slide2
                set t2 to make new text item with properties {object text:"Beta"}
                set position of t2 to {200, 200}
                set transition properties to ¬
                    {transition effect:move in, transition duration:1.0, ¬
                     automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end run
