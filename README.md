# Rikkamus's Road to Vostok Scripts

Random scripts for Road to Vostok.

## How to Install

1. Create a `rikkamus` directory in the game's root directory.
2. Copy the `Common` directory to the `rikkamus` directory.
3. Copy the directories of the scripts you want to install to the `rikkamus` directory.
4. Create an `override.cfg` file in the game's root directory and add `res://rikkamus/Common/Common.gd` as an autoload singleton (prepend an asterisk to the script's path to make it a singleton).

## Example directory structure
```
Road to Vostok/
    rikkamus/
        Common/
        PauseOnFocusLost/
    override.cfg
    RTV.exe
    RTV.pck
```

## Example `override.cfg` file

```
[autoload]
RikkamusCommon="*res://rikkamus/Common/Common.gd"
```
