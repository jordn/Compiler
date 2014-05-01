/*
*  cool.y
*              Parser definition for the COOL language.
*
*/

/* http://www.gnu.org/software/bison/manual/bison.html#Prologue
 */
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  #include "list.h"
  
  extern char *curr_filename;
  
  
  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */
    
    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */
      
      
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;
    
    
    #define SET_NODELOC(Current)  \
    node_lineno = Current;
    
    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to 
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive 
    * (fictional) construct that matches a plus between two integer constants. 
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
    
    plus_consts : INT_CONST '+' INT_CONST 
    
    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:
    
    plus_consts : INT_CONST '+' INT_CONST 
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th exporession with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you 
      // omit the statement @$=..., bison has default rules for deciding which 
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;
      
      
      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of 
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);
      
      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }
    
    */
    
    
    
    void yyerror(char *s);        /*  defined below; called for each parse error */
    extern int yylex();           /*  the entry point to the lexer  */

    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
    
    Program ast_root;       /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}
    
    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276 
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279 
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list
    %type <class_> class
    %type <features> features_list
    %type <features> features
    %type <feature> feature
    %type <formals> formals
    %type <formal> formal
    %type <cases> case_branch_list 
    %type <case_> case_branch
    %type <expressions> one_or_more_expr
    %type <expressions> param_expr
    %type <expression> expr
    %type <expression> let_expr

    /* Precedence declarations go here.
    /* "The declarations %left and %right ([left and] right associativity) take the place of %token
     * which is used to declare a token type name without associativity/precedence.
     * - Bison manual - sec 2.2 */
    %right ASSIGN
    %left NOT
    %nonassoc LE '<' '='
    %left '+' '-'
    %left '*' '/'
    %left ISVOID
    %left '~'
    %left '@'
    %left '.'

    %%
    /* Think about what this grammar means; a program is made up of a list of one or more classes */
    program     : class_list { 
                    /* Save the root of the abstract syntax tree in a global variable @$ 
                     * See section 6.5 in the Tour of Cool pdf */
                    @$ = @1; ast_root = program($1); }
                ;
    
    class_list  : class {
                    /* "In each action, the pseudo-variable $$ stands for the semantic value for the grouping that the rule is going to construct.
                     * Assigning a value to $$ is the main job of most actions.
                     * The semantic values of the components of the rule are referred to as $1, $2, and so on."
                     * - Bison 3.0 manual */
                    $$ = single_Classes($1);
                    /* per variable declaration, "used in semantic analysis" */
                    parse_results = $$; }
                | class_list class {
                    $$ = append_Classes($1,single_Classes($2));
                    parse_results = $$; }
                ;
    
    /* if no parent is specified, the class inherits from the Object class. */
    /* notice the optional "inherits" expression is handled by options in the grammar */
    class     : CLASS TYPEID '{' features_list '}' ';' {
                    /* The class_ constructor builds a Class_ tree node with four arguments as children  */
                    $$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename)); }
                | CLASS TYPEID INHERITS TYPEID '{' features_list '}' ';' {
                    $$ = class_($2, $4, $6, stringtable.add_string(curr_filename)); }

                /* handling errors in class definitions and body */
                | CLASS TYPEID '{' error '}' ';' { yyclearin; $$ = NULL; }
                | CLASS error '{' features_list '}' ';' { yyclearin; $$ = NULL; }
                | CLASS error '{' error '}' ';' { yyclearin; $$ = NULL; }
                ;
    
    /* features_list may be empty, but no empty features in list. 
     * practically, this means the nonterminal features_list can be empty,
     * but we cannot allow the features nonterminal to call nil_Features() */
    features_list   : features { $$ = $1; }
                    | { $$ = nil_Features(); }
                    ;
    features    : feature ';' { $$ = single_Features($1); }
                | features feature ';' { $$ = append_Features($1, single_Features($2)); }
                | error ';' { yyclearin; $$ = NULL; }
                ;
    feature     : OBJECTID '(' formals ')' ':' TYPEID '{' expr '}' { $$ = method($1, $3, $6, $8); }
                /* attribute w/ and w/o assignment */
                | OBJECTID ':' TYPEID { $$ = attr($1, $3, no_expr()); }
                | OBJECTID ':' TYPEID ASSIGN expr { $$ = attr($1, $3, $5); }
                ;

    /* formals are comma-separated arguments, i.e. "formal parameters" */
    formals     : formal { $$ = single_Formals($1); }
                | formals ',' formal { $$ = append_Formals($1, single_Formals($3)); }
                /* empty argument list allowed */
                | { $$ = nil_Formals(); }
                ;
    formal      : OBJECTID ':' TYPEID { $$ = formal($1, $3); }
                ;
   
    /* expressions are the body of the program */
    expr        : OBJECTID ASSIGN expr { $$ = assign($1, $3); }

                /* dispatch: normal, static, omitted self */
                | expr '.' OBJECTID '(' param_expr ')' { $$ = dispatch($1, $3, $5); }
                | expr '@' TYPEID '.' OBJECTID '(' param_expr ')' { $$ = static_dispatch($1, $3, $5, $7); }
                | OBJECTID '(' param_expr ')' { $$ = dispatch(object(idtable.add_string("self")), $1, $3); }

                /* control structures */
                | IF expr THEN expr ELSE expr FI { $$ = cond($2, $4, $6); }
                | WHILE expr LOOP expr POOL { $$ = loop($2, $4); }

                /* block of expression(s) */
                | '{' one_or_more_expr '}' { $$ = block($2); }

                /* nested lets */
                | LET let_expr { $$ = $2; }

                /* Use `case_branch_list` nonterminal to handle one or more cases 
                 * See Cool Tour for more information on constructors
                 */
                | CASE expr OF case_branch_list ESAC { $$ = typcase($2, $4); }

                /* prefix keywords */
                | NEW TYPEID { $$ = new_($2); }
                | ISVOID expr { $$ = isvoid($2); }

                /* operators  */
                | expr '+' expr { $$ = plus($1, $3); }
                | expr '-' expr { $$ = sub($1, $3); }
                | expr '*' expr { $$ = mul($1, $3); }
                | expr '/' expr { $$ = divide($1, $3); }
                | '~' expr { $$ = neg($2); }
                | expr '<' expr { $$ = lt($1, $3); }
                | expr LE expr { $$ = leq($1, $3); }
                | expr '=' expr { $$ = eq($1, $3); }
                | NOT expr { $$ = comp($2); }
                
                /* parentheses */
                | '(' expr ')' { $$ = $2; }

                /* names */
                | OBJECTID { $$ = object($1); }

                /* literals - strings, numbers, booleans */
                | INT_CONST { $$ = int_const($1); }
                | STR_CONST { $$ = string_const($1); }
                | BOOL_CONST { $$ = bool_const($1); }
                ;

    let_expr    : OBJECTID ':' TYPEID IN expr { $$ = let($1, $3, no_expr(), $5); }
                | OBJECTID ':' TYPEID ASSIGN expr IN expr { $$ = let($1, $3, $5, $7); }
                | OBJECTID ':' TYPEID ',' let_expr { $$ = let($1, $3, no_expr(), $5); }
                | OBJECTID ':' TYPEID ASSIGN expr ',' let_expr { $$ = let($1, $3, $5, $7); }
                | error IN expr { yyclearin; $$ = NULL; }
                | error ',' let_expr { yyclearin; $$ = NULL; }
                ;
    
    /* one or more expressions, separated by a semicolon
     * this is not the same as comma-separated expressions (e.g. a list of arguments)
     */
    one_or_more_expr    : expr ';' { $$ = single_Expressions($1); }
                        | one_or_more_expr expr ';' { $$ = append_Expressions($1, single_Expressions($2)); }
                        /* recover from an expression inside a block */
                        | error ';' { yyclearin; $$ = NULL; }
                        ;

    param_expr          : expr { $$ = single_Expressions($1); }
                        | param_expr ',' expr { $$ = append_Expressions($1, single_Expressions($3)); }
                        /* include nil because params are optional */
                        | { $$ = nil_Expressions(); }
                        ;

    /* must have at least one case_branch */
    case_branch_list    : case_branch { $$ = single_Cases($1); }
                        /* "The function `append_Phylums` appends two lists of phylums */
                        | case_branch_list case_branch { $$ = append_Cases($1, single_Cases($2)); }
                        ;
    case_branch         : OBJECTID ':' TYPEID DARROW expr ';' { $$ = branch($1, $3, $5); }
                        ;

    /* end of grammar */
    %%
    
    /* This function is called automatically when Bison detects a parse error. */
    void yyerror(char *s)
    {
      extern int curr_lineno;
      
      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;
      
      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }
    
    