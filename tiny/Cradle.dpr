program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;

const
  TAB = ^I;
  
{ Parse and Translate a Program }
{ <program> ::= PROGRAM <top-level decl> <main> '.' }
procedure Header; forward;
procedure Prolog; forward;
procedure Epilog; forward;

procedure Prog;
begin
  Match('p');
  Header();
  Prolog();
  Match('.');
  Epilog();
end;

{ Write Header Info }
procedure Header;
begin
  Writeln('WARMST', TAB, 'EQU $A01E');
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
