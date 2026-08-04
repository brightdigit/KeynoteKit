-- effect_type.applescript
-- Experiment 2: isolate the transition effect-type field/enum.
-- Builds three decks that are identical except for the transition EFFECT set
-- on slide 2. All three are produced in one scripted pass so the object graph
-- stays maximally stable and the diffs stay clean.
--   argv 1: output path for Magic Move variant
--   argv 2: output path for Dissolve variant
--   argv 3: output path for Push variant

-- effTag is a plain string chosen outside any tell block; the actual
-- enumerator constant (a two-word term like `magic move`) is only valid
-- INSIDE the `tell application "Keynote"` block, so we branch there.
on run argv
    my buildDeck(item 1 of argv, "magic")
    my buildDeck(item 2 of argv, "dissolve")
    my buildDeck(item 3 of argv, "push")
end run

on buildDeck(outPath, effTag)
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
                if effTag is "magic" then
                    set transition properties to ¬
                        {transition effect:magic move, transition duration:1.5, ¬
                         automatic transition:false}
                else if effTag is "dissolve" then
                    set transition properties to ¬
                        {transition effect:dissolve, transition duration:1.5, ¬
                         automatic transition:false}
                else
                    set transition properties to ¬
                        {transition effect:push, transition duration:1.5, ¬
                         automatic transition:false}
                end if
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
