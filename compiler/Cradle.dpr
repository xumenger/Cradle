program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;
  
{----------------------Declaration----------------------------}

{ Const Declarations }
const
  TAB = ^I;
  CR = ^M;
  LF = ^J;

{ Type Declarations }
type
  Symbol = string[8];
  SymTab = array[1..1000] of Symbol;
  TabPtr = ^SymTab;

{ Variable Declarations }
var
  Look: Char;            { Lookahead Character }
  LCount: Integer;       { Label Counter }

{--------------------------------------------------------------}
{ Read New Character from Input Stream }
procedure GetChar;
begin
  Read(Look);
end;

{ Report an Error }
procedure Error(s: string);
begin
  Writeln;
  Writeln(^G, 'Error: ', s, '.');
end;

{ Report Error and Halt }
procedure Abort(s: string);
begin
  Error(s);
  Halt;
end;

{ Report What Was Expected }
procedure Expected(s: string);
begin
  Abort(s + ' Expected');
end;

{ Recognize an Alpha Character }
function IsAlpha(c: Char): Boolean;
begin
  IsAlpha := UpCase(c) in ['A'..'Z'];
end;

{ Recognize a Decimal Digit }
function IsDigit(c: Char): Boolean;
begin
  IsDigit := c in ['0'..'9'];
end;

{ Recognize an AlphaNumeric Character }
function IsAlNum(c: Char): Boolean;
begin
  IsAlNum := IsAlpha(c) or IsDigit(c);
end;

{ Recognize an Addop }
function IsAddop(c: Char): Boolean;
begin
  IsAddop := c in ['+', '-'];
end;

{ Recognize a Mulop }
function IsMulop(c: Char): Boolean;
begin
  IsMulop := c in ['*', '/'];
end;

{ Recognize White Space }
function IsWhite(c: Char): Boolean;
begin
  IsWhite := c in [' ', TAB];
end;

{ Skip Over Leading White Space }
procedure SkipWhite;
begin
  while IsWhite(Look) do
    GetChar();
end;

{ Match a Specific Input Character }
procedure Match(x: Char);
begin
  if Look <> x then Expected('''' + x + '''');
  GetChar();
  SkipWhite();
end;

{ Skip a CRLF }
procedure Fin;
begin
  if Look = CR then GetChar();
  if Look = LF then GetChar();
  SkipWhite();
end;

{ Get an Identifier }
function GetName: Char;
begin
  while Look = CR do
    Fin();
  if not IsAlpha(Look) then Expected('Name');
  GetName := UpCase(Look);
  GetChar();
  SkipWhite();
end;

{ Get a Number }
function GetNum: Char;
begin
  if not IsDigit(Look) then Expected('Integer');
  GetNum := Look;
  GetChar();
  SkipWhite();
end;

{ Generate a Unique Label }
function NewLabel: string;
var
  S: string;
begin
  Str(LCount, S);
  NewLabel := 'L' + S;
  Inc(LCount);
end;

{ Post a Label To Output }
procedure PostLabel(L: string);
begin
  Writeln(L, ':');
end;

{ Output a String with Tab }
procedure Emit(s: string);
begin
  Write(Tab, s);
end;

{ Output a String with Tab and CRLF }
procedure EmitLn(s: string);
begin
  Emit(s);
  Writeln;
end;

{ Parse and Translate an Identifier }
procedure Ident;
var
  Name: Char;
begin
  Name := GetName();
  if Look = '(' then begin
    Match('(');
    Match(')');
    EmitLn('BSR ' + Name);
  end
  else
    EmitLn('MOVE ' + Name + '(PC),D0');
end;

{ Parse and Translate a Math Factor }
procedure Expression; forward;

procedure Factor;
begin
  if Look = '(' then begin
    Match('(');
    Expression();
    Match(')');
  end
  else if IsAlpha(Look) then
    Ident()
  else
    EmitLn('MOVE #' + GetNum() + ',D0');
end;

{ Parse and Translate the First Math Factor }
procedure SignedFactor;
var
  s: Boolean;
begin
  s := Look = '-';
  if IsAddop(Look) then begin
    GetChar();
    SkipWhite();
  end;
  Factor();
  if s then
    EmitLn('NEG D0');
end;

{ Recognize and Translate a Multiply }
procedure Multiply;
begin
  Match('*');
  Factor();
  EmitLn('MULS (SP)+,D0');
end;

{ Recognize and Translate a Divide }
procedure Divide;
begin
  Match('/');
  Factor();
  EmitLn('MOVE (SP)+,D1');
  EmitLn('EXS.L D0');
  EmitLn('DIVS D1,D0');
end;

{ Completion of Term Processing (called by Term and FirstTerm) }
procedure Term1;
begin
  while IsMulop(Look) do begin
    EmitLn('MOVE D0,-(SP)');
    case Look of
      '*': Multiply();
      '/': Divide();
    end;
  end;
end;

{ Parse and Translate a Math Term }
procedure Term;
begin
  Factor();
  Term1();
end;

{ Parse and Translate a Math Term with Possible Leading Sign }
procedure FirstTerm;
begin
  SignedFactor();
  Term1();
end;

{ Recognize and Translate an Add }
procedure Add;
begin
  Match('+');
  Term();
  EmitLn('ADD (SP)+,D0');
end;

{ Recognize and Translate a Subtract }
procedure Subtract;
begin
  Match('-');
  Term();
  EmitLn('SUB (SP)+,D0');
  EmitLn('NEG D0');
end;

{ Parse and Translate an Expression }
procedure Expression;
begin
  FirstTerm();
  while IsAddop(Look) do begin
    EmitLn('MOVE D0,-(SP)');
    case Look of
      '+': Add();
      '-': Subtract();
    end;
  end;
end;

{ Parse and Translate a Boolean Condition }
procedure Condition;
begin
  EmitLn('Condition');
end;

{ Recognize and Translate an IF Construct }
procedure Block; forward;

procedure DoIf;
var
  L1, L2: string;
begin
  Match('i');
  Condition();
  L1 := NewLabel();
  L2 := L1;
  EmitLn('BEQ ' + L1);
  Block();
  if Look = 'l' then begin
    Match('l');
    L2 := NewLabel();
    EmitLn('BRA ' + L2);
    PostLabel(L1);
    Block();
  end;
  PostLabel(L2);
  Match('e');
end;

{ Parse and Translate an Assignment Statement }
procedure Assignment;
var
  Name: Char;
begin
  Name := GetName();
  Match('=');
  Expression();
  EmitLn('LEA ' + Name + '(PC),A0');
  EmitLn('MOVE D0,(A0)');
end;

{ Recognize and Translate a Statement Block }
procedure Block;
begin
  while not (Look in ['e', 'l']) do begin
    case Look of
      'i': DoIf();
      CR: while Look = CR do Fin();
    else Assignment();
    end;
  end;
end;

{ Parse and Translate a Program }
procedure DoProgram;
begin
  Block();
  if Look <> 'e' then Expected('END');
  EmitLn('END');
end;

{ Initialize }
procedure Init;
begin
  LCount := 0;
  GetChar();
end;

{ Main Program }
begin
  Init();
  DoProgram();
end.
