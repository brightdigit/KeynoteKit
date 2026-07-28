-- magic_move_pair.applescript
-- Probes HOW Magic Move records which object on slide N corresponds to
-- which object on slide N+1 — the single fact that most directly shapes
-- your `magic-id` model.
--
-- Both variants have Magic Move ON. They differ only in whether the two
-- slides share a "matchable" object:
--   A: identical text on both slides (Keynote should match & morph them)
--   B: different text on both slides (nothing to match -> should fall back)
-- Diffing A vs B isolates the correspondence mechanism (shared id? name?
-- text hash? position pairing?).
--
--   argv 1: output path for variant A (matchable)
--   argv 2: output path for variant B (non-matchable)

on run argv
    my buildDeck(item 1 of argv, "Alpha", "Alpha")   -- matchable
    my buildDeck(item 2 of argv, "Alpha", "Omega")   -- not matchable
end run

on buildDeck(outPath, text1, text2)
    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                set a to make new text item with properties {object text:text1}
                set position of a to {200, 200}
            end tell
            set slide2 to make new slide with properties {base slide:blankMaster}
            tell slide2
                set b to make new text item with properties {object text:text2}
                set position of b to {600, 400}
                set transition properties to ¬
                    {transition effect:magic move, transition duration:1.5, ¬
                     automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
