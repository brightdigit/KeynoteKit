-- one_effect.applescript
-- Build a single two-slide deck with the given transition effect on slide 2.
-- One effect per osascript invocation (robust against Apple-event
-- "connection is invalid" errors seen when batching many documents).
--   argv 1: output path
--   argv 2: effect tag (dissolve|wipe|movein|iris|cube|flip|switch|magic)

on run argv
    my buildDeck(item 1 of argv, item 2 of argv)
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
                else if tag is "switch" then
                    set transition properties to {transition effect:switch, transition duration:1.5, automatic transition:false}
                else
                    set transition properties to {transition effect:magic move, transition duration:1.5, automatic transition:false}
                end if
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
