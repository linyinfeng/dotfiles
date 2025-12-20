// https://git.sr.ht/~mil/lisgd/tree/master/item/config.def.h

/*
  distancethreshold: Minimum cutoff for a gestures to take effect
  degreesleniency: Offset degrees within which gesture is recognized (max=45)
  timeoutms: Maximum duration for a gesture to take place in miliseconds
  orientation: Number of 90 degree turns to shift gestures by
  verbose: 1=enabled, 0=disabled; helpful for debugging
  device: Path to the /dev/ filesystem device events should be read from
  gestures: Array of gestures; binds num of fingers / gesturetypes to commands
            Supported gestures: SwipeLR, SwipeRL, SwipeDU, SwipeUD,
                                SwipeDLUR, SwipeURDL, SwipeDRUL, SwipeULDR
*/

unsigned int distancethreshold = 125;
unsigned int distancethreshold_pressed = 60;
unsigned int degreesleniency = 15;
unsigned int timeoutms = 800;
unsigned int orientation = 0;
unsigned int verbose = 0;
double edgesizeleft = 50.0;
double edgesizetop = 50.0;
double edgesizeright = 50.0;
double edgesizebottom = 50.0;
double edgessizecaling = 1.0;
char *device = "/dev/input/touchscreen";

//Gestures can also be specified interactively from the command line using -g
Gesture gestures[] = {
	/* nfingers  gesture     position            distance         action            command */
  { 1,         SwipeLR,    EdgeLeft,           DistanceAny,     ActModeReleased,  "niri msg action focus-column-left" },
  { 1,         SwipeRL,    EdgeRight,          DistanceAny,     ActModeReleased,  "niri msg action focus-column-right" },
  { 1,         SwipeDU,    EdgeBottom,         DistanceAny,     ActModeReleased,  "niri msg action focus-workspace-down" },
  { 1,         SwipeUD,    EdgeTop,            DistanceAny,     ActModeReleased,  "niri msg action focus-workspace-up" },
	{ 3,         SwipeDU,    EdgeAny,            DistanceAny,     ActModeReleased,  "niri msg action open-overview" },
	{ 1,         SwipeULDR,  CornerTopLeft,      DistanceAny,     ActModeReleased,  "niri msg action open-overview" },
	{ 1,         SwipeURDL,  CornerTopRight,     DistanceAny,     ActModeReleased,  "niri msg action close-window" },
	{ 1,         SwipeDRUL,  CornerBottomRight,  DistanceAny,     ActModeReleased,  "niri msg action switch-preset-column-width" },
	{ 2,         SwipeUD,    EdgeTop,            DistanceAny,     ActModeReleased,  "noctalia-shell ipc call launcher toggle" },
	{ 2,         SwipeDU,    EdgeBottom,         DistanceAny,     ActModeReleased,  "wvkbd-toggle" },
};
