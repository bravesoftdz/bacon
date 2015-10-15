unit uBStandardTypes;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, {uBaconSymbol,} uBaconTypes;

type
  TBVoid = class (TBBaseType)
  public
    function Create: TBBaseType; override;
    class function GetName: string; override;
  end;
  
  TBDate = class (TBBaseType)
  private
    FValue: Double;
  public
    function Create: TBBaseType; override;
    class function GetName: string; override;
    procedure SetValue(Value: Variant); override;
  end;
  
  TBNumber = class (TBBaseType)
  private
    FValue: Double;
  public
    function Add(const VarLeft, VarRight : variant): Variant; override;
    function Create: TBBaseType; override;
    class function GetName: string; override;
    function GetValue: Variant; override;
    procedure SetValue(Value: Variant); override;
    function Subtract(const VarLeft, VarRight : Variant): Variant; override;
  end;
  
  TBString = class (TBBaseType)
  private
    FValue: string;
  public
    function Create: TBBaseType; override;
    class function GetName: string; override;
    function GetValue: Variant; override;
    procedure SetValue(Value: Variant); override;
  published
    procedure ShowMessage(Sender : TObject; Params : TStrings);
  end;
  
  
procedure Register;

implementation

procedure Register;
begin
end;

{
***************************************** TBVoid *****************************************
}
function TBVoid.Create: TBBaseType;
begin
  Result := inherited Create;
end;

class function TBVoid.GetName: string;
begin
  Result := 'void';
end;

{
***************************************** TBDate *****************************************
}
function TBDate.Create: TBBaseType;
begin
  Result := inherited Create;
  FValue := 0.0;
end;

class function TBDate.GetName: string;
begin
  Result := 'DATE';
end;

procedure TBDate.SetValue(Value: Variant);
begin
  inherited SetValue(Value);
  FValue := Value;
end;

{
**************************************** TBNumber ****************************************
}
function TBNumber.Add(const VarLeft, VarRight : variant): Variant;
var
  Temp: Double;
begin
  Temp := VarAsType(VarLeft, varDouble) + VarAsType(VarRight, varDouble);
  Result := Temp;
end;

function TBNumber.Create: TBBaseType;
begin
  Result := inherited Create;
  FValue := 0.0;
end;

class function TBNumber.GetName: string;
begin
  Result := 'NUMBER';
end;

function TBNumber.GetValue: Variant;
begin
  Result := inherited GetValue;
  Result := FValue;
end;

procedure TBNumber.SetValue(Value: Variant);
begin
  inherited SetValue(Value);
  FValue := Value;
end;

function TBNumber.Subtract(const VarLeft, VarRight : Variant): Variant;
var
  Temp: Double;
begin
  Temp := VarAsType(VarLeft, varDouble) - VarAsType(VarRight, varDouble);
  Result := Temp;
end;

{
**************************************** TBString ****************************************
}
function TBString.Create: TBBaseType;
begin
  Result := inherited Create;
  FValue := '';
end;

class function TBString.GetName: string;
begin
  Result := 'STRING';
end;

function TBString.GetValue: Variant;
begin
  Result := inherited GetValue;
  Result := FValue;
end;

procedure TBString.SetValue(Value: Variant);
begin
  inherited SetValue(Value);
  FValue := Value;
end;

procedure TBString.ShowMessage(Sender : TObject; Params : TStrings);
begin
  Dialogs.ShowMessage(Params[0]);
end;


initialization
end.
