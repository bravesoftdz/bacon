unit uBaconGL;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, OpenGL, GLBase, GLAux, uBaconTypes;

type
  TGLKotik = class (TGLBase)
  private
    fBlending: Boolean;
    filter: Integer;
    fLighting: Boolean;
    FTextureFile: string;
    FxSpeed: GLFloat;
    texture: array [0..2] of Integer;
    xrot: GLfloat;
    yrot: GLfloat;
    ySpeed: GLfloat;
    z: GLfloat;
  protected
    function DoInit: Boolean; override;
    procedure Draw; override;
    procedure KeyPress(KeyCode: Integer; IsDown: Boolean); override;
  public
    property TextureFile: string read FTextureFile write FTextureFile;
    property xSpeed: GLFloat read FxSpeed write FxSpeed;
  end;
  
  TBGLFrame = class (TBBaseType)
  private
    FGL: TGLKotik;
  public
    destructor Destroy; override;
    function Create: TBBaseType; override;
    class function GetName: string; override;
  published
    procedure Execute;
    procedure SetTextureFile(Sender : TObject; Params : TStrings);
    procedure SetTitle(Sender : TObject; Params : TStrings);
    procedure SetXSpeed(Sender : TObject; Params : TStrings);
  end;
  

procedure Register;

implementation

procedure Register;
begin
end;

{
**************************************** TGLKotik ****************************************
}
function TGLKotik.DoInit: Boolean;
  
  const
      LightAmbient: array [0..3] of GLFloat  = ( 0.5, 0.5, 0.5, 1.0 );
      LightDiffuse: array [0..3] of GLFloat  = ( 1.0, 1.0, 1.0, 1.0 );
      LightPosition: array [0..3] of GLFloat = ( 0.0, 0.0, 2.0, 1.0 );
  var
      TextureImage: PTAUX_RGBImageRec;
  
begin
  inherited DoInit;
  z := -5.0;
  TextureImage := auxDIBImageLoadA(PChar(FTextureFile));
  Result := TextureImage <> Nil;
  if Result then
  begin
    glGenTextures (3, @texture);
  
    // First texture
    glBindTexture (gl_Texture_2D, texture[0]);
    glTexParameteri (gl_Texture_2D, gl_Texture_Min_Filter, gl_Nearest);
    glTexParameteri (gl_Texture_2D, gl_Texture_Mag_Filter, gl_Nearest);
    glTexImage2D (gl_Texture_2D, 0, 3, TextureImage^.sizeX, TextureImage^.sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage^.data);
  
    // Second texture
    glBindTexture (gl_Texture_2D, texture[1]);
    glTexParameteri (gl_Texture_2D, gl_Texture_Min_Filter, gl_Linear);
    glTexParameteri (gl_Texture_2D, gl_Texture_Mag_Filter, gl_Linear);
    glTexImage2D (gl_Texture_2D, 0, 3, TextureImage^.sizeX, TextureImage^.sizeY, 0, GL_RGB, GL_UNSIGNED_BYTE, TextureImage^.data);
  
    // Third texture
    glBindTexture (gl_Texture_2D, texture[2]);
    glTexParameteri (gl_Texture_2D, gl_Texture_Min_Filter, gl_Linear_MipMap_Nearest);
    glTexParameteri (gl_Texture_2D, gl_Texture_Mag_Filter, gl_Linear);
    GLBase.gluBuild2DMipmaps (gl_Texture_2D, 3, TextureImage^.sizeX, TextureImage^.sizeY, GL_RGB, GL_UNSIGNED_BYTE, TextureImage^.data);
  
    // Enable textures
    glEnable (gl_Texture_2D);
  
    // Set up the lighting
    glLightfv (GL_LIGHT1, GL_AMBIENT, @LightAmbient[0]);		     	// Setup The Ambient Light
    glLightfv (GL_LIGHT1, GL_DIFFUSE, @LightDiffuse[0]);		     	// Setup The Diffuse Light
    glLightfv (GL_LIGHT1, GL_POSITION, @LightPosition[0]);			// Position The Light
    glEnable (GL_LIGHT1);							// Enable Light One
   // Set up blending
    glColor4f (1.0, 1.0, 1.0, 0.5);	                        		// Full Brightness, 50% Alpha
    glBlendFunc (GL_SRC_ALPHA,GL_ONE);		                        // Blending Function For Translucency Based On Source Alpha Valu
  end;
end;

procedure TGLKotik.Draw;
begin
  glClear (gl_Color_Buffer_Bit or gl_Depth_Buffer_Bit);      		// Clear Screen And Depth Buffer
  glLoadIdentity;							// Reset The Current Matrix
  glTranslatef (0.0, 0.0, z);  			      		// Move Into The Screen by 'z'
  glRotatef (xrot,1.0,0.0,0.0);			      		// Rotate On The X Axis
  glRotatef (yrot,0.0,1.0,0.0);			      		// Rotate On The Y Axis
  glBindTexture (gl_Texture_2D, texture[filter]); 			// Select Our Texture
  
  glBegin(GL_QUADS);
  // Front Face
  glNormal3f (0.0, 0.0, 1.0);					// Normal Pointing Towards Viewer
  glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, -1.0,  1.0);	        // Bottom Left Of The Texture and Quad
  glTexCoord2f(1.0, 0.0); glVertex3f( 1.0, -1.0,  1.0);	        // Bottom Right Of The Texture and Quad
  glTexCoord2f(1.0, 1.0); glVertex3f( 1.0,  1.0,  1.0);	        // Top Right Of The Texture and Quad
  glTexCoord2f(0.0, 1.0); glVertex3f(-1.0,  1.0,  1.0);	        // Top Left Of The Texture and Quad
  
  // Back Face
  glNormal3f (0.0, 0.0, -1.0);					// Normal Pointing Away From Viewer
  glTexCoord2f(1.0, 0.0); glVertex3f(-1.0, -1.0, -1.0);	        // Bottom Right Of The Texture and Quad
  glTexCoord2f(1.0, 1.0); glVertex3f(-1.0,  1.0, -1.0);	        // Top Right Of The Texture and Quad
  glTexCoord2f(0.0, 1.0); glVertex3f( 1.0,  1.0, -1.0);	        // Top Left Of The Texture and Quad
  glTexCoord2f(0.0, 0.0); glVertex3f( 1.0, -1.0, -1.0);	        // Bottom Left Of The Texture and Quad
  
  // Top Face
  glNormal3f (0.0, 1.0, 0.0);					// Normal Pointing Up
  glTexCoord2f(0.0, 1.0); glVertex3f(-1.0,  1.0, -1.0);	        // Top Left Of The Texture and Quad
  glTexCoord2f(0.0, 0.0); glVertex3f(-1.0,  1.0,  1.0);   	// Bottom Left Of The Texture and Quad
  glTexCoord2f(1.0, 0.0); glVertex3f( 1.0,  1.0,  1.0);	        // Bottom Right Of The Texture and Quad
  glTexCoord2f(1.0, 1.0); glVertex3f( 1.0,  1.0, -1.0);	        // Top Right Of The Texture and Quad
  
  // Bottom Face
  glNormal3f (0.0 ,-1.0, 0.0);					// Normal Pointing Down
  glTexCoord2f(1.0, 1.0); glVertex3f(-1.0, -1.0, -1.0);	        // Top Right Of The Texture and Quad
  glTexCoord2f(0.0, 1.0); glVertex3f( 1.0, -1.0, -1.0);	        // Top Left Of The Texture and Quad
  glTexCoord2f(0.0, 0.0); glVertex3f( 1.0, -1.0,  1.0);	        // Bottom Left Of The Texture and Quad
  glTexCoord2f(1.0, 0.0); glVertex3f(-1.0, -1.0,  1.0);	        // Bottom Right Of The Texture and Quad
  
  // Right face
  glNormal3f (1.0, 0.0, 0.0);					// Normal Pointing Right
  glTexCoord2f(1.0, 0.0); glVertex3f( 1.0, -1.0, -1.0);	        // Bottom Right Of The Texture and Quad
  glTexCoord2f(1.0, 1.0); glVertex3f( 1.0,  1.0, -1.0);	        // Top Right Of The Texture and Quad
  glTexCoord2f(0.0, 1.0); glVertex3f( 1.0,  1.0,  1.0);	        // Top Left Of The Texture and Quad
  glTexCoord2f(0.0, 0.0); glVertex3f( 1.0, -1.0,  1.0);	        // Bottom Left Of The Texture and Quad
  
  // Left Face
  glNormal3f (-1.0, 0.0, 0.0);					// Normal Pointing Left
  glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, -1.0, -1.0);	        // Bottom Left Of The Texture and Quad
  glTexCoord2f(1.0, 0.0); glVertex3f(-1.0, -1.0,  1.0);	        // Bottom Right Of The Texture and Quad
  glTexCoord2f(1.0, 1.0); glVertex3f(-1.0,  1.0,  1.0);	        // Top Right Of The Texture and Quad
  glTexCoord2f(0.0, 1.0); glVertex3f(-1.0,  1.0, -1.0);	        // Top Left Of The Texture and Quad
  glEnd;
  
  xrot := xrot + xspeed;  						// X Axis Rotation
  yrot := yrot + yspeed;  						// Y Axis Rotation
end;

procedure TGLKotik.KeyPress(KeyCode: Integer; IsDown: Boolean);
begin
  if IsDown then
    case KeyCode of
      Ord('b'), Ord('B'):
        if fBlending then
        begin
          glDisable (gl_Blend);
          glEnable (gl_Depth_Test);
          fBlending := False;
        end
        else
        begin
          glEnable (gl_Blend);
          glDisable (gl_Depth_Test);
          fBlending := True;
        end;
  
      Ord('l'), Ord('L'):
        if fLighting then
        begin
          glDisable (gl_Lighting);
          fLighting := False;
        end
        else
        begin
          glEnable (gl_Lighting);
          fLighting := True;
        end;
  
      Ord('f'), Ord('F'):
        Filter := (Filter + 1) mod 3;
  
      vk_Next:                z := z + 0.02;
      vk_Prior:               z := z - 0.02;
      vk_Up:                  xspeed := xSpeed - 0.01;
      vk_Down:                xSpeed := xSpeed + 0.01;
      vk_Left:                ySpeed := ySpeed - 0.01;
      vk_Right:               ySpeed := ySpeed + 0.01;
    end;
end;

{
*************************************** TBGLFrame ****************************************
}
destructor TBGLFrame.Destroy;
begin
  FGL.Free;
  inherited Destroy;
end;

function TBGLFrame.Create: TBBaseType;
begin
  Result := inherited Create;
  FGL := TGLKotik.Create;
end;

procedure TBGLFrame.Execute;
begin
  FGL.Execute;
end;

class function TBGLFrame.GetName: string;
begin
  Result := 'TBGLFrame';
end;

procedure TBGLFrame.SetTextureFile(Sender : TObject; Params : TStrings);
begin
  FGL.TextureFile := Params[0];
end;

procedure TBGLFrame.SetTitle(Sender : TObject; Params : TStrings);
begin
  FGL.Title := Params[0];
end;

procedure TBGLFrame.SetXSpeed(Sender : TObject; Params : TStrings);
var
  Temp: Double;
begin
  Temp := StrToFloat(Params[0]);
  FGL.XSpeed := Temp;
end;


initialization
end.
