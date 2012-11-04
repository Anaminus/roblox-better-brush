# BetterBrush #

A Roblox plugin that replaces the default terrain brush.

By activating the plugin, you can click an drag to paint terrain directly into
the world. This works even with a blank place, with no initial terrai to build
off of.

A GUI also appears, containing a few options. The 2 main options, Clear Above
and Fill Below, can be toggled independantly, allowing greater brushing
flexibility.

Options:

- **Clear Above**

  If true, cells above the position of the brush (all the way to the top) will
  be cleared. Used primarily to remove cells.

- **Fill Below**

  If true, cells below the position of the brush (all the way to the bottom)
  will be filled in.

- **Auto-Smooth**

  If true, brushed cells will automatically smoothed with wedges.

- **Radius**

  Determines the size of the brush. May be a value between 1 and 16.

- **Height**

  Determines the height of where cells are brushed. They are offset from the
  position of the mouse by this value. May be a value between -32 and 32.

[Demo of the plugin in action](http://www.youtube.com/watch?v=AHspGdTgFfE)


## Installation ##

1. Open Roblox Studio.
2. Go to `Tools > Open Plugins Folder` to find location of the plugins folder.
3. Extract the archive to this location.


## TODO ##

The default brush plugin has been updated...

- Visual bounding box of where cells will be brushed
- Square brush option (maybe)
- Keybindings
