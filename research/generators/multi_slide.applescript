-- multi_slide.applescript
-- Verify transitions are stored per-slide and independently: a 3-slide deck
-- with a DIFFERENT effect on each slide (incl. slide 1). We then confirm each
-- slide archive carries its own effect.
--   argv 1: output path

on run argv
    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                set t1 to make new text item with properties {object text:"One"}
                set position of t1 to {200, 200}
                set transition properties to {transition effect:dissolve, transition duration:1.5, automatic transition:false}
            end tell
            set s2 to make new slide with properties {base slide:blankMaster}
            tell s2
                set t2 to make new text item with properties {object text:"Two"}
                set position of t2 to {300, 300}
                set transition properties to {transition effect:push, transition duration:1.5, automatic transition:false}
            end tell
            set s3 to make new slide with properties {base slide:blankMaster}
            tell s3
                set t3 to make new text item with properties {object text:"Three"}
                set position of t3 to {400, 400}
                set transition properties to {transition effect:wipe, transition duration:1.5, automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file (item 1 of argv)
        close thisDoc saving no
    end tell
end run
