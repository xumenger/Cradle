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
function GetNum: Char;
begin
  if not IsDigit(Look) then Expected('Integer');
  GetNum := Look;
  GetChar;
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


{-----------------------------------------------------------------}

{ Parse and Translate a Program }
procedure Header; forward;
procedure TopDecls; forward;
procedure Main; forward;
procedure Prolog; forward;
procedure Epilog; forward;

procedure Prog;
begin
  Match('p');
  Header();
  TopDecls();
  Main();
  Match('.');
end;

{ Write Header Info }
procedure Header;
begin
  Writeln('WARMST', TAB, 'EQU $A01E');
end;

{ Allocate Storage for a Variable }
procedure Alloc(N: Char);
begin
  Writeln(N, ':', TAB, 'DC 0');
end;

{ Process a Data Declaration }
procedure Decl;
begin
  Match('v');
  Alloc(GetName());
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

{ Parse and Translate a Main Program }
procedure Main;
begin
  Match('b');
  Prolog();
  Match('e');
  Epilog();
end;

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

{ Initialize }
procedure Init;
begin
  LCount := 0;
  GetChar();
end;

{-----------------------------------------------------------------}

{ Main Program }
begin
  Init();
  Prog();
  if Look <> CR then Abort('Unexpected data after ''.''')
end.
