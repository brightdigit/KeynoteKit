-- transition_matrix.applescript
-- Generates a MINIMAL PAIR that differs only by a slide transition.
--   argv 1: output path for variant A (baseline, no transition)
--   argv 2: output path for variant B (Magic Move on slide 2)
--
-- Slide transitions ARE scriptable, so this whole experiment is automated.
-- Both files are built from the same steps so the object graph stays as
-- stable as possible, keeping the diff clean.
--
-- Usage (via the orchestrator):
--   osascript transition_matrix.applescript /abs/A.key /abs/B.key

on run argv
    set outA to item 1 of argv
    set outB to item 2 of argv

    my buildDeck(outA, false)
    my buildDeck(outB, true)
end run

on buildDeck(outPath, withMagicMove)
    tell application "Keynote"
        set thisDoc to make new document

        tell thisDoc
            set blankMaster to master slide "Blank"

            -- Slide 1: a single positioned text item.
            tell slide 1
                set base slide to blankMaster
                set t1 to make new text item with properties {object text:"Alpha"}
                set position of t1 to {200, 200}
            end tell

            -- Slide 2: the "same" object, moved (the Magic Move scenario).
            set slide2 to make new slide with properties {base slide:blankMaster}
            tell slide2
                set t2 to make new text item with properties {object text:"Alpha"}
                set position of t2 to {600, 400}
            end tell

            if withMagicMove then
                set transition properties of slide2 to ¬
                    {transition effect:magic move, transition duration:1.5, ¬
                     automatic transition:false}
            end if
        end tell

        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
