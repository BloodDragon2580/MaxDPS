# MaxDps_DeathKnight

## [v10.0.5](https://github.com/kaminaris/MaxDps-DeathKnight/tree/v10.0.5) (2023-06-28)
[Full Changelog](https://github.com/kaminaris/MaxDps-DeathKnight/compare/v10.0.4...v10.0.5) [Previous Releases](https://github.com/kaminaris/MaxDps-DeathKnight/releases)

- v10.0.5  
- Merge pull request #5 from doadin/patch-1  
    [Unholy] Fix Lua Error  
- Merge pull request #13 from kaminaris/apocalypseCorrection  
    Update Unholy.lua  
- [Unholy] Fix Lua Error  
    Apparently GetRuneCooldown can return nil for start and duration, googleing suggests at least in the past start can be nil but I have only seen this happen for duration.  
    1. For duration, this should be the cooldowntime based on haste which should be the same for any rune so fix this by setting duration any time we get a duration from GetRuneCooldown, also set duration default to 1, which is the default duration for how often we check for the next spell so should likely be within that window and be checked again anyways, and hopefully not get nil returned again.  
    2. Have not run into this issue but to be preventative, if we don't have a start time but runeReady is false in this case start should be the time the rune went on cd, so since we check every second if the rune is not ready but we don't have a time just set start to current and hope it returns not nil next run 1 second later. Or if the run is ready and we have no start start should be 0 so set it to 0.  
    Error seen:  
    43x MaxDps\_DeathKnight\Main.lua:127: attempt to perform arithmetic on field 'duration' (a nil value)  
    [string "@MaxDps\_DeathKnight\Main.lua"]:127: in function <MaxDps\_DeathKnight\Main.lua:121>  
    [string "=[C]"]: in function `sort'  
    [string "@MaxDps\_DeathKnight\Main.lua"]:121: in function `TimeToRunes'  
    [string "@MaxDps\_DeathKnight\Specialization/Unholy.lua"]:83: in function `NextSpell'  
    [string "@MaxDps\Core.lua"]:274: in function `?'  