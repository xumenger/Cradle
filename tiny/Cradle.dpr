program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;

const
  TAB = ^I;
  CR = ^M;
  LF = ^J;

var
  Look: Char;
  LCount: Integer;
  ST: array['A'..'Z'] of Char;

{-----------------------------------------------------------------}

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

{ Get an Identifier }
function GetName: Char;
begin
  if not IsAlpha(Look) then Expected('Name');
  GetName := UpCase(Look);
  GetChar;
end;

{ Get a Number }
function GetNum: Integer;
var
  Val: Integer;
begin
  Val := 0;
  if not IsDigit(Look) then Expected('Integer');
  while IsDigit(Look) do begin
    Val := 10 * Val + Ord(Look) - Ord('0');
    GetChar();
  end;
  GetNum := Val;
end;

{ Match a Specific Input Character }
procedure Match(x: Char);
begin
  if Look <> x then Expected('''' + x + '''');
  GetChar();
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

{ Look for Symbol in Table }
function InTable(n: Char): Boolean;
begin
  InTable := ST[n] <> ' ';
end;

procedure Undefined(n: Char);
begin
  Abort('Duplicate Identifier ' + n);
end;

{-----------------------------------------------------------------}
{ you can retarget the compiler to a new CPU simply by rewriting
  the following 'code generator' procedures }

{ Clear the Primary Register }
procedure Clear;
begin
  EmitLn('CLR D0');
end;

{ Negate the Primary Register }
procedure Negate;
begin
  EmitLn('NEG D0');
end;

{ Load a Constant Value to Primary Register }
procedure LoadConst(n: Integer);
begin
  Emit('MOVE #');
  Writeln(n, ',D0');
end;

{ Load a Variable to Primary Register }
procedure LoadVar(Name: Char);
begin
  if not InTable(Name) then Undefined(Name);
  EmitLn('MOVE ' + Name + '(PC),D0');
end;

{ Push Primary onto Stack }
procedure Push;
begin
  EmitLn('MOVE D0,-(SP)');
end;

{ Add Top of Stack to Primary }
procedure PopAdd;
begin
  EmitLn('ADD (SP)+,D0');
end;

{ Subtract Primary from Top Stack }
procedure PopSub;
begin
  EmitLn('SUB (SP)+,D0');
  EmitLn('NEG D0');
end;

{ Muliply Top of Stack by Primary }
procedure PopMul;
begin
  EmitLn('MULS (SP)+,D0');
end;

{ Divide Top of Stack by Primary }
procedure PopDiv;
begin
  EmitLn('MOVE (SP)+,D7');
  EmitLn('EXT.L D7');
  EmitLn('DIVS D0,D7');
  EmitLn('MOVE D7,D0');
end;

{ Store Primary to Variable }
procedure Store(Name: Char);
begin
  if not InTable(Name) then Undefined(Name);
  EmitLn('LEA ' + Name + '(PC),A0');
  EmitLn('MOVE D0,(A0)');
end;

{-----------------------------------------------------------------}

{ Write the Prolog }
procedure Prolog;
begin
  PostLabel('MAIN');
end;

{ Write the Epilog }
procedure Epilog;
begin
  EmitLn('DC WARMST');
  EmitLn('END MAIN');
end;

{ Write Header Info }
procedure Header;
begin
  Writeln('WARMST', TAB, 'EQU $A01E');
end;

{ Allocate Storage for a Variable }
procedure Alloc(N: Char);
begin
  if InTable(N) then Undefined(N);
  ST[N] := 'v';
  Write(N, ':', TAB, 'DC ');
  if Look = '=' then begin
    Match('=');
    if Look = '-' then begin
      Write(Look);
      Match('-');
    end;
    Writeln(GetNum());
  end
  else
    WriteLn('0');
end;

{ Process a Data Declaration }
procedure Decl;
begin
  Match('v');
  Alloc(GetName());
  while Look = ',' do begin
    GetChar();
    Alloc(GetName());
  end;
end;

{ Parse and Translate Global Declarations }
procedure TopDecls;
begin
  while Look <> 'b' do begin
    case Look of
      'v': Decl();
    else Abort('Unrecognize Keyword ''' + Look + '''');
    end;
  end;
end;

{ Parse and Translate an Assignmnt Statement }
procedure Assignment;
begin
  GetChar();
end;

{ Parse and Translate a Block of Statement }
procedure Block;
begin
  while Look <> 'e' do
    Assignment();
end;

{ Parse and Translate a Main Program }
procedure Main;
begin
  Match('b');
  Prolog();
  Block();
  Match('e');
  Epilog();
end;

{-----------------------------------------------------------------}

{ Parse and Translate a Program }
procedure Prog;
begin
  Match('p');
  Header();
  TopDecls();
  Main();
  Match('.');
end;

{ Initialize }
procedure Init;
var
  i: Char;
begin
  LCount := 0;
  for i := 'A' to 'Z' do
    ST[i] := ' ';
  GetChar();
end;

{-----------------------------------------------------------------}

{ Main Program }
begin
  Init();
  Prog();
  if Look <> CR then Abort('Unexpected data after ''.''')
end.

