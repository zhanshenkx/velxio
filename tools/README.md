# tools/ — local binaries (not committed)

Put `arduino-cli.exe` here and both `setup.bat` and `start-custom.bat` will find it
without touching your `PATH`.

Download: <https://github.com/arduino/arduino-cli/releases> →
`arduino-cli_<version>_Windows_64bit.zip` → extract `arduino-cli.exe` into this folder.

Verified with arduino-cli 1.6.0. The first sketch compilation then makes the backend
install the `arduino:avr` core (~400 MB, one time, into your Arduino user directory).

If you would rather use a global install, skip this folder entirely: add
`arduino-cli` to `PATH` instead.

Binaries dropped here are intentionally ignored by git (see `.gitignore`), so a
`git status` after downloading stays clean.
