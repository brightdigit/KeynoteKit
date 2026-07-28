-- effect_matrix.applescript
-- Extends Exp 2: build one deck per representative effect (all else identical)
-- so we can inspect each transition block and discover per-effect extra
-- attribute structures (analogous to Magic Move's custom* keys).
-- argv is a list of output paths, one per effect, in the order of `tags` below.

on run argv
    set tags to {"dissolve", "wipe", "movein", "iris", "cube", "flip", "switch"}
    repeat with i from 1 to (count of argv)
        my buildDeck(item i of argv, item i of tags)
    end repeat
end run

on buildDeck(outPath, tag)
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
                set t2 to make new text item with properties {object text:"Alpha"}
                set position of t2 to {600, 400}
                if tag is "dissolve" then
                    set transition properties to {transition effect:dissolve, transition duration:1.5, automatic transition:false}
                else if tag is "wipe" then
                    set transition properties to {transition effect:wipe, transition duration:1.5, automatic transition:false}
                else if tag is "movein" then
                    set transition properties to {transition effect:move in, transition duration:1.5, automatic transition:false}
                else if tag is "iris" then
                    set transition properties to {transition effect:iris, transition duration:1.5, automatic transition:false}
                else if tag is "cube" then
                    set transition properties to {transition effect:object cube, transition duration:1.5, automatic transition:false}
                else if tag is "flip" then
                    set transition properties to {transition effect:object flip, transition duration:1.5, automatic transition:false}
                else
                    set transition properties to {transition effect:switch, transition duration:1.5, automatic transition:false}
                end if
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
