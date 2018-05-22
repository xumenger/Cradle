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
  LCount: Integer;     //Label Counter


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
    //
    Break;
  end;
  GetName := Token;
  SkipWhite();
end;

{ Get a Number }
function GetNum: string;
var
  Value: string;
begin
  Value := '';
  if not IsDigit(Look) then Expected('Integer');
  while IsDigit(Look) do begin
    Value := Value + Look;
    GetChar();
  end;
  GetNum := Value;
  SkipWhite();
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

procedure Expression; forward;

function IsAddop(c: Char): Boolean;
begin
  IsAddop := c in ['+', '-'];
end;

{ Parse and Translate an Identifier }
procedure Ident;
var
  Name: string;
begin
  Name := GetName();
  if Look = '(' then begin
    Match('(');
    Match(')');
    EmitLn('BSR ' + Name);
  end
  else
    EmitLn('MOVE ' + Name + '(PC),D0');
end;

{ BNF: <factor> ::= <number> | (<expression>) | <ident> }
procedure Factor;
begin
  if Look = '(' then begin
    Match('(');
    Expression();
    Match(')');
  end
  else if IsAlpha(Look) then
    Ident()
  else
    EmitLn('MOVE #' + GetNum() + ',D0');
end;

{ Recognize and Translate a Multiply }
procedure Multiply;
begin
  Match('*');
  Factor();
  EmitLn('MULS (SP)+,D0');
end;

{ Recognize and Translate a Divide }
procedure Divide;
begin
  Match('/');
  Factor();
  EmitLn('MOVE (SP)+,D1');
  EmitLn('EXS.L D0');
  EmitLn('DIVS D1,D0');
end;

{ BNF: <term> ::= <factor> [<mulop> <factor>]* }
procedure Term;
begin
  Factor;
  while Look in ['*', '/'] do begin
    EmitLn('MOVE D0,-(SP)');
    case Look of
      '*': Multiply;
      '/': Divide;
    //else Expected('Mulop');
    end;
  end;
end;

{ Recognize and Translate an Add }
procedure Add;
begin
  Match('+');
  Term;
  EmitLn('ADD (SP)+,D0');
end;

{ Recognize and Translate a Subtract }
procedure Subtract;
begin
  Match('-');
  Term;
  EmitLn('SUB (SP)+,D0');
  EmitLn('NEG D0');
end;

{ BNF: <expression> ::= <term> [<addop> <term>]* }
procedure Expression;
begin
  {
  if IsAddop(Look) then
    EmitLn('CLR D0')
  else
    Term;
  while IsAddop(Look) do begin
    EmitLn('MOVE D0,-(SP)');
    case Look of
      '+': Add;
      '-': Subtract;
    //else Expected('Addop');
    end;;
  end; }

  EmitLn('<expr>')
end;

{ Parse and Translate an Assignment Statement }
{ BNF: <ident> = <expession> }
procedure Assignment;
var
  Name: string;
begin
  Name := GetName();
  Match('=');
  Expression();
  EmitLn('LEA ' + Name + '(PC),A0');
  EmitLn('MOVE D0,(A0)');
end;

{-----------------Program Construct-------------------}
procedure DoIf; forward;
procedure Condition; forward;
procedure DoWhile; forward;
procedure DoLoop; forward;
procedure DoRepeat; forward;
procedure DoFor; forward;
procedure Dodo; forward;

{ Recognize and Translate an "Other" }
procedure Other;
begin
  EmitLn(GetName());
end;

{ Recognize and Translate a Statement Block
BNF: <block> ::= [<statement>]* }
procedure Block;
begin
  while not (Look in ['e', 'l', 'u']) do begin
    case Look of
      'i': DoIf();
      'w': DoWhile();
      'p': DoLoop();
      'r': DoRepeat();
      'f': DoFor();
      'd': Dodo();
      'o': Other();
    end;
  end;
end;

{ Parse and Translate a Program
BNF: <program> ::= <block> END }
procedure DoProgram;
begin
  Block();
  if Look <> 'e' then Expected('End');
  EmitLn('END');
end;

{ if condition construct
Pascal: IF <condition> THEN <statement>
C:      IF (<condition>) <statement>
Ada:    IF <condition> <block> [ELSE <block>] ENDIF


     <condition>
     BEQ L1
     <block>
     BRA L2
L1:  <block>
L2:  ...


IF
<condition>  [ L1 = NewLabel;
               L2 = NewLabel;
               Emit(BEQ L1) ]
<block>
ELSE         [ Emit(BRA L2);
               PostLabel(L1)]
<block>
ENDIF        [ PostLabel(L2) ]
}

{ Generate a Unique Label }
function NewLabel: string;
var
  S: string;
begin
  Str(LCount, S);
  NewLabel := 'L' + S;
  Inc(LCount);
end;

{ Post a Label To Output}
procedure PostLabel(L: string);
begin
  Writeln(L, ':');
end;

{ Recognize and Translate an IF Construct
BEQ  <==>  Branch if false
BNE  <==>  Branch if true}
procedure DoIf;
var
  L1, L2: string;
begin
  Match('i');
  Condition();
  L1 := NewLabel();
  L2 := L1;
  EmitLn('BEQ ' + L1);
  Block();
  if Look = 'l' then begin
    Match('l');
    L2 := NewLabel();
    EmitLn('BRA ' + L2);
    PostLabel(L1);
    Block();
  end;
  Match('e');
  PostLabel(L2);
end;

{ Parse and Translate a Boolean Condition }
procedure Condition;
begin
  EmitLn('<condition>');
end;

{ WHILE <condition> <block> ENDWHILE

L1:  <condition>
     BEQ L2
     <block>
     BRA L1
L2:


WHILE        [ L1 = NewLabel;
               PostLabel(L1); ]
<condition>  [ Emit(BEQ L2) ]
<block>
ENDWHILE     [ Emit(BRA L1);
               PostLabel(L2); ]
}

{ Parse and Translate a WHILE Statement }
procedure DoWhile;
var
  L1, L2: string;
begin
  Match('w');
  L1 := NewLabel();
  L2 := NewLabel();
  PostLabel(L1);
  Condition();
  EmitLn('BEQ ' + L2);
  Block();
  Match('e');
  EmitLn('BRA ' + L1);
  PostLabel(L2);
end;

{ LOOP <block> ENDLOOP

LOOP      [ L= NewLabel;
            PostLabel(L);]
<block>
ENDLOOP   [ Emit(BRA L); ]
}

{ Parse and Translate a LOOP Statement }
procedure DoLoop;
var
  L: string;
begin
  Match('p');
  L := NewLabel();
  PostLabel(L);
  Block();
  Match('e');
  EmitLn('BRA ' + L);
end;  

{ REPEAT <block> UNTIL <condition>

REPEAT       [ L = NewLabel;
               PostLabel(L); ]
<block>
UNTIL
<condition>  [ Emit(BEQ L) ]
}

{ Parse and Translate a REPEAT Statement }
procedure DoRepeat;
var
  L: string;
begin
  Match('r');
  L := NewLabel();
  PostLabel(L);
  Block();
  Match('u');
  Condition();
  EmitLn('BEQ ' + L);
end;

{ FOR <ident> = <expr1> TO <expr2> <block> ENDFOR

first translate to while

<ident> = <expr1>
TEMP = <expr2>
WHILE <ident> <= TEMP
<block>
ENDWHILE
}

{ Parse and Translate a FOR Statement }
procedure DoFor;
var
  L1, L2: string;
  Name: string;
begin
  Match('f');
  L1 := NewLabel();
  L2 := NewLabel();
  Name := GetName();
  Match('=');
  Expression();
  EmitLn('SUBQ #1,D0');
  EmitLn('LEA ' + Name + '(PC),A0');
  EmitLn('MOVE D0,(A0)');
  Expression();
  EmitLn('MOVE D0,-(SP)');
  PostLabel(L1);
  EmitLn('LEA ' + Name + '(PC),A0');
  EmitLn('MOVE (A0),D0');
  EmitLn('ADDQ #1,D0');
  EmitLn('MOVE D0,(A0)');
  EmitLn('CMP (SP),D0');
  EmitLn('BGT ' + L2);
  Block();
  Match('e');
  EmitLn('BRA ' + L1);
  PostLabel(L2);
  EmitLn('ADDQ #2,SP');
end;

{ DO STATEMENT
Do
<expr>      [ Emit(SUBQ #1,D0)];
              L = NewLabel;
              PostLabel(L);
              Emit(MOVE D0, -(SP)]
<block>
ENDDO       [ Emit(MOVE (SP)+,D0);
              Emit(DBRA D0,L)]
}

{ Parse and Translate a DO Statement }
procedure Dodo;
var
  L: string;
begin
  Match('d');
  L := NewLabel();
  Expression();
  EmitLn('SUBQ #1,D0');
  PostLabel(L);
  EmitLn('MOVE D0,-(SP)');
  Block();
  EmitLn('MOVE (SP)+,D0');
  EmitLn('DBRA D0,' + L);
end;

{----------------------Initialize--------------------}
procedure Init;
begin
  LCount := 0;
  GetChar();
  SkipWhite();
end;

{-----------------------Run---------------------------}
{ Main Program }
begin
  Init();
  DoProgram();
end.

