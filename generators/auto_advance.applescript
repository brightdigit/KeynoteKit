-- auto_advance.applescript
-- Experiment 3b: does automatic transition (auto-advance on timer) add a
-- separate auto-advance-delay field, or just flip isAutomatic? Effect fixed to
-- dissolve so only the automatic flag varies.
--   argv 1: A = automatic transition:false (advance on click)
--   argv 2: B = automatic transition:true  (advance automatically)

on run argv
    my buildDeck(item 1 of argv, false)
    my buildDeck(item 2 of argv, true)
end run

on buildDeck(outPath, autoFlag)
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
                set transition properties to ¬
                    {transition effect:dissolve, transition duration:1.5, ¬
                     automatic transition:autoFlag}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
