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

In order to track ammo and items you must double-press the mode switching action:

Valve Index Touch controllers = Arm Xen Grenade (squeeze the trigger twice)
Rift S Touch controllers = Use Grip (squeeze the grip twice)
All other controllers = Arm Xen Grenade (controller dependant)
*(If you have rebinded your controller actions then the button might be different for you)*
*(If you can a recommendation for a default action on a particular controller please let me know)*

Your Resin Watch will switch to an orange color and start tracking nearby items. You can change the behavior of its tracking using the console commands listed below.

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

[*][b]resin_watch_allow_ammo_tracking[/b]
Default = 1
Allow ammo to be tracked by the watch's alternate tracking mode.
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_allow_item_tracking[/b]
Default = 1
Allow items to be tracked by the watch's' alternate tracking mode (grenades, healthvials, etc).
[i]This convar is persistent with your save file.[/i]

[*][b]resin_watch_toggle_button[/b]
Default = Grip button for Rift S, Arm Xen Grenade button for all others
Sets the digital action which must be double tapped to change the tracking mode on the Resin Watch.
To figure out the value of the button you want to use, visit The [url=https://developer.valvesoftware.com/wiki/Half-Life:_Alyx_Workshop_Tools/Scripting_API#Digital_Input_Actions]Valve Software Wiki, Digital Input Actions[/url] section and choose the number in the **Value** column next to the action you want.
[i]This convar is persistent with your save file.[/i]

[/list]

[hr][/hr]
Console commands can be set in the [url=https://help.steampowered.com/faqs/view/7D01-D2DD-D75E-2955]launch options[/url] for Half-Life: Alyx, just put a hyphen before each name and the value after, e.g. [b]-resin_watch_primary_hand 1[/b]
They can also be added to your [b]Half-Life Alyx\game\hlvr\cfg\skill.cfg[/b] file, one per line without the hyphen, e.g. [b]resin_watch_primary_hand 1[/b]

[h2]Source Code[/h2]

GitHub: https://github.com/FrostSource/resin_watch

[h2]Known Issues[/h2]

The watch model has no underside and was quickly put together by modifying a base asset. If you are a modeller and want to create a custom watch model for this addon please get in touch!

[strike]The directional indicator does not correctly point to resin when the watch is upside down (hard to notice unless you hold the watch over your head with inverted mode).[/strike]

The watch cannot track resin or items that have not been spawned yet. Because of this the counter might not appear consistent but this is normal behaviour.