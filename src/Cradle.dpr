program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;
  
{----------------------Declaration----------------------------}

{ Constant Declarations }
const
  TAB = ^I;

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
  Writeln(^G, 'Error: ', s, s, '.');
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

{ Match a Specific Input Character }
procedure Match(x: Char);
begin
  if Look = x then GetChar
  else Expected('''' + x + '''');
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

{ Get an Identifier }
function GetName: Char;
begin
  if not IsAlpha(Look) then Expected('Name');
  GetName := UpCase(Look);
  GetChar;
end;

{ Get a Number }
function GetNum: Char;
begin
  if not IsDigit(Look) then Expected('Integer');
  GetNum := Look;
  GetChar;
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

{ Initialize }
procedure Init;
begin
  GetChar;
end;

{-----------------------Run---------------------------}

{ Main Program }
begin
  Init;
end.