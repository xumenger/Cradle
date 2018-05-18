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

{-----------Parse and Translate a Math Expression-------------}

{ Get Term }
procedure Term;
begin
  EmitLn('MOVE #' + GetNum + ',D0');
end;

{ Recognize and Translate an Add }
procedure Add;
begin
  Match('+');
  Term;
  EmitLn('ADD (SP)+, D0');
end;

{ Recognize and Translate a Subtract }
procedure Subtract;
begin
  Match('-');
  Term;
  EmitLn('SUB (SP)+, D0');
  EmitLn('NEG D0');
end;

{ BNF: <term> [<addop> <term>]* }
procedure Expression;
begin
  Term;
  while Look in['+', '-'] do begin
    EmitLn('MOVE D0, -(SP)');
    case Look of
      '+': Add;
      '-': Subtract;
    else Expected('Addop');
    end;;
  end;
end;

{-----------------------Run---------------------------}

{ Main Program }
begin
  Init;
  Expression;
end.
