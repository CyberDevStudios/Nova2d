# Packaging & Distribution

This guide covers turning a Nova2D project into something players can run: a `.love` file
or a platform-specific build.

## 1. Prepare the project

Before packaging:

- Set the version in `src/version.lua` (single source of truth; the splash screen reads it)
- Update `conf.lua`: title, window size, icon
- Install dependencies and commit/keep the generated `libs/` and `nova2d-lock.lua`
- Remove development-only files if you want a lean archive:
  `gestor/`, `tests/`, `docs/`, `openspec/`, `.github/`

`love gestor/ install` must have run at least once; the game loads dependencies from
`libs/` at runtime.

## 2. Build a `.love` file

A `.love` file is a ZIP of the project root:

```bash
cd my-game
zip -9 -r ../my-game.love . \
    -x "*.git*" -x "*tests/*" -x "*gestor/*" -x "*docs/*" -x "*.love"
```

Run it with Love2D:

```bash
love ../my-game.love
```

Keep `main.lua` at the archive root. `conf.lua` must be there too.

## 3. Windows, macOS, Linux builds

The standard approach is to append the `.love` file to the Love2D executable (Windows) or
replace the executable inside the app bundle (macOS). The Love2D wiki maintains the
up-to-date steps:

- <https://love2d.org/wiki/Game_Distribution>

For repeatable builds, community tools such as `love-release` automate the same steps.
Nova2D does not bundle a packager, so any tool that produces a valid Love2D build works.

### Windows

```bash
copy /b love.exe+my-game.love my-game.exe
```

Ship `my-game.exe` next to the DLLs and license files that come with Love2D.

### macOS

Copy `love.app` to `MyGame.app`, place `my-game.love` inside
`MyGame.app/Contents/Resources/`, and edit `Contents/Info.plist` (bundle name,
identifier, icon). Sign the app if you distribute it outside your machine.

### Linux

Either distribute the `.love` file (players install Love2D), or ship it with the Love2D
runtime using the same append trick as Windows. AppImage/Flatpak packaging is outside the
scope of this guide.

## 4. Versioning

`src/version.lua` holds the framework version. Your game version is separate — put it in
`nova2d.lua`, `conf.lua` or your own config, and display it wherever you like. The demo
shows the framework version in the HUD as an example.

## 5. Checklist

- [ ] `love .` boots with a clean console
- [ ] Dependencies are present in `libs/`
- [ ] `conf.lua` has the final title, size and icon
- [ ] No `.git`, `tests/` or `docs/` inside the shipped archive
- [ ] The build runs on a machine without the project directory
- [ ] Audio works if the game uses it (`t.modules.audio = true`)
