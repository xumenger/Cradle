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
           'VAR', 'BEGIN', 'END', 'PROGRAM');
  KWcode: string[NKW1] = 'xilewevbep';
  MaxEntry = 100;

var
  Look: Char;                    { Lookahead Character }
  LCount: Integer;
  ST: array[1..MaxEntry] of Symbol;
  SType: array[1..MaxEntry] of Symbol;
  Token: Char;                   { Encoded Token       }
  Value: string[16];             { Unencoded Token     }
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
  IsWhite := c in [' ', TAB];
end;

{ Skip Over Leading White Space }
procedure SkipWhite;
begin
  while IsWhite(Look) do
    GetChar();
end;

{ Skip Over an End-of-Line }
procedure NewLine;
begin
  while Look = CR do begin
    GetChar();
    if Look = LF then GetChar();
    SkipWhite();
  end;
end;

{ Get an Identifier }
procedure GetName;
begin
  NewLine();
  if not IsAlpha(Look) then Expected('Name');
  Value := '';
  while IsAlNum(Look) do begin
    Value := Value + UpCase(Look);
    GetChar();
  end;
  SkipWhite();
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

{ Match a Specific Input String }
procedure MatchString(x: string);
begin
  if Value <> x then Expected('''' + x + '''');
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
function Lookup(T: TabPtr; s: string; n: Integer): Integer; forward;
function InTable(n: Symbol): Boolean;
begin
  InTable := Lookup(@ST, n, MaxEntry) <> 0;
end;

{ Add a New Entry to Symbol Table }
procedure AddEntry(N: Symbol; T: Char);
begin
  if InTable(N) then Abort('Duplicate Identifier ' + N);
  if NEntry = MaxEntry then Abort('Symbol Table Full');
  Inc(NEntry);
  ST[NEntry] := N;
  SType[NEntry] := T;
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
  EmitLn('SEG D0');
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

{-----------------------------------------------------------------}

{ Parse and Translate a Math Factor }
procedure Expression; forward;
procedure BoolExpression; forward;
procedure Factor;
begin
  if Look = '(' then begin
    Match('(');
    BoolExpression();
    Match(')');
  end
  else if IsAlpha(Look) then begin
    GetName();
    LoadVar(Value[1]);
  end
  else
    LoadConst(GetNum());
end;

{ Parse and Translate a Negative Factor }
procedure NegFactor;
begin
  Match('-');
  if IsDigit(Look) then
    LoadConst(-GetNum())
  else begin
    Factor();
    Negate();
  end;
end;

{ Parse and Translate a Leading Factor }
procedure FirstFactor;
begin
  case Look of
    '+': begin
      Match('+');
      Factor();
      end;
    '-':
      NegFactor();
  else
    Factor();
  end;
end;

{ Recognize and Translate a Multiply }
procedure Multiply;
begin
  Match('*');
  Factor();
  PopMul();
end;

{ Recognize and Translate a Divide }
procedure Divide;
begin
  Match('/');
  Factor();
  PopDiv();
end;

{ Common Code Used by Term and FirstTerm }
procedure Term1;
begin
  while IsMulop(Look) do begin
    Push();
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

{ Parse and Translate a Leading Term }
procedure FirstTerm;
begin
  FirstFactor();
  Term1();
end;

{ Recognize and Translate an Add }
procedure Add;
begin
  Match('+');
  Term();
  PopAdd();
end;

{ Recognize and Translate a Subtract }
procedure Subtract;
begin
  Match('-');
  Term();
  PopSub();
end;

{ Parse and Translate an Expression }
procedure Expression;
begin
  FirstTerm();
  while IsAddop(Look) do begin
    Push();
    case Look of
      '+': Add();
      '-': Subtract();
    end;
  end;
end;

{ Parse and Translate an Assignment Statement }
procedure Assignment;
var
  Name: Char;
begin
  Name := Value[1];
  Match('=');
  BoolExpression();
  Store(Name);
end;

{-----------------------------------------------------------------}

{ Recognize and Translate a Relational "Equals" }
procedure Equal;
begin
  Match('=');
  Expression();
  //BoolExpression();
  PopCompare();
  SetEqual();
end;

{ Recognize and Translate a Relational "Less Than or Equal" }
procedure LessOrEqual;
begin
  Match('=');
  Expression();
  PopCompare();
  SetLessOrEqual();
end;

{ Recognize and Translate a Relational "Not Equals" }
procedure NotEqual;
begin
  Match('>');
  Expression();
  PopCompare();
  SetNEqual();
end;

{ Recognize and Translate a Relational "Less Than" }
procedure Less;
begin
  Match('<');
  case Look of
    '=': LessOrEqual();
    '>' : NotEqual();
  else
    begin
      Expression();
      PopCompare();
      SetLess();
    end;
  end;
end;

{ Recognize and Translate a Relational "Greater Than" }
procedure Greater;
begin
  Match('>');
  if Look = '=' then begin
    Match('=');
    Expression();
    PopCompare();
    SetGreaterOrEqual();
  end
  else begin
    Expression();
    PopCompare();
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
      '#': NotEqual();
      '<': Less();
      '>': Greater();
    end;
  end;
end;

{ Parse and Translate a Boolean Factor with Leading NOT }
procedure NotFactor;
begin
  if Look = '!' then begin
    Match('!');
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
    Match('&');
    NotFactor();
    PopAnd();
  end;
end;

{ Recognize and Translate a Boolean OR }
procedure BoolOr;
begin
  Match('|');
  BoolTerm();
  PopOr();
end;  

{ Recognize and Translate an Exclusive Or }
procedure BoolXor;
begin
  Match('~');
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
  BoolExpression();
  L1 := NewLabel();
  L2 := L1;
  BranchFalse(L1);
  Block();
  if Token = 'l' then begin
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

{ Get an Identifier and Scan it for Keywords }
procedure Scan;
begin
  GetName();
  Token := KWcode[Lookup(Addr(KWlist), Value, NKW) + 1];
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
  if InTable(N) then Abort('Duplicate Variable Name ' + N);
  AddEntry(N, 'v');
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
  GetName();
  Alloc(Value[1]);
  while Look = ',' do begin
    Match(',');
    GetName();
    Alloc(Value[1]);
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
    Scan();
  end;
end;

{ Parse and Translate a Block of Statement }
procedure Block;
begin
  while not (Look in ['e', 'l']) do begin
    case Look of
      'i': DoIf();
      'w': DoWhile();
    else
      Assignment();
    end;
    Scan();
  end;
end;

{ Parse and Translate a Main Program }
procedure Main;
begin
  MatchString('BEGIN');
  Prolog();
  Block();
  MatchString('END');
  Epilog();
end;

{-----------------------------------------------------------------}

{ Parse and Translate a Program }
procedure Prog;
begin
  MatchString('PROGRAM');
  Header();
  TopDecls();
  Main();
  MatchString('.');
end;

{ Initialize }
procedure Init;
var
  i: Integer;
begin
  LCount := 0;
  for i := 1 to MaxEntry do begin
    ST[i] := ' ';
    SType[i] := ' ';
  end;
  GetChar();
  Scan();
end;

{-----------------------------------------------------------------}

{ Main Program }
begin
  Init();
  Prog();
  if Look <> CR then Abort('Unexpected data after ''.''')
end.

