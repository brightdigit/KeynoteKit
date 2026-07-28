-- mm_shapes.applescript
-- Experiment 4b: repeat the Magic Move correspondence probe with SHAPES instead
-- of bare text items, to confirm the file-level conclusion (no persisted
-- correspondence) is not text-specific. Both variants have Magic Move on slide 2.
--   argv 1: A = matchable   (shape "Alpha" on both slides)
--   argv 2: B = non-matchable (shape "Alpha" then "Omega")

on run argv
    my buildDeck(item 1 of argv, "Alpha", "Alpha")
    my buildDeck(item 2 of argv, "Alpha", "Omega")
end run

on buildDeck(outPath, txt1, txt2)
    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                set s1 to make new shape with properties {position:{200, 200}, object text:txt1}
            end tell
            set slide2 to make new slide with properties {base slide:blankMaster}
            tell slide2
                set s2 to make new shape with properties {position:{600, 400}, object text:txt2}
                set transition properties to ¬
                    {transition effect:magic move, transition duration:1.5, ¬
                     automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
