# Rikkamus's Road to Vostok Scripts

Random scripts for Road to Vostok.

## How to Install

1. Copy the scripts you want to install to the game's root directory.
2. Create an `override.cfg` file in the game's root directory and include each script as an autoload singleton (prepend an asterisk to the script's file path to make it a singleton).

## Example `override.cfg` file

```
[autoload]
PauseOnFocusLost="*res://PauseOnFocusLost.gd"
```
