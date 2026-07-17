-- duration_sweep.applescript
-- Experiment 3 (automatable part): isolate the duration and delay fields and
-- confirm their units. Uses the `dissolve` effect (which emits no extra
-- fields) so the ONLY differences between decks are the timing values.
--
-- NOTE: transition *direction* is NOT in the Keynote AppleScript dictionary
-- (the `transition settings` record only exposes effect/duration/delay/
-- automatic), so direction is handled human-in-the-loop, not here.
--
--   argv 1: baseline           (duration 0.5, delay 0.0)
--   argv 2: long duration      (duration 3.0, delay 0.0)
--   argv 3: delayed            (duration 0.5, delay 2.0)

on run argv
    my buildDeck(item 1 of argv, 0.5, 0.0)
    my buildDeck(item 2 of argv, 3.0, 0.0)
    my buildDeck(item 3 of argv, 0.5, 2.0)
end run

on buildDeck(outPath, durVal, delayVal)
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
                    {transition effect:dissolve, transition duration:durVal, ¬
                     transition delay:delayVal, automatic transition:false}
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end buildDeck
