unit uBaconIntf;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs;

type
  IBaconBaseType = interface (IUnknown)
    procedure Add(RValue : IBaconBaseType); safecall;
    procedure Divide(RValue : IBaconBaseType); safecall;
    procedure Multiply(RValue : IBaconBaseType); safecall;
    procedure Subtract(RValue : IBaconBaseType); safecall;
  end;
  

procedure Register;

implementation

procedure Register;
begin
end;


initialization
end.
