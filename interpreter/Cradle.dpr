program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;
  
{----------------------Declaration----------------------------}

{ Constant Declarations }
const
  TAB = ^I;
  CR = ^M;

{ Variable Declarations }
var
  Look: Char;          //Lookahead Character


{----------------------Function----------------------------}

{ Read New Character From Inpput Stream }
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

{ Recoginze an Alpha Character }
function IsAlpha(c: Char): Boolean;
begin
  IsAlpha := UpCase(c) in ['A'..'Z'];
end;

{ Recoginze a Decimal Digit }
function IsDigit(c: Char): Boolean;
begin
  IsDigit := c in ['0'..'9'];
end;

{ Recognize an Alphanumeric }
function IsAlNum(c: Char): Boolean;
begin
  IsAlNum := IsAlpha(c) or IsDigit(c);
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
  if Look <> x then Expected('''' + x + '''')
  else begin
    GetChar();
    SkipWhite();
  end;
end;

{ Get an Identifier }
function GetName: string;
var
  Token: string;
begin
  Token := '';
  if not IsAlpha(Look) then Expected('Name');
  while IsAlNum(Look) do begin
    Token := Token + UpCase(Look);
    GetChar();
  end;
  GetName := Token;
  SkipWhite();
end;

{ Get a Number }
function GetNum: Integer;
begin
  if not IsDigit(Look) then Expected('Integer');
  GetNum := Ord(Look) - Ord('0');
  GetChar();
end;

{ Output a String with Tab }
procedure Emit(s: string);
begin
  write(TAB, s);
end;

{ Output a String with Tab and CRLF }
procedure EmitLn(s: string);
begin
  Emit(s);
  Writeln;
end;

{-----------Parse and Translate a Math Expression-------------}

function Expression: Integer; forward;

function IsAddop(c: Char): Boolean;
begin
  IsAddop := c in ['+', '-'];
end;

{ BNF: <expression> ::= <term> [<addop> <term>]* }
function Expression: Integer;
begin
  Expression := GetNum();
end;

{----------------------Initialize--------------------}
procedure Init;
begin
  GetChar();
  SkipWhite();
end;

{-----------------------Run---------------------------}
{ Main Program }
begin
  Init();
  Writeln(Expression());
end.

