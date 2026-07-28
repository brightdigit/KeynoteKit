-- base_shape_build.applescript
-- Exp 8 (build_shape): a NON-TEXT (shape) build, to test whether the build
-- effect string is object-type-qualified. Text builds serialize e.g.
-- "apple:dissolve character" (build_fx.md); does a build on a shape drop the
-- " character" suffix (-> "apple:dissolve")? If so, the build enum is
-- object-type-qualified and the Deck model needs per-type effect strings.
--
-- Builds are NOT settable via the Keynote AppleScript dictionary, so this only
-- makes the base (one shape, no animation). A human then adds exactly ONE
-- Build In to the shape in the Animate inspector.
--
--   argv 1: output path for the base deck

on run argv
    set outPath to item 1 of argv
    tell application "Keynote"
        set thisDoc to make new document
        tell thisDoc
            set blankMaster to master slide "Blank"
            tell slide 1
                set base slide to blankMaster
                set sh to make new shape with properties {position:{300, 250}}
                set width of sh to 300
                set height of sh to 200
            end tell
        end tell
        save thisDoc in POSIX file outPath
        close thisDoc saving no
    end tell
end run
