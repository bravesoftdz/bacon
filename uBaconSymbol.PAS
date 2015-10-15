unit uBaconSymbol;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Contnrs, uBaconTypes;

type
  
  TBTypeRef = class of TBBaseType;
  TBSymbolTable = class;
  
  TBSymbol = class (TObject)
  private
    FBCategory: TSymbolCategory;
    FBContext: TBContext;
    FBName: string;
    FBScope: TSymbolScope;
    FBType: TBBaseType;
    FParams: TBSymbolTable;
    function GetBCategory: TSymbolCategory;
    function GetBContext: TBContext;
    function GetBName: string;
    function GetBScope: TSymbolScope;
    function GetBType: TBBaseType;
    procedure SetBCategory(const Value: TSymbolCategory);
    procedure SetBContext(const Value: TBContext);
    procedure SetBName(const Value: string);
    procedure SetBScope(const Value: TSymbolScope);
    procedure SetBType(const Value: TBBaseType);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CopyTo(var NewSymbol : TBSymbol);
    function GetValue: Variant;
    procedure SetValue(Value: Variant);
    property BCategory: TSymbolCategory read GetBCategory write SetBCategory;
    property BContext: TBContext read GetBContext write SetBContext;
    property BName: string read GetBName write SetBName;
    property BScope: TSymbolScope read GetBScope write SetBScope;
    property BType: TBBaseType read GetBType write SetBType;
    property Params: TBSymbolTable read FParams write FParams;
    property Value: Variant read GetValue write SetValue;
  end;
  
  TBSymbolTable = class (TObject)
  private
    FInternalTable: array[1..1000] of TBSymbol;
    FPosition: Integer;
    function DoAddSymbol(const SymName : string; const SymType : TBBaseType; const  
        SymContext : TBContext; const SymScope : TSymbolScope; const SymCat : 
        TSymbolCategory): TBSymbol;
    procedure DoClear(const FromItem, ToItem : integer);
    function GetFirst: Integer;
    function GetLast: Integer;
    function GetSymbols(Index: Integer): TBSymbol;
    procedure Init;
  public
    constructor Create;
    destructor Destroy; override;
    function AddFunction(const FuncName : string; const FuncType : TBBaseType; const  
        FuncContext : TBContext; const FuncScope : TSymbolScope): TBSymbol;
    function AddInternalFunction(const FuncName : string; const FuncType : TBBaseType): 
        TBSymbol;
    function AddParam(const ParamName : string; const ParamType : TBBaseType; const  
        ParamContext : TBContext; const ParamScope : TSymbolScope): TBSymbol;
    procedure AddParams(const ParamsTable : TBSymbolTable;  const ParamContext :  
        TBContext; const ParamScope : TSymbolScope);
    function AddVar(const VarName : string; const VarType : TBBaseType; const VarContext  
        : TBContext; const VarScope : TSymbolScope): TBSymbol;
    procedure Clear;
    procedure ClearFromBookmark(const FromBookmark : integer);
    procedure CopyTo(var NewTable : TBSymbolTable);
    function GetBookmark: Integer;
    function GetSymbol(const SymName : string): TBSymbol;
    property First: Integer read GetFirst;
    property Last: Integer read GetLast;
    property Position: Integer read FPosition;
    property Symbols[Index: Integer]: TBSymbol read GetSymbols; default;
  end;
  

procedure Register;

implementation

const
  sErrSymbolDuplicate = 'Duplicate symbol %s';
    
procedure Register;
begin
end;

{
**************************************** TBSymbol ****************************************
}
constructor TBSymbol.Create;
begin
  inherited Create;
  FParams  := TBSymbolTable.Create;
end;

destructor TBSymbol.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

procedure TBSymbol.CopyTo(var NewSymbol : TBSymbol);
begin
  NewSymbol := TBSymbol.Create;
  NewSymbol.BCategory := BCategory;
  NewSymbol.BContext  := BContext;
  NewSymbol.BName     := BName;
  NewSymbol.BScope    := BScope;
  NewSymbol.BType     := BType;
  NewSymbol.Value     := Value;
  if Params <> nil then
    Params.CopyTo(NewSymbol.FParams);
end;

function TBSymbol.GetBCategory: TSymbolCategory;
begin
  Result := FBCategory;
end;

procedure TBSymbol.SetBCategory(const Value: TSymbolCategory);
begin
  if FBCategory <> Value then
  begin
    FBCategory := Value;
  end;
end;

function TBSymbol.GetBContext: TBContext;
begin
  Result := FBContext;
end;

procedure TBSymbol.SetBContext(const Value: TBContext);
begin
    FBContext := Value;
end;

function TBSymbol.GetBName: string;
begin
  Result := FBName;
end;

procedure TBSymbol.SetBName(const Value: string);
begin
  if FBName <> Value then
  begin
    FBName := Value;
  end;
end;

function TBSymbol.GetBScope: TSymbolScope;
begin
  Result := FBScope;
end;

procedure TBSymbol.SetBScope(const Value: TSymbolScope);
begin
  if FBScope <> Value then
  begin
    FBScope := Value;
  end;
end;

function TBSymbol.GetBType: TBBaseType;
begin
  Result := FBType;
end;

procedure TBSymbol.SetBType(const Value: TBBaseType);
begin
  if FBType <> Value then
  begin
    FBType := Value;
  //  FTypeInstance := FBType.Create;
  end;
end;

function TBSymbol.GetValue: Variant;
begin
  Result := FBType.Value;
end;

procedure TBSymbol.SetValue(Value: Variant);
begin
  FBType.SetValue(Value);
end;

{
************************************* TBSymbolTable **************************************
}
constructor TBSymbolTable.Create;
begin
  inherited Create;
  // TODO:
  // FInternalTable := TObjectList.Create;
  // FInternalTable.OwnsObjects := True;
  Init;
end;

destructor TBSymbolTable.Destroy;
begin
  // TODO: FreeAndNil(FInternalTable);
  inherited Destroy;
end;

function TBSymbolTable.AddFunction(const FuncName : string; const FuncType : TBBaseType; 
    const  FuncContext : TBContext; const FuncScope : TSymbolScope): TBSymbol;
begin
  Result := DoAddSymbol(FuncName, FuncType, FuncContext, FuncScope, scFunc);
end;

function TBSymbolTable.AddInternalFunction(const FuncName : string; const FuncType : 
    TBBaseType): TBSymbol;
begin
  Result := DoAddSymbol(FuncName, FuncType, cNullContext, scGlobal, scFunc);
end;

function TBSymbolTable.AddParam(const ParamName : string; const ParamType : TBBaseType; 
    const  ParamContext : TBContext; const ParamScope : TSymbolScope): TBSymbol;
begin
  Result := DoAddSymbol(ParamName, ParamType, ParamContext, ParamScope, scParam);
end;

procedure TBSymbolTable.AddParams(const ParamsTable : TBSymbolTable;  const ParamContext 
    :  TBContext; const ParamScope : TSymbolScope);
var
  I: Integer;
begin
  for i:=ParamsTable.First to ParamsTable.Position do
    if Assigned(ParamsTable[i]) then
      AddVar(ParamsTable[i].BName, ParamsTable[i].BType, ParamContext, ParamScope);
end;

function TBSymbolTable.AddVar(const VarName : string; const VarType : TBBaseType; const 
    VarContext  : TBContext; const VarScope : TSymbolScope): TBSymbol;
begin
  Result := DoAddSymbol(VarName, VarType, VarContext, VarScope, scVar);
end;

procedure TBSymbolTable.Clear;
begin
  Init;
end;

procedure TBSymbolTable.ClearFromBookmark(const FromBookmark : integer);
begin
  DoClear(FromBookmark, high(FInternalTable));
end;

procedure TBSymbolTable.CopyTo(var NewTable : TBSymbolTable);
var
  I: Integer;
  TempSymbol: TBSymbol;
begin
  NewTable := TBSymbolTable.Create;
  // TODO: Ottimizzare sostituendo high con position ?
  for i:=low(FInternalTable) to high(FInternalTable) do
    if Assigned(FInternalTable[i]) then
      if FInternalTable[i].BScope = scGlobal then
      begin
        FInternalTable[i].CopyTo(TempSymbol);
        NewTable.FInternalTable[i] := TempSymbol;
        NewTable.FPosition := i;
      end;
end;

function TBSymbolTable.DoAddSymbol(const SymName : string; const SymType : TBBaseType; 
    const  SymContext : TBContext; const SymScope : TSymbolScope; const SymCat : 
    TSymbolCategory): TBSymbol;
var
  NewSymbol: TBSymbol;
begin
  if GetSymbol(SymName) <> nil then
    raise Exception.Create(Format(sErrSymbolDuplicate,[SymName]))
  else
  begin
    NewSymbol := TBSymbol.Create;
    with NewSymbol do
    begin
      BType     := SymType;
      BName     := SymName;
      BContext  := SymContext;
      BScope    := SymScope;
      BCategory := SymCat;
      FInternalTable[FPosition] := NewSymbol;
      inc(FPosition);
    end;
    Result := NewSymbol;
  end;
end;

procedure TBSymbolTable.DoClear(const FromItem, ToItem : integer);
var
  I: Integer;
begin
  for i:=FromItem to ToItem do
    if (Assigned(FInternalTable[i])) then
      FreeAndNil(FInternalTable[i]);
end;

function TBSymbolTable.GetBookmark: Integer;
begin
  Result := FPosition; // TODO: FInternalTable.Count;
end;

function TBSymbolTable.GetSymbol(const SymName : string): TBSymbol;
var
  I: Integer;
  TempName: string;
begin
  Result := nil;
  // Symbols are case-insensitive..
  TempName := UpperCase(SymName);
  for i:=low(FInternalTable) to high(FInternalTable) do
    if Assigned(FInternalTable[i]) then
      if UpperCase(FInternalTable[i].BName) = TempName then
      begin
        Result := FInternalTable[i];
        exit;
      end;
end;

procedure TBSymbolTable.Init;
var
  I: Integer;
begin
  FPosition := low(FInternalTable);
  DoClear(low(FInternalTable), high(FInternalTable));
end;

function TBSymbolTable.GetFirst: Integer;
begin
  Result := low(FInternalTable);
end;

function TBSymbolTable.GetLast: Integer;
begin
  Result := high(FInternalTable);
end;

function TBSymbolTable.GetSymbols(Index: Integer): TBSymbol;
begin
  Result := FInternalTable[Index];
end;


initialization
end.
