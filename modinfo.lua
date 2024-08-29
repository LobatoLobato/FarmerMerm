name = "Farmer Merm"
description = "WurtWurtWurtWurtWurtWurtWurtWurtWurtWurtWurtWurtWurtWurtWurt"
author = "Lobato"
version = "0.0.1"
forumthread = ""
icon_atlas = "icon.xml"
icon = "icon.tex"
client_only_mod = false
all_clients_require_mod = true
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
priority = 0
api_version = 10


configuration_options =
{
  {
    name = "CTRL",
    label = "CTRL Turns Mod",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = false,
    hover = "Whether holding CTRL enables or disables the mod.",
  },
  {
    name = "KEYBOARDTOGGLEKEY",
    label = "Options Button",
    options = keyslist,
    default = "B",
    -- hover = "A key to open the mod's options. On controllers, open\nthe scoreboard and then use Menu Misc 3 (left stick click).\nI recommend setting this with the Settings menu in DST.",
    hover =
    "A key to open the mod's options. On controllers, open\nthe scoreboard and then use Menu Misc 3 (left stick click). When set to None, controller is also unbound.",
  },
  {
    name = "GEOMETRYTOGGLEKEY",
    label = "Toggle Button",
    options = keyslist,
    default = "V",
    -- hover = "A key to toggle to the most recently used geometry\n(for example, switching between Square and X-Hexagon). No controller binding.\nI recommend setting this with the Settings menu in DST.",
    hover =
    "A key to toggle to the most recently used geometry\n(for example, switching between Square and X-Hexagon). No controller binding.",
  },
  {
    name = "SNAPGRIDKEY",
    label = "Snap Grid Button",
    options = keyslist,
    default = "",
    -- hover = "A key to snap the grid to have a point centered on the hovered object or point. No controller binding.\nI recommend setting this with the Settings menu in DST.",
    hover = "A key to snap the grid to have a point centered on the hovered object or point. No controller binding.",
  },
  {
    name = "SHOWMENU",
    label = "In-Game Menu",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = true,
    hover = "If on, the button opens the menu.\nIf off, it just toggles the mod on and off.",
  },
  {
    name = "BUILDGRID",
    label = "Show Build Grid",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = true,
    hover = "Whether to show the build grid.",
  },
  {
    name = "GEOMETRY",
    label = "Grid Geometry",
    options = {
      { description = "Square",         data = "SQUARE" },
      { description = "Diamond",        data = "DIAMOND" },
      { description = "X Hexagon",      data = "X_HEXAGON" },
      { description = "Z Hexagon",      data = "Z_HEXAGON" },
      { description = "Flat Hexagon",   data = "FLAT_HEXAGON" },
      { description = "Pointy Hexagon", data = "POINTY_HEXAGON" },
    },
    default = "SQUARE",
    hover = "What build grid geometry to use.",
  },
  {
    name = "TIMEBUDGET",
    label = "Refresh Speed",
    options = percent_options,
    default = 0.1,
    hover =
    "How much of the available time to use for refreshing the grid.\nDisabling or setting too high will likely cause lag.",
  },
  {
    name = "HIDEPLACER",
    label = "Hide Placer",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = false,
    hover =
    "Whether to hide the placer (the ghost version of the item you're placing).\nHiding it can help you see the grid better.",
  },
  {
    name = "HIDECURSOR",
    label = "Hide Cursor Item",
    options = {
      { description = "Hide All",    data = 1 },
      { description = "Show Number", data = true },
      { description = "Show All",    data = false },
    },
    default = false,
    hover = "Whether to hide the cursor item, to better see the grid.",
  },
  {
    name = "SMARTSPACING",
    label = "Smart Spacing",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = false,
    hover =
    "Whether to adjust the spacing of the grid based on what object is being placed.\nAllows for optimal grids, but can make it hard to put things just where you want them.",
  },
  {
    name = "ACTION_TILL",
    label = "Till Grid",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = true,
    hover = "Whether to use a grid for tilling farm soil.\nAutomatically turned off when using the Snapping Tills mod.",
  },
  {
    name = "SMALLGRIDSIZE",
    label = "Fine Grid Size",
    options = smallgridsizeoptions,
    default = 10,
    hover = "How big to make the grid for things that use a fine grid (structures, plants, etc).",
  },
  {
    name = "MEDGRIDSIZE",
    label = "Medium Grid Size",
    options = medgridsizeoptions,
    default = 6,
    hover = "How big to make the grid for things that use a medium grid (such as walls, DST crops).",
  },
  {
    name = "BIGGRIDSIZE",
    label = "Large Grid Size",
    options = biggridsizeoptions,
    default = 2,
    hover = "How big to make the grid for things that use a large grid (such as turf and pitchforks).",
  },
  {
    name = "GOODCOLOR",
    label = "Unblocked Color",
    options = color_options,
    default = "whiteoutline",
    hover = "The color to use for unblocked points, where you can place things.",
  },
  {
    name = "BADCOLOR",
    label = "Blocked Color",
    options = color_options,
    default = "blackoutline",
    hover = "The color to use for blocked points, where you cannot place things.",
  },
  {
    name = "NEARTILECOLOR",
    label = "Nearest Tile Color",
    options = color_options,
    default = "white",
    hover = "The color to use for the nearest tile outline.",
  },
  {
    name = "GOODTILECOLOR",
    label = "Unblocked Tile Color",
    options = color_options,
    default = "whiteoutline",
    hover = "The color to use for the turf tile grid, where you can place turf.",
  },
  {
    name = "BADTILECOLOR",
    label = "Blocked Tile Color",
    options = color_options,
    default = "blackoutline",
    hover = "The color to use for the turf tile grid, where you can't place turf.",
  },
  {
    name = "GOODPLACERCOLOR",
    label = "Unblocked Placer Color",
    options = placer_color_options,
    default = "white",
    hover = "The color to use for an unblocked placer\n(the \"shadow copy\" of the thing you're placing).",
  },
  {
    name = "BADPLACERCOLOR",
    label = "Blocked Placer Color",
    options = placer_color_options,
    default = "black",
    hover = "The color to use for a blocked placer\n(the \"shadow copy\" of the thing you're placing).",
  },
  {
    name = "REDUCECHESTSPACING",
    label = "Tighter Chests",
    options = {
      { description = "Yes", data = true },
      { description = "No",  data = false },
    },
    default = true,
    hover = "Whether to allow chests to be placed closer together than normal.\nThis may not work in DST.",
  },
  {
    name = "CONTROLLEROFFSET",
    label = "Controller Offset",
    options = {
      { description = "On",  data = true },
      { description = "Off", data = false },
    },
    default = false,
    hover = "With a controller, whether objects get placed\nright at your feet (\"off\") or at an offset (\"on\").",
  },
}
