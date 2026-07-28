-- base_for_builds.applescript
-- Object BUILDS (build-in/out, order, timing) are NOT settable via the
-- Keynote AppleScript dictionary. So automation builds the base deck, and
-- a human adds the one un-scriptable thing in the Animate inspector.
--
-- Workflow for each build experiment:
--   1) Run this to create the base (N identical objects, no animation).
--   2) Save-as the base UNCHANGED as fixtures/<exp>_A.key   (control)
--   3) In Keynote, add exactly ONE build to ONE object.
--   4) Save-as fixtures/<exp>_B.key                          (variant)
--   5) run_experiment.py <exp> --skip-generate --a A.key --b B.key
--
--   argv 1: output path for the base deck
--   argv 2: (optional) number of objects, default 3

on run argv
    set outPath to item 1 of argv
    set n to 3
    if (count of argv) > 1 then set n to (item 2 of argv) as integer

    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                repeat with i from 1 to n
                    set ti to make new text item with properties {object text:("Item " & i)}
                    set position of ti to {200, (150 + (i * 80))}
                end repeat
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end run
