unit uBacon;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Contnrs, 
  uBaconTypes;
//  uBaconSymbol;

type
  TBacon = class (TComponent)
  private
    FBuffer: string;
    FBufferLen: Integer;
    FCode: TStringList;
    FComment: string;
    FContextTable: TBContextTable;
    FCurrContext: TBContext;
    FEof: Boolean;
    FInput: string;
    FLValue: TBSymbol;
    FOutput: string;
    FParsed: Boolean;
    FRegisteredClassTypes: TClassList;
    FStdOut: TStringList;
    FSymbolTable: TBSymbolTable;
    FTitle: string;
    procedure Abort(const Msg : string);
    function BindParams(var Execute : TExecutionState; OwnerFunction : TBSymbol; const    
        FunctionName : string): Boolean;
    function BoolExpression(var Execute : TExecutionState): Variant;
    function BoolOr(var Execute : TExecutionState): Variant;
    function BoolTerm(var Execute : TExecutionState): Variant;
    function BoolXOr(var Execute : TExecutionState): Variant;
    procedure ClearCurrContext;
    procedure CreateParam(FuncSymbol : TBSymbol; const FuncName : string);
    procedure DoAssignment(var Execute : TExecutionState);
    procedure DoFuncCall(var Execute : TExecutionState);
    procedure DoIf(var Execute : TExecutionState);
    procedure DoWhile(var Execute : TExecutionState);
    procedure Error(const Msg : string);
    function Evaluator(var Execute : TExecutionState): Variant;
    function Expression(var Execute : TExecutionState): Variant;
    function Factor(var Execute : TExecutionState): Variant;
    procedure GetChar;
    function GetCurrContext: TBContext;
    function GetCurrLine: string;
    function GetCurrLook: Char;
    function GetCurrLValue: TBSymbol;
    function GetCurrPointer: Integer;
    function GetCurrStatement: TStatementType;
    function GetCurrToken: TTokenType;
    function GetCurrValue: string;
    procedure GetIdentifier;
    procedure GetNextToken;
    procedure GetNumber;
    procedure GetStatement;
    procedure GetStringConstant;
    procedure IdentifierToTokenType;
    procedure IncLineNumber;
    procedure IncPointer;
    procedure Init;
    function IsAssignment: Boolean;
    function IsCurrValueFunction(const Name : string): Boolean;
    function IsFuncCall: Boolean;
    function IsFuncDecl: Boolean;
    function LookNextChar: Char;
    function LookNextToken: string;
    procedure MatchChar(const ExpectedChar : char);
    procedure MatchString(const ExpectedString : string);
    function NotFactor(var Execute : TExecutionState): Variant;
    procedure ParseBlock(var Execute : TExecutionState);
    procedure ParseHeader;
    procedure ParseProgram;
    procedure PopContext;
    procedure PushContext;
    procedure ReadFormalParams(var Execute : TExecutionState; const CreateParams :      
        boolean; FuncSymbol : TBSymbol; const FuncName : string);
    procedure ReadFunc(var Execute : TExecutionState; Scope : TSymbolScope);
    procedure ReadVar(Scope : TSymbolScope);
    function Relation(var Execute : TExecutionState): Variant;
    function RunFunc(var Execute : TExecutionState; const FunctionName : string): Variant;
    procedure SetCurrContext(NewContext : TBContext);
    procedure SetCurrLValue(const LValue : TBSymbol);
    procedure SetCurrStatement(NewStatementType : TStatementType);
    procedure SetCurrToken(NewToken: TTokenType);
    procedure SetCurrValue(const NewValue : string);
    procedure SetEof;
    function SkipLine: string;
    procedure SkipWhite;
    function StrToBType(const sType : string): TBBaseType;
    function Term(var Execute : TExecutionState): Variant;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    function EvalTestCondition: Boolean;
    function GetValue(const VarName : string): Variant;
    procedure LoadProgramFile(const FileName : string);
    procedure RegisterType(aNewTypeRef : TBTypeRef);
    procedure Run;
    procedure SetCode(Code : TStrings);
    property Parsed: Boolean read FParsed write FParsed;
  published
    property Code: TStringList read FCode write FCode;
    property Comment: string read FComment write FComment;
    property Input: string read FInput write FInput;
    property Output: string read FOutput write FOutput;
    property StdOut: TStringList read FStdOut write FStdOut;
    property Title: string read FTitle write FTitle;
  end;
  
  TTestCondition = class (TObject)
  private
    FCurrCondition: string;
    FEof: Boolean;
    FSymbolTable: TBSymbolTable;
    FTestCondition: string;
    FWorkString: string;
    function Str2Double(const sDouble : string): Double;
  public
    constructor Create(const TestCondition : string; const SymbolTable : TBSymbolTable);
    function Eval: Boolean;
    procedure First;
    procedure Next;
    property Eof: Boolean read FEof write FEof;
  end;
  

const
  _BACON_EXT = 'bac';
  
procedure Register;

implementation

uses
  xProcs;
  
type
  TBaconMethod = procedure (Sender : TObject; Params : TStrings) of object;
  
const
  TAB = ^I;
  CR  = ^M;
  LF  = ^J;
  cDecimalSeparator = '.';
  cMinus        = '-';
  cStartComment = '#';
  sErrVarUndefined    = 'Undefined variable %s';
  cQuoteChar = '''';
  
procedure Register;
begin
end;


{ Recognize an Alpha Character }
function IsAlpha(c: char): boolean;
begin
   IsAlpha := UpCase(c) in ['A'..'Z'];
end;

{ Recognize a Decimal Digit }
function IsDigit(c: char): Boolean;
begin
  Result := c in ['0'..'9'];
end;

{ Recognize an AlphaNumeric Character }
function IsAlNum(c: char): boolean;
begin
  IsAlNum := IsAlpha(c) or IsDigit(c);
end;

{ Recognize White Space }
function IsWhite(c: char): boolean;
begin
   IsWhite := c in [' ', TAB, CR, LF, '#'];
end;

function IsSpecial(c: char): boolean;
begin
   Result := c in ['(', ')'];
end;

function IsOrOp(c : string) : boolean;
begin
  IsOrOp := c = 'OR';
end;

{--------------------------------------------------------------}
{ Recognize an Addop }
function IsAddop(c: string): boolean;
begin
   IsAddop := c[1] in ['+', '-'];
end;

{--------------------------------------------------------------}
{ Recognize a Mulop }
function IsMulop(c: string): boolean;
begin
   IsMulop := c[1] in ['*', '/'];
end;

function IsRelOp(c : string) : boolean;
begin
  IsRelOp := (c = '=') or
    (c = '<') or
    (c = '>');
end;

{
***************************************** TBacon *****************************************
}
constructor TBacon.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FCode         := TStringList.Create;
  FSymbolTable  := TBSymbolTable.Create;
  FContextTable := TBContextTable.Create;
  FRegisteredClassTypes := TClassList.Create;
  //FRegisteredInstanceTypes := TObjectList.Create;
  //FRegisteredInstanceTypes.OwnsObjects := True;
end;

destructor TBacon.Destroy;
begin
  FreeAndNil(FCode);
  FreeAndNil(FRegisteredClassTypes);
  //FreeAndNil(FRegisteredInstanceTypes);
  FreeAndNil(FSymbolTable);
  FreeAndNil(FContextTable);
  inherited Destroy;
end;

procedure TBacon.Abort(const Msg : string);
begin
  Error(Msg+' at line '+IntToStr(FCurrContext.FLineNum));
  Halt;
end;

function TBacon.BindParams(var Execute : TExecutionState; OwnerFunction : TBSymbol; const 
    FunctionName : string): Boolean;
var
  I: Integer;
  Param: TBSymbol;
begin
  Result := True;
  MatchChar('(');
  if GetCurrLook <> ')' then
  begin
    i := OwnerFunction.Params.First;
    Param := OwnerFunction.Params[i];
    while Param <> nil do
    begin
      Param.Value := Expression(Execute);
      if GetCurrLook=',' then
      begin
        MatchChar(',');
        inc(i);
        if i > OwnerFunction.Params.Position then
          Abort('Troppi parametri');
        Param := OwnerFunction.Params[i];
        Param.Value := Expression(Execute);
        inc(i);
        Param := OwnerFunction.Params[i];
      end
      else
        Param := nil;
    end;
  end;
  if GetCurrLook=')' then
    MatchChar(')');
end;

function TBacon.BoolExpression(var Execute : TExecutionState): Variant;
var
  Temp: string;
begin
  Result := BoolTerm(Execute);
  while IsOrOp(LookNextToken) do
  begin
    GetNextToken;
    Temp := GetCurrValue;
    if Temp = 'OR' then
    begin
      if (BoolOr(Execute) > 0) or (Result > 0) then Result := 1 else Result := 0;
    end
    else
    begin
      if Temp = 'XOR' then
        if (Result > 0) xor (BoolXOr(Execute) > 0) then Result := 1 else Result := 0;
    end;
  end;
end;

function TBacon.BoolOr(var Execute : TExecutionState): Variant;
begin
  GetNextToken;
  Result := BoolTerm(Execute);
end;

function TBacon.BoolTerm(var Execute : TExecutionState): Variant;
begin
  Result := NotFactor(Execute);
  while LookNextToken = 'AND' do
  begin
    GetNextToken;
    MatchString('AND');
    if (Result > 0) and (NotFactor(Execute) > 0) then
      Result := 1
    else
      Result := 0;
  end;
end;

function TBacon.BoolXOr(var Execute : TExecutionState): Variant;
begin
  GetNextToken;
  Result := BoolTerm(Execute);
end;

procedure TBacon.ClearCurrContext;
begin
  with FCurrContext do
  begin
    FPosition  := 1;
    FTokenType := ttNone;
    FValue     := '';
    FLook      := #0;
    FLineNum   := 1;
    FLevel     := 0;
  end;
end;

procedure TBacon.CreateParam(FuncSymbol : TBSymbol; const FuncName : string);
var
  ParamType: TBBaseType;
  ParamName: string;
begin
  ParamType := StrToBType(GetCurrValue);
  if ParamType = nil then Abort('Invalid type name');
  GetNextToken;
  // TODO ripristinare if GetCurrToken <> 'x' then Expected('Parameter name');
  ParamName := GetCurrValue;
  FuncSymbol.Params.AddParam(ParamName, ParamType, GetCurrContext, scGlobal);
end;

procedure TBacon.DoAssignment(var Execute : TExecutionState);
var
  VarName: string;
  SymLValue: TBSymbol;
  TempValue: Variant;
begin
  VarName := GetCurrValue; //FLValue;
  GetNextToken;
  SymLValue := FSymbolTable.GetSymbol(VarName);
  if SymLValue = nil then
    Abort(Format(sErrVarUndefined, [VarName]));
  SetCurrLValue(SymLValue);
  TempValue := Expression(Execute); //GetCurrValue;
  if Execute = esExecute then
    SymLValue.Value := TempValue;
end;

procedure TBacon.DoFuncCall(var Execute : TExecutionState);
var
  ObjName: string;
  PublishedName: string;
  TempSymbol: TBSymbol;
  ObjMethod: TBaconMethod;
  Parameters: TStrings;
  TempMethod: TMethod;
  TempField: Pointer;
  TempString: string;
  
  type
    PString = ^String;
  
begin
  // TODO: creare Exception
  ObjName := GetCurrValue;
  //TempMethod := nil;
  //TempField := nil;
  MatchChar('.');
  TempSymbol := FSymbolTable.GetSymbol(ObjName);
  if TempSymbol = nil then
    raise Exception.Create('TBacon.DoFuncCall: Invalid symbol');
  if TempSymbol.BCategory <> scVar then
    raise Exception.Create('TBacon.DoFuncCall: Invalid variable');
  PublishedName := GetCurrValue;
  Parameters := TStringList.Create;
  TempMethod.Code := TempSymbol.BType.MethodAddress(PublishedName);
  // Se non e' un metodo verifica se e' una property
  if TempMethod.Code = nil then
  begin
    TempField := TempSymbol.BType.FieldAddress(PublishedName);
    if TempField = nil then
      raise Exception.Create('TBacon.DoFuncCall: Invalid method or property');
  end
  // Se e' un metodo legge i parametri
  else
  begin
    MatchChar('(');
    repeat
      Parameters.Add(GetCurrValue);
      GetNextToken;
    until GetCurrLook = ')';
  end;
  MatchChar(')');
  try
    if Execute = gExecute then
    begin
      if TempMethod.Code <> nil then
      begin
        TMethod(ObjMethod).Code := TempMethod.Code;
        TMethod(ObjMethod).Data := TempSymbol.BType;
        if Assigned(ObjMethod) then
          ObjMethod(Self, Parameters)
        else
          raise Exception.Create('TBacon.DoFuncCall: Invalid method');
      end
      else
      begin
        TempString := GetCurrValue;
        PString(TempField)^ := TempString;
      end;
    end;
  finally
    Parameters.Free;
  end;
end;

procedure TBacon.DoIf(var Execute : TExecutionState);
var
  IfTrue: Boolean;
  ThenExecState, ElseExecState: TExecutionState;
begin
  GetNextToken;
  if Execute = esExecute then
    IfTrue := BoolExpression(Execute) > 0
  else
  begin
    BoolExpression(Execute);  // Si mangia, come al solito, l'espressione
    IfTrue := False;
  end;
  if IfTrue then
  begin
    ThenExecState := esExecute;
    ElseExecState := esNoExecute;
  end
  else
  begin
    ThenExecState := esNoExecute;
    ElseExecState := esExecute;
  end;
  ParseBlock(ThenExecState);
  if ThenExecState = esBreak then
    Execute := ThenExecState;
  if GetCurrToken = ttElse then
  begin
    GetNextToken;
    if Execute = esExecute then
    begin
      ParseBlock(ElseExecState);
      if ElseExecState = esBreak then
        Execute := ElseExecState;
    end
    else
      ParseBlock(gNoExecute);
  end;
  MatchString('ENDIF');
end;

procedure TBacon.DoWhile(var Execute : TExecutionState);
var
  SavedContext: TBContext;
begin
  SavedContext := GetCurrContext;
  GetNextToken;
  if Execute = esExecute then
  begin
    while BoolExpression(Execute) > 0 do
    begin
      ParseBlock(gExecute);
      SetCurrContext(SavedContext);
      GetNextToken;
    end;
    { Si mangia il blocco per andare avanti }
    ParseBlock(gNoExecute);
  end
  else
  { Se Execute=False legge il blocco una volta sola }
  begin
    { Valuta l'espressione solo per consumarla }
    BoolExpression(Execute);
    ParseBlock(gNoExecute);
  end;
  MatchString('ENDWHILE');
end;

procedure TBacon.Error(const Msg : string);
begin
  raise Exception.Create('Errore: '+Msg);
end;

function TBacon.EvalTestCondition: Boolean;
var
  TestCondition: TTestCondition;
begin
  Result := False;
  if FOutput='' then
    raise Exception.Create('No test condition');
  TestCondition := TTestCondition.Create(FOutput, FSymbolTable);
  TestCondition.First;
  while not TestCondition.Eof do
  begin
    Result := TestCondition.Eval;
    if not Result then
      exit;
    TestCondition.Next;
  end;
  FreeAndNil(TestCondition);
end;

function TBacon.Evaluator(var Execute : TExecutionState): Variant;
var
  Temp: string;
  TempSymbol: TBSymbol;
begin
  Temp := GetCurrValue;
  TempSymbol := FSymbolTable.GetSymbol(Temp);
  if TempSymbol <> nil then
  begin
    case TempSymbol.BCategory of
    scVar:
      Result := TempSymbol.Value;
    scFunc:
      Result := RunFunc(Execute, Temp);
    end;
  end
  else
    Result := Temp;
end;

function TBacon.Expression(var Execute : TExecutionState): Variant;
var
  TmpValue: Variant;
  Temp: string;
  CurrLValue: TBSymbol;
begin
  (*if IsAddOp(GetCurrLook) then
    TmpValue := varEmpty
  else *)
  Result := Term(Execute);
  CurrLValue := GetCurrLValue;
  while IsAddop(GetCurrLook) do
  begin
    if GetCurrLook='+' then
    begin
      MatchChar('+');
      Result := CurrLValue.BType.Add(Result, Term(Execute));
    end
    else
      if GetCurrLook='-' then
      begin
        MatchChar('-');
        Result := CurrLValue.BType.Subtract(Result,Term(Execute));
      end;
  end;
end;

function TBacon.Factor(var Execute : TExecutionState): Variant;
begin
  if IsCurrValueFunction(GetCurrValue) then
    Result := Evaluator(Execute)
  else
    if GetCurrLook = '(' then
    begin
      MatchChar('(');
    //  Result := BoolExpression(Execute);
      Result := Expression(Execute);
      MatchChar(')');
    end
    else
      Result := Evaluator(Execute);
end;

procedure TBacon.GetChar;
begin
  SetEof;
  if FCurrContext.FPosition > FBufferLen then
    FCurrContext.FLook := #0
  else
  begin
    FCurrContext.FLook := FBuffer[GetCurrPointer];
    if GetCurrLook = CR then
      IncLineNumber;
    IncPointer;
  end;
end;

function TBacon.GetCurrContext: TBContext;
begin
  Result := FCurrContext;
end;

function TBacon.GetCurrLine: string;
var
  TmpLine: string;
  Cursor: Integer;
begin
  if GetCurrPointer > FBufferLen then
  begin
    Result := '';
  end
  else
  begin
    Cursor := GetCurrPointer;
    TmpLine := '';
    while (FBuffer[Cursor] <> CR) and (Cursor <= FBufferLen) do
    begin
      TmpLine := TmpLine + FBuffer[Cursor];
      inc(Cursor);
    end;
    Result := TmpLine;
  end;
end;

function TBacon.GetCurrLook: Char;
begin
  Result := FCurrContext.FLook;
end;

function TBacon.GetCurrLValue: TBSymbol;
begin
  Result := TBSymbol(FCurrContext.FLValue);
end;

function TBacon.GetCurrPointer: Integer;
begin
  Result := FCurrContext.FPosition;
end;

function TBacon.GetCurrStatement: TStatementType;
begin
  Result := FCurrContext.FStatementType;
end;

function TBacon.GetCurrToken: TTokenType;
begin
  Result := FCurrContext.FTokenType;
end;

function TBacon.GetCurrValue: string;
begin
  Result := FCurrContext.FValue;
end;

procedure TBacon.GetIdentifier;
begin
  SetCurrToken(ttIdentifier);
  SkipWhite;
  if not IsAlpha(GetCurrLook) then Abort('Name');
  SetCurrValue('');
  repeat
    SetCurrValue(GetCurrValue + UpCase(GetCurrLook));
    GetChar;
  until not IsAlNum(GetCurrLook);
end;

procedure TBacon.GetNextToken;
begin
  SkipWhite;
  if GetCurrLook = cQuoteChar then
    GetStringConstant
  else
    if (GetCurrLook='(') or (GetCurrLook=')') then
    else
    if IsAlpha(GetCurrLook) then
    begin
      GetIdentifier;
      IdentifierToTokenType;
    end
    else
      // Se vede segno meno o se e' un numero
      if (GetCurrLook=cMinus) or IsDigit(GetCurrLook) then
        GetNumber
      else
        if IsSpecial(GetCurrLook) then
        begin
          SetCurrValue(GetCurrLook);
          GetChar;
        end;
  SkipWhite;
end;

procedure TBacon.GetNumber;
var
  SawDecimalSeparator: Boolean;
begin
  SetCurrToken(ttNumber);
  SawDecimalSeparator := False;
  if (GetCurrLook <> cMinus) and not IsDigit(GetCurrLook) then Abort('Numeric');
  // TODO: Segnalare errore se si trova un carattere non valido
  SetCurrValue('');
  repeat
    SetCurrValue(GetCurrValue + GetCurrLook);
    GetChar;
    { Include la , (solo la prima) nel numero }
    if not SawDecimalSeparator then
      if GetCurrLook=cDecimalSeparator then
      begin
        SetCurrValue(GetCurrValue + GetCurrLook);
        GetChar;
        SawDecimalSeparator := True;
      end;
  until not IsDigit(GetCurrLook);
  { Sostituisce il cDecimalSeparator con il DecimalSeparator "vero" }
  if SawDecimalSeparator then
    SetCurrValue(xProcs.strReplace(GetCurrValue, cDecimalSeparator, DecimalSeparator));
end;

procedure TBacon.GetStatement;
begin
  GetNextToken;
  if IsAssignment then
  begin
    SetCurrStatement(stAssignment);
  //  FLValue := GetCurrValue;
    GetChar; // Consuma '='
  end
  else
    IdentifierToTokenType;
end;

procedure TBacon.GetStringConstant;
begin
  SetCurrToken(ttStringConstant);
  SkipWhite;
  SetCurrValue('');
  //MatchChar(cQuoteChar);
  GetChar; // Consuma ' iniziale
  if GetCurrLook <> cQuoteChar then
  repeat
    SetCurrValue(GetCurrValue + GetCurrLook);
    GetChar;
  until GetCurrLook = cQuoteChar;
  GetChar; // Consuma l'ultimo '
end;

function TBacon.GetValue(const VarName : string): Variant;
var
  TempSymbol: TBSymbol;
begin
  Result := Unassigned;
  TempSymbol := FSymbolTable.GetSymbol(VarName);
  if TempSymbol <> nil then
    Result := TempSymbol.Value;
end;

procedure TBacon.IdentifierToTokenType;
var
  TempValue: string;
  TempSymbol: TBSymbol;
begin
  TempValue := GetCurrValue;
  TempSymbol := FSymbolTable.GetSymbol(TempValue);
  if TempSymbol <> nil then
    case TempSymbol.BCategory of
      scVar:
        if GetCurrLook = '.' then
          SetCurrStatement(stFuncCall);
    end
  else
    if TempValue = 'END' then
    begin
      if GetCurrLook = '.' then
      begin
        SetCurrStatement(stEndProgram);
        SetCurrToken(ttEndProgram);
      end
      else
      begin
        SetCurrStatement(stEnd);
        SetCurrToken(ttEnd);
      end
    end
    else
      if TempValue = 'IF' then
        SetCurrStatement(stIf)
      else
        if TempValue = 'WHILE' then
          SetCurrStatement(stWhile)
        else
          if TempValue = 'EXIT' then
            SetCurrStatement(stExit)
          else
            if TempValue = 'BEGIN' then
              SetCurrToken(ttBegin)
            else
              if TempValue = 'ELSE' then
              begin
                SetCurrToken(ttElse);
                SetCurrStatement(stEnd);
              end
              else
                if (TempValue = 'ENDIF') or
                   (TempValue = 'ENDWHILE') then
                begin
                  SetCurrToken(ttEnd);
                  SetCurrStatement(stEnd);
                end;
end;

procedure TBacon.IncLineNumber;
begin
  with FCurrContext do
    FLineNum := FLineNum + 1;
end;

procedure TBacon.IncPointer;
begin
  with FCurrContext do
    FPosition := FPosition + 1;
end;

procedure TBacon.Init;
begin
  FParsed := False;
  if Assigned(FStdOut) then
    FStdOut.Clear;
  FEof := False;
  FBuffer := FCode.Text;
  FBufferLen := Length(FBuffer);
  FSymbolTable.Clear;
  ClearCurrContext;
  GetChar; // First character to initialize the system
  GetNextToken;
  FContextTable.Clear;
end;

function TBacon.IsAssignment: Boolean;
begin
  Result := GetCurrLook = '=';//Pos('=', GetCurrLine) > 0;
end;

function TBacon.IsCurrValueFunction(const Name : string): Boolean;
var
  Temp: TBSymbol;
begin
  Result := False;
  Temp := FSymbolTable.GetSymbol(Name);
  if Assigned(Temp) then
    Result := Temp.BCategory = scFunc;
end;

function TBacon.IsFuncCall: Boolean;
begin
  Result := GetCurrLook = '.';
end;

function TBacon.IsFuncDecl: Boolean;
begin
  Result := Pos(')', GetCurrLine) > 0;
end;

procedure TBacon.LoadProgramFile(const FileName : string);
begin
  FCode.LoadFromFile(FileName);
  FParsed := False;
  Init;
  ParseHeader;
end;

function TBacon.LookNextChar: Char;
begin
  Result := FBuffer[GetCurrPointer];
end;

function TBacon.LookNextToken: string;
var
  OldContext: TBContext;
begin
  OldContext := GetCurrContext;
  GetNextToken;
  Result := GetCurrValue;
  SetCurrContext(OldContext);
end;

procedure TBacon.MatchChar(const ExpectedChar : char);
begin
  if GetCurrLook <> ExpectedChar then
    Abort('Mi aspettavo: '+ExpectedChar);
  GetChar;
  GetNextToken;
end;

procedure TBacon.MatchString(const ExpectedString : string);
begin
  if GetCurrValue <> ExpectedString then
    Abort('Mi aspettavo: '+ExpectedString);
  GetNextToken;
end;

function TBacon.NotFactor(var Execute : TExecutionState): Variant;
begin
  if GetCurrValue='NOT' then
  begin
    MatchString('NOT');
    Result := Relation(Execute);
  end
  else
    Result := Relation(Execute);
end;

procedure TBacon.ParseBlock(var Execute : TExecutionState);
begin
  while not FEof and (not (GetCurrToken in [ttEnd, ttElse, ttEndProgram])) do
  begin
    GetStatement;
    case GetCurrStatement of
     stIf:
       DoIf(Execute);
     stWhile:
       DoWhile(Execute);
     stAssignment:
       DoAssignment(Execute);
     stFuncCall:
       DoFuncCall(Execute);
     stExit:
       begin
         MatchString('EXIT');
         if Execute = esExecute then
           Execute := esBreak;
       end;
     stEnd,stEndProgram:
         break;
     stNone:
       Abort('Undefined statement');
    end;
  //    Semi;     Scan;
  end;
end;

procedure TBacon.ParseHeader;
begin
  MatchString('PROGRAM');
  FTitle := GetCurrValue;
  GetNextToken; // consuma il nome del programma
  if GetCurrValue='COMMENT' then
  begin
    FComment := SkipLine;
    GetNextToken;
  end;
  if GetCurrValue='OUTPUT' then
  begin
    FOutput := SkipLine;
    GetNextToken;
  end;
end;

procedure TBacon.ParseProgram;
begin
  while GetCurrToken <> ttEndProgram do
    if IsFuncDecl then
      ReadFunc(gNoExecute, scGlobal)
    else
      ReadVar(scGlobal);
end;

procedure TBacon.PopContext;
begin
end;

procedure TBacon.PushContext;
begin
end;

procedure TBacon.ReadFormalParams(var Execute : TExecutionState; const CreateParams :     
    boolean; FuncSymbol : TBSymbol; const FuncName : string);
begin
  // TODO: Segnalare errore se numero di parametri non uguale alla definizione
  MatchChar('(');
  if GetCurrLook <> ')' then
  begin
    if CreateParams then
      CreateParam(FuncSymbol, FuncName)
    else
      while GetCurrLook <> ')' do
      begin
        if GetCurrLook=',' then GetChar;
        GetNextToken;
      end;
  
    while GetCurrLook=',' do
    begin
      MatchChar(',');
  //    MatchString(',');
      if CreateParams then
        CreateParam(FuncSymbol, FuncName)
      else
        while GetCurrLook <> ')' do
          GetNextToken;
    end;
  end;
  MatchChar(')');
end;

procedure TBacon.ReadFunc(var Execute : TExecutionState; Scope : TSymbolScope);
var
  TempFuncType: string;
  FuncType: TBBaseType;
  FuncName: string;
  FuncSymbol: TBSymbol;
  Bookmark: Integer;
begin
  FuncType := nil;
  FuncSymbol := nil;
  TempFuncType := GetCurrValue;
  GetNextToken;
  FuncName := GetCurrValue;
  { Inserisce la funzione solo se NON gia' inserita }
  if FSymbolTable.GetSymbol(FuncName) = nil then
  begin
    FuncType := StrToBType(TempFuncType);
    if FuncType = nil then Abort('Invalid type name');
    FuncSymbol := FSymbolTable.AddFunction(FuncName, FuncType, GetCurrContext, scGlobal);
  end;
  ReadFormalParams(Execute, True, FuncSymbol, FuncName);
  while GetCurrValue <> 'BEGIN' do
    ReadVar(scLocal);
  MatchString('BEGIN');
  (* TODO
  if IsFuncDecl then
    ReadFunc(Execute, scLocal)
  else
    ReadVar(scLocal);
  *)
  Bookmark := FSymbolTable.GetBookmark;
  // Aggiunge Result per non dare "undefined" nel parsing
  FSymbolTable.AddVar('RESULT', FuncType, GetCurrContext, scLocal);
  FSymbolTable.AddParams(FuncSymbol.Params, GetCurrContext, scLocal);
  ParseBlock(gNoExecute);
  // Elimina Result
  FSymbolTable.ClearFromBookmark(Bookmark);
  MatchString('END');
end;

procedure TBacon.ReadVar(Scope : TSymbolScope);
var
  VarType: TBBaseType;
  VarName: string;
  sVarType: string;
  Symbol: TBSymbol;
begin
  //VarType := StrToBType(GetCurrValue);
  sVarType := GetCurrValue;
  //if VarType = nil then Abort('Invalid type name');
  GetNextToken;
  VarName := GetCurrValue;
  Symbol := FSymbolTable.GetSymbol(VarName);
  if Symbol=nil then
  begin
    VarType := StrToBType(sVarType);
    if VarType = nil then Abort('Invalid type name');
    FSymbolTable.AddVar(VarName, VarType, GetCurrContext, Scope);
  end
  else
  begin
    VarType := Symbol.BType;
    if VarType = nil then
    begin
      VarType := StrToBType(sVarType);
      if VarType = nil then Abort('Invalid type name');
    end;
  end;
  GetNextToken;
end;

procedure TBacon.RegisterType(aNewTypeRef : TBTypeRef);
var
  NewTypeInstance: TBBaseType;
begin
  if FRegisteredClassTypes.IndexOf(aNewTypeRef) < 0 then
  begin
    FRegisteredClassTypes.Add(aNewTypeRef);
  //  aNewTypeRef.RegisterFunctions(Self);
  end;
end;

function TBacon.Relation(var Execute : TExecutionState): Variant;
var
  Temp: string;
  
  function Less(const Left : variant; const OrEqual : boolean): Boolean;
  begin
    MatchChar('<');
    if OrEqual then
    begin
      MatchChar('=');
      Result := Left <= Expression(Execute)
    end
    else
      Result := Left < Expression(Execute);
  end;
  
  function Equals(const Left : variant): Boolean;
  begin
    MatchChar('=');
    Result := Left = Expression(Execute);
  end;
  
  function Greater(const Left : variant; const OrEqual : boolean): Boolean;
  begin
    MatchChar('>');
    if OrEqual then
    begin
      MatchChar('=');
      Result := Left >= Expression(Execute)
    end
    else
      Result := Left > Expression(Execute);
  end;
  
  function NotEquals(const Left : variant): Boolean;
  begin
    MatchChar('<');
    Result := Expression(Execute) <> Left;
  end;
  
begin
  Result := Expression(Execute);
  GetNextToken;
  if IsRelOp(GetCurrLook) then
  begin
    Temp := GetCurrLook;
    if Temp = '=' then
    begin
      if Equals(Result) then
        Result := 1
      else
        Result := 0;
    end
    else
      if Temp = '<' then
      begin
        if GetCurrLook='>' then
          if NotEquals(Result) then Result := 1 else Result := 0
        else
          if Less(Result, LookNextChar='=')  then Result := 1 else Result := 0;
      end
      else
      begin
        if Temp = '>' then
          if Greater(Result, LookNextChar='=')  then Result := 1 else Result := 0;
      end
  end;
end;

procedure TBacon.Run;
begin
  if not FParsed then
  begin
    Init;
    ParseHeader;
    ParseProgram;
    FParsed := True;
  end;
  RunFunc(gExecute, 'MAIN');
end;

function TBacon.RunFunc(var Execute : TExecutionState; const FunctionName : string): 
    Variant;
var
  Bookmark: Integer;
  FuncSymbol: TBSymbol;
  OldSymbolTable, NewSymbolTable: TBSymbolTable;
  I: Integer;
  Param: TBSymbol;
  SavedExecutionState: TExecutionState;
begin
  Result := 0.0;
  Bookmark := 0;
  OldSymbolTable := nil;
  GetNextToken;
  if Execute = esExecute then
  begin
    Bookmark := FSymbolTable.GetBookmark;
    FuncSymbol := FSymbolTable.GetSymbol(FunctionName);
    // Main non ha parametri (per ora....)
    if FunctionName <> 'MAIN' then
      if not BindParams(Execute, FuncSymbol, FunctionName) then
        exit;
  
    OldSymbolTable := FSymbolTable;
    FSymbolTable.CopyTo(NewSymbolTable);
    FSymbolTable := NewSymbolTable;
  
    for i := FuncSymbol.Params.First to
             FuncSymbol.Params.Position do
    begin
      Param := FuncSymbol.Params[i];
      if Assigned(Param) then
        if FSymbolTable.AddVar(Param.BName, Param.BType, GetCurrContext, scLocal) = nil then
          Abort('Fallita AddSymbol');
    end;
    PushContext;
    // Result non si deve propagare ai livelli sottostanti
    FSymbolTable.AddVar('RESULT', FuncSymbol.BType, GetCurrContext, scLocal);
    SetCurrContext(FuncSymbol.BContext);
    GetNextToken;
  end;
  ReadFormalParams(Execute, False, nil, FunctionName);  // "Consuma" i parametri
  if Execute = esExecute then
  begin
    while GetCurrToken <> ttBegin do
      if IsFuncDecl then
        ReadFunc(gNoExecute, scLocal)
      else
        ReadVar(scLocal);
    MatchString('BEGIN');
  (*
    // Consuma le var locali
    if GetCurrValue{GetCurrToken} = 'v' then
      TopDecls(scLocal)
    else
      MatchString('BEGIN');
  *)
    SavedExecutionState := Execute;
    ParseBlock(gExecute);
    { Ripristina lo stato precedente se "exit" }
    if Execute = esBreak then
      Execute := SavedExecutionState;
  //    MatchString('END');
    Result := FSymbolTable.GetSymbol('RESULT').Value;
    PopContext;
    FSymbolTable.ClearFromBookmark(Bookmark);
    FSymbolTable := OldSymbolTable;
    NewSymbolTable.Free;
    GetNextToken;
  end;
end;

procedure TBacon.SetCode(Code : TStrings);
begin
  FCode.Assign(Code);
  FParsed := False;
end;

procedure TBacon.SetCurrContext(NewContext : TBContext);
begin
  with FCurrContext do
  begin
    FPosition   := NewContext.FPosition;
    FTokenType  := NewContext.FTokenType;
    FLook       := NewContext.FLook;
    FValue      := NewContext.FValue;
    FLineNum    := NewContext.FLineNum;
  end;
end;

procedure TBacon.SetCurrLValue(const LValue : TBSymbol);
begin
  FCurrContext.FLValue := LValue;
end;

procedure TBacon.SetCurrStatement(NewStatementType : TStatementType);
begin
  FCurrContext.FStatementType := NewStatementType;
end;

procedure TBacon.SetCurrToken(NewToken: TTokenType);
begin
  FCurrContext.FTokenType := NewToken;
end;

procedure TBacon.SetCurrValue(const NewValue : string);
begin
  FCurrContext.FValue := NewValue;
end;

procedure TBacon.SetEof;
begin
  FEof := FCurrContext.FPosition > FBufferLen;
end;

function TBacon.SkipLine: string;
begin
  Result := '';
  while FCurrContext.FLook <> CR do
  begin
    Result := Result + FCurrContext.FLook;
    GetChar;
  end;
end;

procedure TBacon.SkipWhite;
begin
  while IsWhite(FCurrContext.FLook) or (FCurrContext.FLook = ';') do
  begin
    // Clear curr statement type after a semicolon
    if FCurrContext.FLook = ';' then
      SetCurrStatement(stNone);
    if FCurrContext.FLook = cStartComment then
      SkipLine
    else
      GetChar;
  end;
end;

function TBacon.StrToBType(const sType : string): TBBaseType;
var
  I: Integer;
  Instance: TBBaseType;
begin
  Result := nil;
  for i := 0 to FRegisteredClassTypes.Count - 1 do
    if UpperCase(TBTypeRef(FRegisteredClassTypes[i]).GetName) = sType then
    begin
      Instance := TBBaseType(FRegisteredClassTypes[i].NewInstance);
      try
        Instance.Create;
      except
        raise;
      end;
      Result := Instance;
      exit;
    end;
end;

function TBacon.Term(var Execute : TExecutionState): Variant;
var
  Value: Variant;
  Temp: string;
begin
  Result := Factor(Execute);
  while IsMulOp(GetCurrLook) do
  begin
    if GetCurrLook = '*' then
    begin
      MatchChar('*');
      Result := Result * Factor(Execute);
    end
    else
      if GetCurrLook = '/' then
      begin
        MatchChar('/');
        Result := Result / Factor(Execute);
      end;
  end;
  //Result := Value;
end;

{
************************************* TTestCondition *************************************
}
constructor TTestCondition.Create(const TestCondition : string; const SymbolTable : 
    TBSymbolTable);
begin
  FTestCondition := TestCondition;
  FEof := FTestCondition <> '';
  FSymbolTable := SymbolTable;
end;

function TTestCondition.Eval: Boolean;
var
  Temp: string;
  VarName: string;
  ExpectedValue: Double;
  TempSymbol: TBSymbol;
  CurrValue: Double;
  ValueName: string;
begin
  Temp := FCurrCondition;
  VarName := strToken(Temp,':');
  ValueName := Trim(Copy(Temp, 1, Length(Temp)));
  TempSymbol := FSymbolTable.GetSymbol(ValueName);
  if TempSymbol = nil then
    ExpectedValue := Str2Double(ValueName)
  else
    ExpectedValue := TempSymbol.Value;
  TempSymbol := FSymbolTable.GetSymbol(VarName);
  if TempSymbol = nil then
    raise Exception.Create('Undefined symbol '+VarName);
  // Forza conversione a double
  CurrValue := TempSymbol.Value;
  Result := CurrValue = ExpectedValue;
end;

procedure TTestCondition.First;
begin
  // Ripristina la stringa originale
  FWorkString := FTestCondition;
  Next;
end;

procedure TTestCondition.Next;
begin
  // La prossima condizione viene rimossa da FWorkString e salvata in FCurrCondition
  FCurrCondition := xProcs.strToken(FWorkString, ';');
  FEof := FCurrCondition = '';
end;

function TTestCondition.Str2Double(const sDouble : string): Double;
var
  Temp: string;
begin
  Temp := sDouble;
  if Pos(cDecimalSeparator, sDouble) > 0 then
    Temp := xProcs.strReplace(Temp, cDecimalSeparator, DecimalSeparator);
  Result := StrToFloat(Temp);
end;


initialization
end.
