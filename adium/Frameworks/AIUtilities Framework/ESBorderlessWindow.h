//ESBorderlessWindow.h based largely off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

@interface ESBorderlessWindow : NSWindow
{
    //This point is used in dragging to mark the initial click location
    NSPoint previousLocation;
}

@end
