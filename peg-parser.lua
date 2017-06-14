local lpeg = require "lpeg-funcs"
local peg = {}

local P, V = lpeg.P, lpeg.V
local T = lpeg.T -- lpeglabel
local token, kw = lpeg.token, lpeg.kw



-- imported from relabel.lua :


local errinfo = {
  {"NoPatt", "no pattern found"},
  {"ExtraChars", "unexpected characters after the pattern"},

  {"ExpPatt1", "expected a pattern after '/' or the label(s)"},

  {"ExpPatt2", "expected a pattern after '&'"},
  {"ExpPatt3", "expected a pattern after '!'"},

  {"ExpPatt4", "expected a pattern after '('"},
  {"ExpPatt5", "expected a pattern after ':'"},
  {"ExpPatt6", "expected a pattern after '{~'"},
  {"ExpPatt7", "expected a pattern after '{|'"},

  {"ExpPatt8", "expected a pattern after '<-'"},

  {"ExpPattOrClose", "expected a pattern or closing '}' after '{'"},

  {"ExpNum", "expected a number after '^', '+' or '-' (no space)"},
  {"ExpCap", "expected a string, number, '{}' or name after '->'"},

  {"ExpName1", "expected the name of a rule after '=>'"},
  {"ExpName2", "expected the name of a rule after '=' (no space)"},
  {"ExpName3", "expected the name of a rule after '<' (no space)"},

  {"ExpLab1", "expected at least one label after '{'"},
  {"ExpLab2", "expected a label after the comma"},

  {"ExpNameOrLab", "expected a name or label after '%' (no space)"},

  {"ExpItem", "expected at least one item after '[' or '^'"},

  {"MisClose1", "missing closing ')'"},
  {"MisClose2", "missing closing ':}'"},
  {"MisClose3", "missing closing '~}'"},
  {"MisClose4", "missing closing '|}'"},
  {"MisClose5", "missing closing '}'"},  -- for the captures

  {"MisClose6", "missing closing '>'"},
  {"MisClose7", "missing closing '}'"},  -- for the labels

  {"MisClose8", "missing closing ']'"},

  {"MisTerm1", "missing terminating single quote"},
  {"MisTerm2", "missing terminating double quote"},
}



local errmsgs = {}
local labels = {}

for i, err in ipairs(errinfo) do
  errmsgs[i] = err[2]
  labels[err[1]] = i
end


local function expect (pattern, labelname)
  local label = labels[labelname]
  local record = function (input, pos, syntaxerrs)
    table.insert(syntaxerrs, { label = label, pos = pos })
    return true
  end
  return pattern + lpeg.Cmt(lpeg.Carg(2), record) * lpeg.T(label)
end



-- end

re = require "re"

testgram =  [[

	program <- stmtsequence
	stmtsequence <- statement (';' statement)*
	statement <- ifstmt / repeatstmt / assignstmt / readstmt / writestmt
	ifstmt <- 'if' exp 'then' stmtsequence ('else' stmtsequence)? 'end'
	repeatstmt <- 'repeat' stmtsequence 'until' exp
	assignstmt <- IDENTIFIER ':=' exp
	readstmt <- 'read' IDENTIFIER
	writestmt <- 'write' exp
	exp <- simpleexp (COMPARISONOP simpleexp)*
	COMPARISONOP <- '<' / '='
	simpleexp <- term (ADDOP term)*
	ADDOP <- '+' / '-'
	term <- factor (MULOP factor)*
	MULOP <- '*' / '/'
	factor <- '(' exp ')' / NUMBER / IDENTIFIER

	NUMBER <- '-'? [0-9]+
	IDENTIFIER <- [a-zA-Z]+
	
	
]]


--g = re.compile(testgram)

--print(g:match("a:=1;ifcthendend"))

local function tp(rulename, rule)
	print("{rulename = "..rulename..", rule = "..rule.."}")
end
local function tpr(action,op1,op2)
	if op2 then
		print("{action = "..action..", op1 = "..op1..", op2 = "..op2.."}")
	else
		print("{action = "..action..", op1 = "..op1.."}")
	end
end


p = re.compile [=[

pattern         <- exp !.
exp             <- S (grammar / alternative)

alternative     <- {| {:action: ''->'or':} {:op1: seq :} '/' S {:op2: alternative:} |}
					/ seq
seq             <- {| {:action: ''->'and':} {:op1: prefix :} {:op2: seq:} |}
					/ prefix
prefix          <- '&' S prefix / '!' S prefix / suffix
suffix          <- primary S (([+*?]
                            / '^' [+-]? num
                            / '->' S (string / '{}' / name)
                            / '=>' S name) S)*

primary         <- '(' exp ')' / string / class / defined
                 / '{:' (name ':')? exp ':}'
                 / '=' name
                 / '{}'
                 / '{~' exp '~}'
                 / '{' exp '}'
                 / '.'
                 / name S !arrow
                 / '<' name '>'          -- old-style non terminals

grammar         <- {| definition+ |}
definition      <- {| {:rulename: name :} S arrow {:rule: exp :} |}

class           <- '[' '^'? item (!']' item)* ']'
item            <- defined / range / .
range           <- . '-' [^]]

S               <- (%s / '--' [^%nl]*)*   -- spaces and comments
name            <- [A-Za-z][A-Za-z0-9_]*
arrow           <- '<-'
num             <- [0-9]+
string          <- '"' [^"]* '"' / "'" [^']* "'"
defined         <- '%' name

]=]
--
res = p:match(testgram)
print(res);
lpeg.print_r(res);
--print(grammar:match(testgram))

--[[
Function: parse(input)

Input: a grammar in PEG format, described in https://github.com/vsbenas/parser-gen

Output: if parsing successful - a table of grammar rules, else - runtime error

Example input: 	"Program <- stmt* / SPACE;
		stmt <- ('a' / 'b')+;
		SPACE <- '';"
Example output: {
	{rulename = "Program", 	rule = {action = "or", op1 = {action = "zero-or-more", op1 = "stmt"}, op2 = "SPACE"}},
	{rulename = "stmt", 	rule = {action = "one-or-more", op1 = {action="or", op1 = "'a'", op2 = 'b'}},
	{rulename = "SPACE",	rule = "''", token=1},

}

The rules are further processed and turned into lpeg compatible format in parser-gen.lua

]]--
function peg.pegToAST(input)
	return grammar:match(input)
end

if arg[1] then	
	-- argument must be in quotes if it contains spaces
	lpeg.print_r(peg.pegToAST(arg[1]));
end

return peg
