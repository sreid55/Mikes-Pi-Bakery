'' ===========================================================================
''
''  File: WMF_ColorThemeDemo_010.spin 
''
''  Modification History
''
''  Author:     Andre' LaMothe 
''  Copyright (c) Andre' LaMothe / Parallax Inc.
''  See end of file for terms of use
''  Version:    1.0
''  Date:       1/29/2011
''
''  Comments: The VGA driver used by the high level WMF_Terminal_Services_***.spin
''  driver has support for 2 colors per character row. In other words, for each line
''  of the display, the characters can have 2 colors. The demo shows off a couple function
''  calls that facilitate changing these colors with pre-defined RGB "theme" set constants
''  that I have created in the terminal services driver. These are nothing more that two
''  constants each that select two complementary colors that you can set the display to
''  so that it doesn't "look" bad. The idea of this graphics series is not only to show
''  how to display text, graphics, make gui elements, but to teach some decent color and
''  aesthetics tactics. Programmers are notorious for choosing terriable colors, so these
''  themes can help those that are "RGB challenged" and give them some default color schemes
''  that won't hurt the eyes of those using applications your may develop :)
''
''  Of course, we would like to have a lot more than 2 colors per row, but more color and high
''  resolution means that we need to start using 3-4 COGs to process the information and
''  that's just not worth it at this point. 2 colors per row is more than enough for the
''  astute GUI designer to make a screen interesting and engaging. Later in the series
''  we might create some higher color / lower resolution applications. But, for now,
''  I have opted to use one of the most tried and true VGA drivers developed by Parallax
''  that has been around for a while and it has high resolution, 2 colors per row
''  which is fine for now.  
''
''  Requires: This demo, like the majority of VGA demos requires a Propeller platform
''  with both a mouse and keyboard as well as VGA output. You can adjust the pins for
''  the devices below in the CON section. This demo was developed using the standard
''  Propeller Demo board with a 5 Mhz, xtal. If you have something different you will
''  have to make the appropriate changes.  
''
'' ===========================================================================


CON
' -----------------------------------------------------------------------------
' CONSTANTS, DEFINES, MACROS, ETC.   
' -----------------------------------------------------------------------------

  ' set speed to 80 MHZ, 5.0 MHZ xtal, change this if you are using
  ' other XTAL speeds
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' import some constants from the Propeller Window Manager
  VGACOLS = WMF#VGACOLS
  VGAROWS = WMF#VGAROWS

  ' set these constants based on the Propeller device you are using
  VGA_BASE_PIN      = 16        'VGA pins 16-23
  
  MOUSE_DATA_PIN    = 24        'MOUSE data pin
  MOUSE_CLK_PIN     = 25        'MOUSE clock pin

  KBD_DATA_PIN      = 26        'KEYBOARD data pin
  KBD_CLK_PIN       = 27        'KEYBOARD clock pin 

  ' ASCII codes for ease of character and string processing
  ASCII_A      = 65
  ASCII_B      = 66
  ASCII_C      = 67
  ASCII_D      = 68
  ASCII_E      = 69
  ASCII_F      = 70
  ASCII_G      = 71
  ASCII_H      = 72
  ASCII_O      = 79  
  ASCII_P      = 80
  ASCII_Z      = 90
  ASCII_0      = 48
  ASCII_9      = 57
  ASCII_LEFT   = $C0
  ASCII_RIGHT  = $C1
  ASCII_UP     = $C2
  ASCII_DOWN   = $C3 
  ASCII_BS     = $C8 ' backspace
  ASCII_DEL    = $C9 ' delete
  ASCII_LF     = $0A ' line feed 
  ASCII_CR     = $0D ' carriage return
  ASCII_ESC    = $CB ' escape
  ASCII_HEX    = $24 ' $ for hex
  ASCII_BIN    = $25 ' % for binary
  ASCII_LB     = $5B ' [ 
  ASCII_SEMI   = $3A ' ; 
  ASCII_EQUALS = $3D ' = 
  ASCII_PERIOD = $2E ' .
  ASCII_COMMA  = $2C ' ,
  ASCII_SHARP  = $23 ' #
  ASCII_NULL   = $00 ' null character
  ASCII_SPACE  = $20 ' space
  ASCII_TAB    = $09 ' horizontal tab

' box drawing characters
  ASCII_HLINE = 14 ' horizontal line character
  ASCII_VLINE = 15 ' vertical line character
  ASCII_TOPLT = 10 ' top left corner character
  ASCII_TOPRT = 11 ' top right corner character
  ASCII_TOPT  = 16 ' top "t" character
  ASCII_BOTT  = 17 ' bottom "t" character
  ASCII_LTT   = 18 ' left "t" character
  ASCII_RTT   = 19 ' right "t" character
  ASCII_BOTLT = 12 ' bottom left character
  ASCII_BOTRT = 13 ' bottom right character
  ASCII_DITHER = 24 ' dithered pattern for shadows
  NULL         = 0 ' NULL pointer


OBJ
  '---------------------------------------------------------------------------
  ' Propeller Windows GUI object(s) 
  '---------------------------------------------------------------------------
  
  WMF           : "WMF_Terminal_Services_010" 
  kbd           : "Keyboard_011"
  mouse         : "Mouse_011" 

VAR
' -----------------------------------------------------------------------------
' DECLARED VARIABLES, ARRAYS, ETC.   
' -----------------------------------------------------------------------------

  byte  gVgaRows, gVgaCols ' convenient globals to store number of columns and rows

  byte  gStrBuff1[64]      ' some string buffers
  byte  gStrBuff2[64]

  ' these data structures contains two cursors in the format [x,y,mode]
  ' these are passed to the VGA driver, so it can render them over the text in the display
  ' like "hardware" cursors, that don't disturb the graphics under them. We can use them
  ' to show where the text cursor and mouse cursor is
  ' The data structure is 6 contiguous bytes which we pass to the VGA driver ultimately
  
  byte  gTextCursX, gTextCursY, gTextCursMode        ' text cursor 0 [x0,y0,mode0] 
  byte  gMouseCursX, gMouseCursY, gMouseCursMode     ' mouse cursor 1 [x1,y1,mode1] 

  byte  gMouseButtons                                ' buttons for mouse 
  long  gVideoBufferPtr                              ' holds the address of the video buffer passed back from the VGA driver 

CON
' -----------------------------------------------------------------------------
' MAIN ENTRY POINT   
' -----------------------------------------------------------------------------
PUB Start | userSel, rowIndex 

  ' first step create the GUI itself
  CreateAppGUI

  ' MAIN EVENT LOOP - this is where you put all your code in an infinite loop...  
  repeat
    ' get mouse state which is being tracked by VGA driver to move the virtual cursor(s) as well
    ' these globals are bound to the VGA driver during initialization by passing the address of the
    ' cursor(s) 6 bytes (3 for each cursor; "mouse" and "keyboard") by reading the mouse each iteration
    ' of the event loop the mouse cursor will still update and move around the screen in the demo
    ' also notice that the "text" cursor is visible on the VGA screen top, left a few rows down
    ' if we wanted we could move it as well by updating ITS global variables which are also being
    ' tracked by the VGA driver   
    gMouseCursX   := mouse.bound_x                   
    gMouseCursY   := mouse.bound_y                   
    gMouseButtons := mouse.buttons
     
    ' main code goes here................

    ' clear the screen, resetting the terminal cursor to (0,0) as well
    WMF.OutTerm( $00 ) 

    ' print menu
    WMF.StringTerm(string("VGA Terminal Services Demo | Color Theme Menu Demo | (c) Parallax 2011"))
    WMF.NewlineTerm
    WMF.NewlineTerm

    ' draw menu items as a list of text strings using the terminal, note variant StringTermLn
    ' which prints a carriage return, newline after the string

    WMF.StringTermLn(string("1. WHITENBLACK - Basic white on black theme, looks like a DOS/CMD console terminal, white text on black background."))
    WMF.NewlineTerm
    WMF.StringTermLn(string("2. BLACKNWHITE - Basic black on white theme, looks like a modern Windows/Linux/Mac OS window with black text on white background."))
    WMF.NewlineTerm
    WMF.StringTermLn(string("3. ATARI_C64 - Atari/C64 theme -- This is white on dark blue like the old 8-bit systems."))
    WMF.NewlineTerm
    WMF.StringTermLn(string("4. APPLE2 - Apple ][ / Terminal theme - This theme is green text on a black background, reminiscient of old terminals and the Apple ][."))
    WMF.NewlineTerm
    WMF.StringTermLn(string("5. WASP -  Wasp / Yellow jacket theme - Black on yellow background.")) 
    WMF.NewlineTerm
    WMF.StringTermLn(string("6. AUTUMN - Autumn theme - Black on orange background.")) 
    WMF.NewlineTerm
    WMF.StringTermLn(string("7. CREAMSICLE - Creamsicle theme  - White on orange background.")) 
    WMF.NewlineTerm
    WMF.StringTermLn(string("8. ORCHID - Purple orchid theme - White on purple background.")) 
    WMF.NewlineTerm
    WMF.StringTermLn(string("9. GREMLIN - Gremlin theme  - Green on gray background.")) 
    WMF.NewlineTerm
    WMF.StringTerm(string("Your selection?"))    

    ' get user input with local function and then convert to integer       
    userSel := WMF.atoi( GetStringTerm( @gStrBuff1, 4), 4 )

    ' based on user selection change the color scheme of the screen  
    case userSel
 
      1:   ' basic white on black theme, looks like a DOS/CMD console terminal, white text on black background
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_WHITENBLACK_INFO_FG, WMF#CTHEME_WHITENBLACK_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_WHITENBLACK_FG, WMF#CTHEME_WHITENBLACK_BG )       

      2:   ' basic black on white theme, looks like a modern Windows/Linux/Mac OS window with black text on white background
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_BLACKNWHITE_INFO_FG, WMF#CTHEME_BLACKNWHITE_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_BLACKNWHITE_FG, WMF#CTHEME_BLACKNWHITE_BG )       

      3: ' Atari/C64 theme -- this is white on dark blue like the old 8-bit systems
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_ATARI_C64_INFO_FG, WMF#CTHEME_ATARI_C64_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_ATARI_C64_FG, WMF#CTHEME_ATARI_C64_BG )       

      4: ' Apple ][ / Terminal theme - this theme is green text on a black background, reminiscient of old terminals and the Apple ][.
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_APPLE2_INFO_FG, WMF#CTHEME_APPLE2_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_APPLE2_FG, WMF#CTHEME_APPLE2_BG )       

      5:  ' wasp/yello jacket theme - black on yellow background,
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_WASP_INFO_FG, WMF#CTHEME_WASP_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_WASP_FG, WMF#CTHEME_WASP_BG )       

      6: ' autumn theme  - black on orange background
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_AUTUMN_INFO_FG, WMF#CTHEME_AUTUMN_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_AUTUMN_FG, WMF#CTHEME_AUTUMN_BG )       

      7: ' creamsicle theme  - white on orange background
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_CREAMSICLE_INFO_FG, WMF#CTHEME_CREAMSICLE_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_CREAMSICLE_FG, WMF#CTHEME_CREAMSICLE_BG )       

      8: ' purple orchid theme  - white on purple background
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_ORCHID_INFO_FG, WMF#CTHEME_ORCHID_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_ORCHID_FG, WMF#CTHEME_ORCHID_BG )       

      9:
       ' set topmost line to inverted values to make top "info" line stronger
       WMF.SetLineColor( 0, WMF#CTHEME_GREMLIN_INFO_FG, WMF#CTHEME_GREMLIN_INFO_BG )

       ' set the rest of screen to normal non-inverted colors
       repeat rowIndex from 1 to VGAROWS-1
         WMF.DelayMilliSec( 20 )
         WMF.SetLineColor( rowIndex, WMF#CTHEME_GREMLIN_FG, WMF#CTHEME_GREMLIN_BG )       
 
' end PUB ---------------------------------------------------------------------

PUB CreateAppGUI | retVal 
' This functions creates the entire user interface for the application and does any other
' static initialization you might want, notice we start both a mouse and keyboard driver
' if you do NOT want one or the other you can comment our the driver calls to start them
' but it will break some of the demos. Thus, ideally use a Propeller platform that has both
' a keyboard and mouse to get the most out of the series of demos. You can always remove one
' input device in your final applications, but its nice to have them both for illustrative
' purposes to show certain GUI concepts
 
  ' text cursor starting position and as blinking underscore  
  gTextCursX     := 0                              
  gTextCursY     := 0                              
  gTextCursMode  := %110       

  'set mouse cursor position and as solid block
  gMouseCursX    := VGACOLS/2                              
  gMouseCursY    := VGAROWS/2                              
  gMouseCursMode := %001 

  ' start the mouse
  mouse.start( MOUSE_DATA_PIN, MOUSE_CLK_PIN )

  ' set boundaries
  mouse.bound_limits(0, 0, 0, VGACOLS - 1, VGAROWS - 1, 0)

  ' adjust speed/sensitivity (note minus value on 2nd parm inverts the axis as well)
  mouse.bound_scales(8, -8, 0)           

  'mouse starting position
  mouse.bound_preset(VGACOLS/2, VGAROWS/2, 0)            

  ' start the keyboard
  kbd.start( KBD_DATA_PIN, KBD_CLK_PIN )

  ' now start the VGA driver and terminal services 
  retVal := WMF.Init(VGA_BASE_PIN, @gTextCursX )

  ' rows encoded in upper 8-bits. columns in lower 8-bits of return value, redundant code really
  ' since we pull it in with a constant in the first CON section, but up to you! 
  gVgaRows := ( retVal & $0000FF00 ) >> 8
  gVgaCols := retVal & $000000FF

  ' VGA buffer encoded in upper 16-bits of return value
  gVideoBufferPtr := retVal >> 16 

  '---------------------------------------------------------------------------
  'setup screen colors
  '---------------------------------------------------------------------------
 
  ' the VGA driver VGA_HiRes_Text_*** only has 2 colors per character
  ' (one for foreground, one for background). However,each line/row on the screen
  ' can have its OWN set of 2 colors, thus as long as you design your interfaces
  ' "vertically" you can have more apparent colors, nonetheless, on any one row
  ' there are only two colors. The function call below fills the color table up
  ' for the specified foreground and background colors from the set of "themes"
  ' found in the WMF_Terminal_Services_*** driver. These are nothing more than
  ' some pre-computed color constants that look "good" and if you are color or
  ' artistically challenged will help you make your GUIs look clean and professional.
  WMF.ClearScreen( WMF#CTHEME_ATARI_C64_FG, WMF#CTHEME_ATARI_C64_BG )

  ' set topmost line to inverted values to make top "info" line stronger
  WMF.SetLineColor( 0, WMF#CTHEME_ATARI_C64_INFO_FG, WMF#CTHEME_ATARI_C64_INFO_BG )

                 

  ' return to caller
  return
   
' end PUB ---------------------------------------------------------------------    

CON
' -----------------------------------------------------------------------------
' USER TEXT INPUT FUNCTION(s)   
' -----------------------------------------------------------------------------

PUB GetStringTerm(pStringPtr, pMaxLength) | length, key
{{
DESCRIPTION: This simple function is a single line editor that allows user to enter keys from the keyboard
and then echos them to the screen, when the user hits <ENTER> | <RETURN> the function
exits and returns the string. The function has simple editing and allows <BACKSPACE> to
delete the last character, that's it! The function outputs to the terminal.

PARMS: pStringPTr - pointer to storage for input string.
       pMaxLength - maximum length of string buffer.

RETURNS: pointer to string, empty string if user entered nothing.

}}

  ' current length of string buffer
  length := 0  

  ' draw cursor
  repeat 

    ' draw cursor
    WMF.OutTerm( "_" )
    WMF.OutTerm( $08 )
  
    ' wait for keypress 
    repeat while (kbd.gotkey == FALSE)

    ' user entered a key process it

    ' get key from buffer
    key := kbd.key
     
    case key
       ASCII_LF, ASCII_CR: ' return    
 
        ' null terminate string and return
        byte [pStringPtr][length] := ASCII_NULL
     
        return( pStringPtr )

       ASCII_BS, ASCII_DEL, ASCII_LEFT: ' backspace (edit)

         if (length > 0)
           ' move cursor back once to overwrite last character on screen
           WMF.OutTerm( ASCII_SPACE )
           WMF.OutTerm( $08 )          
           WMF.OutTerm( $08 )
           
           ' echo character
           WMF.OutTerm( ASCII_SPACE )
           WMF.OutTerm( $08 )
         
           ' decrement length
           length--
 
       other:    ' all other cases
         ' insert character into string 
         byte [pStringPtr][length] := key

         ' update length
         if (length < pMaxLength )
           length++
         else
           ' move cursor back once to overwrite last character on screen
           WMF.OutTerm( $08 )          

         ' echo character
         WMF.OutTerm( key )
     
' end PUB ----------------------------------------------------------------------


CON
' -----------------------------------------------------------------------------
' SOFTWARE LICENSE SECTION   
' -----------------------------------------------------------------------------
{{
┌────────────────────────────────────────────────────────────────────────────┐
│                     TERMS OF USE: MIT License                              │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│                                                                            │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS│
│IN THE SOFTWARE.                                                            │
└────────────────────────────────────────────────────────────────────────────┘
}}       