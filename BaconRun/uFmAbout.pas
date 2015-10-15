unit uFmAbout;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  VersInfo, StdCtrls, jpeg, ExtCtrls, Buttons;

type
  TFmAbout = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    dfsVersionInfoResource: TdfsVersionInfoResource;
    LblProduct: TLabel;
    LblDescription: TLabel;
    LblVersion: TLabel;
    LblCopy: TLabel;
    BitBtn1: TBitBtn;
    Label2: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FmAbout: TFmAbout;

implementation

{$R *.DFM}

end.
