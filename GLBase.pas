unit GLBase;

interface

// OpenGL Basic Framework code, written by Dave Jewell, Spring 2002
// Based upon NeHe's original C++ code (http://nehe.gamedev.net/)

uses Windows, Messages, OpenGL;

type
  TGLBase = class (TObject)
  private
    FBitsPerPixel: Integer;
    fCreateFullScreen: Boolean;
    FFullScreen: Boolean;
    FHeight: Integer;
    FWidth: Integer;
    fWindowTitle: string;
    function ChangeScreenResolution: Boolean;
    procedure CleanUp;
    function CreateWindowGL: Boolean;
    procedure PumpMessages;
    function RegisterWindowClass: Boolean;
    procedure ReshapeGL(Width, Height: Integer);
    procedure SetTitle(const Value: string);
    procedure TerminateApplication;
    procedure WMClose(var Message: TWMClose); message WM_CLOSE;
  protected
    fClassName: string;
    fHDC: HDC;
    fHRC: HGLRC;
    fHWnd: HWnd;
    fIsVisible: Boolean;
    fLastTickCount: DWord;
    fTerminating: Boolean;
    function DoInit: Boolean; virtual;
    procedure DoUnInit; virtual;
    procedure Draw; virtual; abstract;
    procedure KeyPress(KeyCode: Integer; IsDown: Boolean); virtual;
    procedure Update(milliSeconds: DWord); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Execute;
    procedure ToggleFullScreen;
    property BitsPerPixel: Integer read FBitsPerPixel;
    property FullScreen: Boolean write FFullScreen;
    property Height: Integer write FHeight;
    property Title: string write SetTitle;
    property Width: Integer write FWidth;
  end;
  
// Stuff that's missing from Borland's Header files...

procedure glGenTextures (Count: Integer; textures: PInteger); stdcall; external 'opengl32.dll';
procedure glBindTexture (Target, Texture: Integer); stdcall; external 'opengl32.dll';

// And stuff that needs fixing!

function gluBuild2DMipmaps (target: GLenum; components, width, height: GLint; format, atype: GLenum; data: Pointer): Integer; stdcall; external 'glu32.dll';

implementation

const
    wm_ToggleFS = wm_User + 1;

function TGLBaseWindowProc (Wnd, Msg, wParam, lParam: Integer): Integer; stdcall;
begin
    Result := 0;
    with TGLBase (GetWindowLong (Wnd, gwl_UserData)) do begin
        case Msg of
            wm_Close:       begin
                                TerminateApplication;
                                Exit;
                            end;

            wm_SysCommand:  if (wParam = sc_ScreenSave) or (wParam = sc_MonitorPower) then Exit;

            wm_ToggleFS:    begin
                                fCreateFullScreen := not fCreateFullScreen;
                                PostMessage (Wnd, wm_Quit, 0, 0);
                                Exit;
                            end;

            wm_KeyDown,
            wm_KeyUp:       begin
                                KeyPress (wParam, Msg = wm_KeyDown);
                                Exit;
                            end;

            wm_Size:        case wParam of
			  	Size_Minimized:
                                begin
                                    fIsVisible := False;
                                    Exit;
                                end;

                                Size_Restored,
                                Size_Maximized:
                                begin
                                    fIsVisible := True;
				    ReshapeGL (LOWORD (lParam), HIWORD (lParam));
				    Exit;
                                end;
                            end;
        end;
    end;

    Result := DefWindowProc (Wnd, Msg, wParam, lParam);
end;

// TGLBase

{
**************************************** TGLBase *****************************************
}
constructor TGLBase.Create;
begin
  Inherited Create;
  fClassName    := 'OpenGLAFX';
  fWindowTitle  := 'OpenGLAFX 1.0 Demo';
  fWidth        := 800;
  fHeight       := 600;
  fBitsPerPixel := 16;
  fFullScreen   := False;
end;

destructor TGLBase.Destroy;
begin
  Cleanup;
  //UnRegisterClass (PChar (fClassName), hInstance);
end;

function TGLBase.ChangeScreenResolution: Boolean;
var
  dm: DevMode;
begin
      FillChar (dm, sizeof (dm), 0);
      with dm do begin
          dmSize          := sizeof (dm);
  	dmPelsWidth	:= fWidth;
  	dmPelsHeight	:= fHeight;
  	dmBitsPerPel	:= fBitsPerPixel;
  	dmFields	:= dm_BitsPerPel or dm_PelsWidth or dm_PelsHeight;
      end;
  
      Result := ChangeDisplaySettings (dm, cds_FullScreen) = 0;
end;

procedure TGLBase.CleanUp;
begin
  if fHWnd <> 0 then
  begin
    if fHDC <> 0 then
    begin
      wglMakeCurrent (fHDC, 0);
      if fHRC <> 0 then
      begin
        wglDeleteContext (fHRC);
        fHRC := 0;
      end;
      ReleaseDC (fHWnd, fHDC);
      fHDC := 0;
    end;
    DestroyWindow (fHWnd);
    fHWnd := 0;
  end;
  if fFullScreen then
    ChangeDisplaySettings (TDeviceMode (Nil^), 0);
  UnRegisterClass (PChar (fClassName), hInstance);
end;

function TGLBase.CreateWindowGL: Boolean;
var
  X, Y: Integer;
  WindowRect: TRect;
  PixelFormat: Integer;
  pfd: PixelFormatDescriptor;
  windowStyle, exWindowStyle: DWord;
begin
  Result := False;
  fTerminating := False;
  WindowStyle := ws_OverLappedWindow;
  exWindowStyle := ws_Ex_AppWindow;
  SetRect (WindowRect, 0, 0, fWidth, fHeight);
  
  // Initialise PixelFormatDescriptor
  FillChar (pfd, sizeof (pfd), 0);
  pfd.nSize           := sizeof (pfd);
  pfd.nVersion        := 1;
  pfd.dwFlags         := pfd_Draw_To_Window or pfd_Support_OpenGL or pfd_DoubleBuffer;
  pfd.iPixelType      := pfd_Type_RGBA;
  pfd.cColorBits      := fBitsPerPixel;
  pfd.cDepthBits      := 16;
  pfd.iLayerType      := pfd_Main_Plane;
  
  // If full-screen mode requested, try changing video mode
  if fFullScreen then begin
  if not ChangeScreenResolution then begin
  // Fullscreen Mode Failed.  Run In Windowed Mode Instead
  MessageBox (0, 'Sorry: full-screen mode not available.', 'Error', mb_Ok or mb_IconExclamation);
  fFullScreen := False;
  end else begin
  WindowStyle := ws_PopUp;
  exWindowStyle := exWindowStyle or ws_Ex_TopMost;
  end
  
  // If not full-screen mode, adjust window rectangle to allow for borders.																// (Top Window Covering Everything Else)
  end else AdjustWindowRectEx (WindowRect, WindowStyle, False, ExWindowStyle);
  
  // Centre the window
  X := (GetSystemMetrics (sm_CxScreen) - (WindowRect.Right - WindowRect.Left)) div 2;
  Y := (GetSystemMetrics (sm_CyScreen) - (WindowRect.Bottom - WindowRect.Top)) div 2;
  
  // Create the API-level window
  
  fHWnd := CreateWindowEx (ExWindowStyle, PChar (fClassName), PChar (fWindowTitle),
            WindowStyle, X, Y, WindowRect.Right - WindowRect.Left,
            WindowRect.Bottom - WindowRect.Top, 0, 0,									// No Menu
            hInstance, Nil);
  try
  if fHWnd = 0 then Exit;
  SetWindowLong (fHWnd, gwl_UserData, Integer (Self));
  
  fHDC := GetDC (fHWnd);
  if fHDC = 0 then Exit;
  
  // Choose a compatible pixel format
  PixelFormat := ChoosePixelFormat (fHDC, @pfd);
  if PixelFormat = 0 then Exit;
  
  // Set the pixel format
  if not SetPixelFormat (fHDC, PixelFormat, @pfd) then Exit;
  
  // Create the rendering format
  fHRC := wglCreateContext (fHDC);
  if fHRC = 0 then Exit;
  
  // Make the Rendering Context current
  if not wglMakeCurrent (fHDC, fHRC) then Exit;
  
  // Looks like we're in business...
  ShowWindow (fHWnd, sw_Normal);
  SetForegroundWindow (fHWnd);
  fIsVisible := True;
  ReshapeGL (fWidth, fHeight);
  fLastTickCount := GetTickCount;
  Result := True;
  finally
  if Result = False then begin
  if fHRC <> 0 then wglDeleteContext (fHRC);
  if fHDC <> 0 then ReleaseDC (fHWnd, fHDC);
  if fHWnd <> 0 then DestroyWindow (fHWnd);
  fHRC := 0;  fHDC := 0;  fHWnd := 0;
  end;
  end;
end;

function TGLBase.DoInit: Boolean;
begin
  glShadeModel (gl_Smooth);
  glClearColor (0.0, 0.0, 0.0, 0.5);
  glClearDepth (1.0);
  glEnable (gl_Depth_Test);
  glDepthFunc (gl_Less);
  glHint (gl_Perspective_Correction_Hint, gl_Nicest);
  FTerminating := False;
  Result := True;
end;

procedure TGLBase.DoUnInit;
begin
end;

procedure TGLBase.Execute;
begin
  if not RegisterWindowClass then
  begin
    MessageBox (0, 'Error Registering Window Class', 'Error', mb_Ok or mb_IconExclamation);
    Exit;
  end;
  
  fCreateFullScreen := fFullScreen;
  while not fTerminating do
  begin
    fFullScreen := fCreateFullScreen;
    if CreateWindowGL then
    begin
      if DoInit then
        PumpMessages
      else
        TerminateApplication;
      DoUnInit;
      Cleanup;
    end
    else
    begin
      fTerminating := True;
      MessageBox (0, 'Error Creating OpenGL Window', 'Error', mb_Ok or mb_IconExclamation);
    end;
  end;
end;

procedure TGLBase.KeyPress(KeyCode: Integer; IsDown: Boolean);
begin
end;

procedure TGLBase.PumpMessages;
var
  Msg: TMsg;
  var ticksNow: DWord;
begin
  while True do
  begin
    if PeekMessage (Msg, fHWnd, 0, 0, pm_Remove) then
    begin
      // Check For WM_QUIT Message
      if Msg.message = wm_Quit then
        Exit
      else
        DispatchMessage (Msg);
    end
    else
      if not fIsVisible then
        WaitMessage
      else
      begin
        // Process Application Loop
        ticksNow := GetTickCount;
        Update (ticksNow - fLastTickCount);
        fLastTickCount := ticksNow;
        Draw;
        SwapBuffers (fHDC);
      end;
  end;
end;

function TGLBase.RegisterWindowClass: Boolean;
var
  cls: TWndClassEx;
begin
  FillChar (cls, sizeof (cls), 0);
  with cls do
  begin
    cbSize          := sizeof (cls);
    style           := cs_hRedraw or cs_vRedraw or cs_OwnDC;
    hInstance    	:= SysInit.hInstance;
    hbrBackground	:= Color_AppWorkSpace;
    hCursor         := LoadCursor (0, idc_Arrow);
    lpszClassName	:= PChar (fClassName);
    lpfnWndProc	:= @TGLBaseWindowProc;
  end;
  Result := RegisterClassEx (cls) <> 0;
end;

procedure TGLBase.ReshapeGL(Width, Height: Integer);
begin
  if Height = 0 then Height := 1;
  
  // Reset the current viewport
  glViewport (0, 0, Width, Height);
  
  // Select the projection matrix, and reset it
  glMatrixMode (GL_PROJECTION);
  glLoadIdentity;
  
  fWidth := Width; fHeight := Height;
  // Recalculate the window's aspect ration
  gluPerspective (45.0, Width / Height, 1.0, 100.0);
  
  // Select the modelview matrix, and reset it
  glMatrixMode (gl_ModelView);
  glLoadIdentity;
end;

procedure TGLBase.TerminateApplication;
begin
  PostMessage (fHWnd, wm_Quit, 0, 0);
  fTerminating := True;
end;

procedure TGLBase.ToggleFullScreen;
begin
  PostMessage (fHWnd, wm_ToggleFS, 0, 0);
end;

procedure TGLBase.Update(milliSeconds: DWord);
begin
end;

procedure TGLBase.SetTitle(const Value: string);
begin
  if fWindowTitle <> Value then
  begin
    fWindowTitle := Value;
  end;
  FTerminating  := False;
end;

procedure TGLBase.WMClose(var Message: TWMClose);
var
  Msg: TMsg;
begin
  CleanUp;
  Msg.Message := Wm_close;
  DispatchMessage(Msg);
end;

end.
