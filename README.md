# ThoughtDump

Simple macOS menubar app to capture thoughts. **Cmd+Shift+Space** toggles panel.

Thoughts persist locally, accessible via SQLite at `~/Documents/ThoughtDump/thoughts.store`.

## Build & Run

```bash
cd ThoughtDump
xcodebuild -scheme ThoughtDump -configuration Debug -derivedDataPath ./build build
open ./build/Build/Products/Debug/ThoughtDump.app
```

Or open `ThoughtDump.xcodeproj` in Xcode and hit Run.
