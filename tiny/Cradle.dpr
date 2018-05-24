program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;

const
  TAB = ^I;
  
{ Parse and Translate a Program }
procedure Header; forward;
procedure Main; forward;
procedure Prolog; forward;
procedure Epilog; forward;

procedure Prog;
begin
  Match('p');
  Header();
  Main();
  Match('.');
end;

{ Write Header Info }
procedure Header;
begin
  Writeln('WARMST', TAB, 'EQU $A01E');
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

{ Main Program }
begin
  Init();
  Prog();
  if Look <> CR then Abort('Unexpected data after ''.''')
end.
