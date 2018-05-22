program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;
  
{----------------------Declaration----------------------------}

{ Constant Declarations }
const
  TAB = ^I;
  CR = #13;
  LF = #10;

{ Variable Declarations }
var
  Look: Char;                          //Lookahead Character
  Table: array['A'..'Z'] of Integer;


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
function GetName: Char;
begin
  if not IsAlpha(Look) then Expected('Name');
  GetName := UpCase(Look);
  GetChar();
end;

{ Get a Number }
function GetNum: Integer;
var
  Value: Integer;
begin
  Value := 0;
  if not IsDigit(Look) then Expected('Integer');
  while IsDigit(Look) do begin
    Value := 10 * Value + Ord(Look) - Ord('0');
    GetChar();
  end;
  GetNum := Value;
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

{ Recoginze and Skip Over a Newline }
procedure NewLine;
begin
  if Look = CR then begin
    GetChar();
    if Look = LF then
      GetChar();
  end;
end;

{ Input Routine }
procedure Input;
begin
  Match('?');
  Read(Table[GetName()]);
end;

{ Output Routine }
procedure Output;
begin
  Match('!');
  Writeln(Table[GetName()]);
end;

{-----------Parse and Translate a Math Expression-------------}

function Expression: Integer; forward;

function IsAddop(c: Char): Boolean;
begin
  IsAddop := c in ['+', '-'];
end;

function Factor: Integer;
begin
  if Look = '(' then begin
    Match('(');
    Factor := Expression();
    Match(')');
  end
  else if IsAlpha(Look) then
    Factor := Table[GetName()]
  else
    Factor := GetNum();
end;

function Term: Integer;
var
  Value: Integer;
begin
  Value := Factor();
  while Look in ['*', '/'] do begin
    case Look of
      '*': begin
        Match('*');
        Value := Value * Factor();
      end;
      '/': begin
        Match('/');
        Value := Value div Factor();
      end;
    end;
  end;
  Term := Value;
end;

{ BNF: <expression> ::= <term> [<addop> <term>]* }
function Expression: Integer;
var
  Value: Integer;
begin
  if IsAddop(Look) then
    Value := 0
  else
    Value := Term();
  while IsAddop(Look) do begin
    case Look of
      '+': begin
        Match('+');
        Value := Value + Term();
      end;
      '-': begin
        Match('-');
        Value := Value - Term();
      end;
    end;
  end;
  Expression := Value;
end;

{ Parse and Translate an Assignment Statement }
procedure Assignment;
var
  Name: Char;
begin
  Name := GetName();
  Match('=');
  Table[Name] := Expression();
end;

{----------------------Initialize--------------------}

{ Initialize the Variable Area
For the compiler, we had no problem in dealing with variable names ..
we just issued the names to the assembler and let the rest of the program
take care of allocating storage for them. Here, on the other hand, we need
to be able to fetch the values of the variables and return then as the return
values of Factor. We need a storage mechanism for these variables}
procedure InitTable;
var
  i: Char;
begin
  for i := 'A' to 'Z' do
    Table[i] := 0;
end;

procedure Init;
begin
  InitTable();
  GetChar();
  SkipWhite();
end;


{-----------------------Run---------------------------}
{ Main Program }
begin
  Init();
  repeat
    case Look of
      '?': Input();
      '!': Output();
    else Assignment;
    end;
    NewLine();
  until Look = '.';
end.

