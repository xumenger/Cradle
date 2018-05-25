program Cradle;

{$APPTYPE CONSOLE}

uses
  SysUtils;

type
  Symbol = string[8];
  SymTab = array[1..1000] of Symbol;
  TabPtr = ^SymTab;

const
  TAB = ^I;
  CR = ^M;
  LF = ^J;
  NKW = 9;
  NKW1 = 10;
  KWlist: array[1..NKW] of Symbol =
          ('IF', 'ELSE', 'ENDIF', 'WHILE', 'ENDWHILE',
           'READ', 'WRITE', 'VAR', 'END');
  KWcode: string[NKW1] = 'xileweRWve';
  MaxEntry = 100;

var
  Look: Char;                    { Lookahead Character }
  LCount: Integer = 0;
  Token: Char;                   { Encoded Token       }
  Value: string[16];             { Unencoded Token     }
  ST: array[1..MaxEntry] of Symbol;
  SType: array[1..MaxEntry] of Char;
  NEntry: Integer = 0;

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

{ Report an Undefined Identifier }
procedure Undefined(n: string);
begin
  Abort('Undefined Identifier ' + n);
end;

{ Report a Duplicate Identifier }
procedure Duplicate(n: string);
begin
  Abort('Duplicate Identifier ' + n);
end;

{ Check to Make Sure the Current Token is an Identifier }
procedure CheckIdent;
begin
  if Token <> 'x' then Expected('Identifier');
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

{ Recognize a Boolean Orop }
function IsOrop(c: Char): Boolean;
begin
  IsOrop := c in ['|', '~'];
end;

{ Recognize a Relop }
function IsRelop(c: Char): Boolean;
begin
  IsRelop := c in ['=', '#', '<', '>'];
end;

{ Recognize White Space }
function IsWhite(c: Char): Boolean;
begin
  IsWhite := c in [' ', TAB, CR, LF];
end;

{ Skip Over Leading White Space }
procedure SkipWhite;
begin
  while IsWhite(Look) do
    GetChar();
end;


{ Output a String with Tab }
procedure Emit(s: string);
begin
  Write(TAB, s);
end;

{ Output a String with Tab and CRLF }
procedure EmitLn(s: string);
begin
  Emit(s);
  Writeln;
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

{-----------------------------------------------------------------}

{ Table Lookup }
function Lookup(T: TabPtr; s: string; n: Integer): Integer;
var
  i: Integer;
  found: Boolean;
begin
  found := False;
  i := n;
  while (i > 0) and not found do begin
    if s = T^[i] then
      found := True
    else
      Dec(i);
  end;
  Lookup := i;
end;

{ Locate a Symbol in Table}
{ Return the Index of the Entry, Zero if not present }
function Locate(N: Symbol): Integer;
begin
  Locate := Lookup(@ST, n, NEntry);
end;

{ Look for Symbol in Table }
function InTable(n: Symbol): Boolean;
begin
  InTable := Lookup(@ST, n, NEntry) <> 0;
end;

{ Check to See if an Identifier is in the Symbol Table }
{ Report an error if it's not }
procedure CheckTable(N: Symbol);
begin
  if not InTable(N) then Undefined(N);
end;

{ Check the Symbol Table for a Duplicate Identifier }
{ Report an Error if Identifier is already in Table }
procedure CheckDup(N: Symbol);
begin
  if InTable(N) then Duplicate(N);
end;

{ Add a New Entry to Symbol Table }
procedure AddEntry(N: Symbol; T: Char);
begin
  CheckDup(N);
  if NEntry = MaxEntry then Abort('Symbol Table Full');
  Inc(NEntry);
  ST[NEntry] := N;
  SType[NEntry] := T;
end;

{ Get an Identifier }
procedure GetName;
begin
  SkipWhite();
  if not IsAlpha(Look) then Expected('Identifier');
  Token := 'x';
  Value := '';
  repeat
    Value := Value + UpCase(Look);
    GetChar();
  until not IsAlNum(Look);
end;

{ Get a Number }
procedure GetNum;
begin
  SkipWhite();
  if not IsDigit(Look) then Expected('Integer');
  Token := '#';
  Value := '';
  repeat
    Value := Value + Look;
    GetChar();
  until not IsDigit(Look);
end;

{ Get an Operator }
procedure GetOp;
begin
  SkipWhite();
  Token := Look;
  Value := Look;
  GetChar();
end;

{ Get the Next Input Token }
procedure Next;
begin
  SkipWhite();
  if IsAlpha(Look) then GetName()
  else if IsDigit(Look) then GetNum()
  else GetOp()
end;

{ Get an Identifier and Scan it for Keywords }
procedure Scan;
begin
  if Token = 'x' then
    Token := KWcode[Lookup(Addr(KWlist), Value, NKW) + 1];
end;

{ Match a Specific Input String }
procedure MatchString(x: string);
begin
  if Value <> x then Expected('''' + x + '''');
  Next();
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
procedure LoadConst(n: string);
begin
  Emit('MOVE #');
  Writeln(n, ',D0');
end;

{ Load a Variable to Primary Register }
procedure LoadVar(Name: string);
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
procedure Store(Name: string);
begin
  EmitLn('LEA ' + Name + '(PC),A0');
  EmitLn('MOVE D0,(A0)');
end;


{ Complement the Primary Register }
procedure NotIt;
begin
  EmitLn('NOT D0');
end;

{ AND Top of Stack with Primary }
procedure PopAnd;
begin
  EmitLn('AND (SP)+,D0');
end;

{ OR Top of Stack with Primary }
procedure PopOr;
begin
  EmitLn('OR (SP)+,D0');
end;

{ XOR Top of Stack with Primary }
procedure PopXor;
begin
  EmitLn('EOR (SP)+,D0');
end;

{ Compare Top of Stack with Primary }
procedure PopCompare;
begin
  EmitLn('CMP (SP)+,D0');
end;

{ Set D0 If Compare was = }
procedure SetEqual;
begin
  EmitLn('SEQ D0');
  EmitLn('EXT D0');
end;

{ Set D0 If Compare was != }
procedure SetNEqual;
begin
  EmitLn('SNE D0');
  EmitLn('EXT D0');
end;

{ Set D0 If Compare was > }
procedure SetGreater;
begin
  EmitLn('SLT D0');
  EmitLn('EXT D0');
end;

{ Set D0 If Compare was < }
procedure SetLess;
begin
  EmitLn('SGT D0');
  EmitLn('EXT D0');
end;

{ Set D0 If Compare was <= }
procedure SetLessOrEqual;
begin
  EmitLn('SGE D0');
  EmitLn('EXT D0');
end;

{ Set D0 If Compare was >= }
procedure SetGreaterOrEqual;
begin
  EmitLn('SLE D0');
  EmitLn('EXT D0');
end;


{ Branch Unconditional }
procedure Branch(L: string);
begin
  EmitLn('BRA ' + L);
end;

{ Branch False }
procedure BranchFalse(L: string);
begin
  EmitLn('TST D0');
  EmitLn('BEQ ' + L);
end;


{ Read Variable to Primary Register }
procedure ReadIt(Name: string);
begin
  EmitLn('BSR READ');
  Store(Name);
end;

{ Write Variable from Primary Register }
procedure WriteIt;
begin
  EmitLn('BSR WRITE');
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

{ Allocate Storage for a Variable }
procedure Allocate(Name, Val: Symbol);
begin
  Writeln(Name, ':', TAB, 'DC ', Val);
end;

{-----------------------------------------------------------------}

{ Parse and Translate a Math Factor }
procedure BoolExpression; forward;
procedure Expression; forward;
procedure Factor;
begin
  if Look = '(' then begin
    Next();
    BoolExpression();
    MatchString(')');
  end
  else begin
    if Token = 'x' then
      LoadVar(Value)
    else if Token = '#' then
      LoadConst(Value)
    else
      Expected('Math Factor');
    Next();
  end;
end;

{ Recognize and Translate a Multiply }
procedure Multiply;
begin
  Next();
  Factor();
  PopMul();
end;

{ Recognize and Translate a Divide }
procedure Divide;
begin
  Next();
  Factor();
  PopDiv();
end;

{ Parse and Translate a Math Term }
procedure Term;
begin
  Factor();
  while IsMulop(Token) do begin
    Push();
    case Token of
      '*': Multiply();
      '/': Divide();
    end;
  end;
end;

{ Recognize and Translate an Add }
procedure Add;
begin
  Next();
  Term();
  PopAdd();
end;

{ Recognize and Translate a Subtract }
procedure Subtract;
begin
  Next();
  Term();
  PopSub();
end;

{ Get Another Expression and Compare }
procedure CompareExpression;
begin
  Expression();
  PopCompare();
end;

{ Get The Next Expression and Compare }
procedure NextExpression;
begin
  Next();
  CompareExpression();
end;

{ Parse and Translate an Expression }
procedure Expression;
begin
  if IsAddop(Token) then
    Clear()
  else
    Term();
  while IsAddop(Token) do begin
    Push();
    case Token of
      '+': Add();
      '-': Subtract();
    end;
  end;
end;

{ Parse and Translate an Assignment Statement }
procedure Assignment;
var
  Name: string;
begin
  CheckTable(Value);
  Name := Value;
  Next();
  MatchString('=');
  BoolExpression();
  Store(Name);
end;

{-----------------------------------------------------------------}

{ Recognize and Translate a Relational "Equals" }
procedure Equal;
begin
  NextExpression();
  SetEqual();
end;

{ Recognize and Translate a Relational "Less Than or Equal" }
procedure LessOrEqual;
begin
  NextExpression();
  SetLessOrEqual();
end;

{ Recognize and Translate a Relational "Not Equals" }
procedure NotEqual;
begin
  NextExpression();
  SetNEqual();
end;

{ Recognize and Translate a Relational "Less Than" }
procedure Less;
begin
  Next();
  case Token of
    '=': LessOrEqual();
    '>': NotEqual();
  else
    begin
      CompareExpression();
      SetLess();
    end;
  end;
end;

{ Recognize and Translate a Relational "Greater Than" }
procedure Greater;
begin
  Next();
  if Token = '=' then begin
    NextExpression();
    SetGreaterOrEqual();
  end
  else begin
    CompareExpression();
    SetGreater();
  end;
end;

{ Parse and Translate a Relation }
procedure Relation;
begin
  Expression();
  if IsRelop(Look) then begin
    Push();
    case Look of
      '=': Equal();
      '<': Less();
      '>': Greater();
    end;
  end;
end;

{ Parse and Translate a Boolean Factor with Leading NOT }
procedure NotFactor;
begin
  if Look = '!' then begin
    Next();
    Relation();
    NotIt();
  end
  else
    Relation()
end;

{ Parse and Translate a Boolean Term }
procedure BoolTerm;
begin
  NotFactor();
  while Look = '&' do begin
    Push();
    Next();
    NotFactor();
    PopAnd();
  end;
end;

{ Recognize and Translate a Boolean OR }
procedure BoolOr;
begin
  Next();
  BoolTerm();
  PopOr();
end;  

{ Recognize and Translate an Exclusive Or }
procedure BoolXor;
begin
  Next();
  BoolTerm();
  PopXor();
end;

{ Parse and Translate a Boolean Expression }
procedure BoolExpression;
begin
  BoolTerm();
  while IsOrop(Look) do begin
    Push();
    case Look of
      '|': BoolOr();
      '~': BoolXor();
    end;
  end;
end;

{-----------------------------------------------------------------}

{ Recognize and Translate an IF Construct }
procedure Block; forward;

procedure DoIf;
var
  L1, L2: string;
begin
  Next();
  BoolExpression();
  L1 := NewLabel();
  L2 := L1;
  BranchFalse(L1);
  Block();
  if Token = 'l' then begin
    Next();
    L2 := NewLabel();
    Branch(L2);
    PostLabel(L1);
    Block();
  end;
  PostLabel(L2);
  MatchString('ENDIF');
end;

{ Parse and Translate a WHILE Statement }
procedure DoWhile;
var
  L1, L2: string;
begin
  Next();
  L1 := NewLabel();
  L2 := NewLabel();
  PostLabel(L1);
  BoolExpression();
  BranchFalse(L2);
  Block();
  MatchString('ENDWHILE');
  Branch(L1);
  PostLabel(L2);
end;

{ Read a Single Variable }
procedure ReadVar;
begin
  CheckIdent();
  CheckTable(Value);
  ReadIt(Value);
  Next();
end;

{ Process a Read Statement }
procedure DoRead;
begin
  Next();
  MatchString('(');
  ReadVar();
  while Look = ',' do begin
    Next();
    ReadVar();
  end;
  MatchString(')');
end;

{ Process a Write Statement }
procedure DoWrite;
begin
  Next();
  MatchString('(');
  Expression();
  WriteIt();
  while Token = ',' do begin
    Next();
    Expression();
    WriteIt();
  end;
  MatchString(')');
end;

{ Parse and Translate a Block of Statement }
procedure Block;
begin
  Scan();
  while not (Token in ['e', 'l']) do begin
    case Token of
      'i': DoIf();
      'w': DoWhile();
      'R': DoRead();
      'W': DoWrite();
    else
      Assignment();
    end;
    Scan();
  end;
end;

{-----------------------------------------------------------------}

{ Allocate Storage for a Variable }
procedure Alloc;
begin
  Next();
  if Token <> 'x' then Expected('Variable Name');
  CheckDup(Value);
  AddEntry(Value, 'v');
  Allocate(Value, '0');
  Next();
end;

{ Parse and Translate Global Declarations }
procedure TopDecls;
begin
  Scan();
  while Token = 'v' do
  begin
    Alloc();
    while Token = ',' do
    begin
      Alloc();
    end;
  end;
end;

{ Initialize }
procedure Init;
begin
  GetChar();
  Next();
end;

{-----------------------------------------------------------------}

{ Main Program }
begin
  Init();
  MatchString('PROGRAM');
  Header();
  TopDecls();
  MatchString('BEGIN');
  Prolog();
  Block();
  MatchString('END');
  Epilog();
end.

