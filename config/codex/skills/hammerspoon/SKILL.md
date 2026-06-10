---
name: hammerspoon
description: Create, review, or update Hammerspoon Lua automation config using official online API docs. Use for ~/.hammerspoon/init.lua, config/hammerspoon/init.lua, hs.* APIs, hotkeys, app launchers, window and screen layout, Spoons, watchers, menubar items, alerts, notifications, and macOS desktop automation.
---

# Hammerspoon

## Workflow

1. Inspect the existing Hammerspoon config before changing behavior. In this
   dotfiles repo, start with `config/hammerspoon/init.lua`.
2. For API-specific work, verify the current official docs before editing code:
   - Docs index: `https://www.hammerspoon.org/docs/`
   - Getting started guide: `https://www.hammerspoon.org/go/`
   - Module pages: `https://www.hammerspoon.org/docs/<module>.html`
3. On module pages, read the relevant Signature, Parameters, Returns, Notes,
   and examples. Use exact `hs.*` module names and exact dot or colon call
   syntax from the docs.
4. Keep changes small and reloadable. Preserve user structure, existing
   keybindings, and unrelated local changes.
5. When touching repo Lua config, run the narrowest relevant check available;
   use `make check-lua` for broader Lua validation when practical.

## API Guidance

- Use `hs.hotkey.bind` for simple global shortcuts. Check
  `hs.hotkey.assignable` or `hs.hotkey.systemAssigned` when shortcut conflicts
  matter.
- Use `hs.application`, `hs.application.watcher`, and `hs.appfinder` for app
  launch, focus, and app lifecycle flows.
- Use `hs.window`, `hs.screen`, `hs.geometry`, `hs.grid`, `hs.layout`, and
  `hs.window.filter` for window and screen automation. Avoid assuming every
  window is standard, visible, or in the current Space.
- Use `hs.pathwatcher`, `hs.timer`, `hs.menubar`, `hs.chooser`, and watcher
  objects only with retained references when they must keep running.
- Prefer official Spoons docs and the official Spoon repository for Spoon
  setup. Do not invent Spoon APIs from names alone.

## Hammerspoon Gotchas

- Hammerspoon config is Lua. A colon call passes the object as `self`; a dot
  call does not. Match the docs exactly.
- Objects created during `init.lua` load can be garbage-collected if no
  reference survives after the file finishes. Store long-lived watchers,
  timers, menubar items, chooser instances, filters, and manually constructed
  hotkeys in a top-level table or global.
- `hs.reload()` destroys the current Lua interpreter and starts a new config
  load. Do not put required follow-up logic after a reload call in the same
  callback.
- Many Hammerspoon APIs depend on macOS Accessibility, app state, current
  Space, display layout, or permissions. Handle missing windows/apps/screens
  defensively.
- If official docs are unavailable, do not guess signatures. Use patterns
  already present in the config when safe, or state the docs gap before
  proposing code.
