# Class Change Notifier
SourceMod plugin for Team Fortress 2. Enables the text notifications of a player changing class in mp_tournament mode. Includes checks of the current game state to ensure that it's not the ready-up phase in a tournament game.

This is intended for mp_tournament games, and will *technically* work in any environment, but will likely behave weirdly. If you want to use it in pubs, enable the override CVAR to keep it enabled at all times.

## CVARs
`sm_classchange_notify <0/1>` - enables the class change notices as a whole. Defaults 1.
`sm_classchange_notify_override <0/1>` - overrides any game-state checking, enabling the function of the plugin at all times.

## Known issues
Using usermessages leads to the player and class names being tinted green, BUT uses players' languages. There's probably a way to make the names team-colored as it should be, but I haven't figured it out.
I might make a method switch that lets server owners switch between "user language but green" and "team-colored but hard-coded english" in the interim.
