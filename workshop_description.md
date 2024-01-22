[h1]Resin Watch[/h1]

Keep track of resin in the map using this watch with a nearby indicator and total resin counter so you'll never miss an upgrade!

[i]This addon is compatible with Scalable Init Support but does not require it.[/i]

[img]https://steamuserimages-a.akamaihd.net/ugc/2312102971535718159/B40340B355316F302AC1910CF8464CA2FA204EC1/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false[/img]

[h2]How To Use[/h2]

Tilt your non-dominant hand to your face as you would to see your health and look at the watch attached to wrist.
The main center screen will light up with a directional indicator when resin is nearby and will point to the nearest piece.
The counter at the top of the watch displays how much resin is left in the map.

When resin is far enough above or below the watch, a level indicator at the corner of the watch will light up with an arrow to let you know it might be on a floor you haven't reached yet.

As you explore the map your resin watch will beep and vibrate your controller whenever a new piece of resin is nearby to notify you.

[h2]Console Commands[/h2]

If you don't know how to use the console, follow this guide: https://steamcommunity.com/sharedfiles/filedetails/?id=2040205272

[hr][/hr]
[list]

[*][b]resin_watch_primary_hand[/b]
Default = 0
Resin watch will be attached to the primary hand instead of the secondary hand.
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_inverted[/b]
Default = 0
Resin watch will be inverted on the wrist, screen facing the same way as the palm.
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_radius[/b]
Default = 700
The distance at which resin will be tracked by the directional indicator.
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_notify[/b]
Default = 1
The watch will beep and vibrate your controller when resin is nearby.
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_level_up[/b]
Default = 90
How far above the watch resin is considered on an upper floor. Used for the level indicator arrow on the watch.
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_level_down[/b]
Default = -90
How far below the watch resin is considered on a lower floor. Used for the level indicator arrow on the watch.
[i]This convar is persistent with your save file.[/i]

[/list]

[hr][/hr]
Console commands can be set in the launch options for Half-Life: Alyx, just put a hyphen before each name and the value after, e.g. [b]-resin_watch_primary_hand 1[/b]

[h2]Source Code[/h2]

GitHub: https://github.com/FrostSource/resin_watch

[h2]Known Issues[/h2]

The watch model has no underside and was quickly put together by modifying a base asset. If you are a modeller and want to create a custom watch model for this addon please get in touch!

[strike]The directional indicator does not correctly point to resin when the watch is upside down (hard to notice unless you hold the watch over your head with inverted mode).[/strike]

The watch will not track resin that has not been spawned yet, because of this the counter might not appear consistent but this is normal behaviour.