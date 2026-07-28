-- mm_duplicate.applescript
-- Experiment 4c: does building slide 2 by DUPLICATING slide 1 (then editing)
-- leave any file-level trace vs building slide 2 independently? Both variants
-- are "matchable" (same text "Alpha" on both slides) with Magic Move on slide 2.
-- Diffing A vs B tells us whether duplicate-and-edit is a stronger substrate for
-- `magic-id` (e.g. preserved object ids / a duplicated-from reference) or whether
-- the two approaches are structurally identical (matcher relies on content only).
--
--   argv 1: A = independent creation
--   argv 2: B = duplicate-and-edit

on run argv
    my buildIndependent(item 1 of argv)
    my buildDuplicate(item 2 of argv)
end run

on buildIndependent(outPath)
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
                    {transition effect:magic move, transition duration:1.5, ¬
                     automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildIndependent

on buildDuplicate(outPath)
    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                set t1 to make new text item with properties {object text:"Alpha"}
                set position of t1 to {200, 200}
            end tell
            -- slide 2 is a duplicate of slide 1, then its object is moved.
            duplicate slide 1
            tell slide 2
                set position of text item 1 to {600, 400}
                set transition properties to ¬
                    {transition effect:magic move, transition duration:1.5, ¬
                     automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDuplicate
