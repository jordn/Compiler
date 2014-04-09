/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");


/* DECLARATIONS
 * ======================================================================== */

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
extern int curr_lineno;
extern int verbose_flag;
extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int comment_depth;
int string_length = 0;

void addToStr(char* str);
%}

/* DEFINITIONS
 * ======================================================================== */


/*
 * Define names for regular expressions here.
 */

DARROW          =>
NUMBER          [0-9]
ALPHANUMERIC    [a-zA-Z0-9_]

%x COMMENT
%x STRING
%s BROKENSTRING

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
[ \t] 

"(*"            {   comment_depth++;
                    // printf("comment depth: %d\n", comment_depth);
                    BEGIN(COMMENT); 
                }
<COMMENT>"(*"   {   comment_depth++;
                    // printf("comment depth: %d\n", comment_depth);
                }
<COMMENT>\n     { curr_lineno++; }
<COMMENT>.      {}
<COMMENT>"*)"   {   comment_depth--;
                    // printf("comment shallowness: %d\n", comment_depth);
                    if (comment_depth == 0) {
                        BEGIN(INITIAL);
                    } 
                }
<INITIAL,STRING>"*)"   {
                    cool_yylval.error_msg = "Unmatched *)";
                    return(ERROR);
}

"--".*\n        { curr_lineno++; }  /* discard line */
"--".*          { curr_lineno++; }  /* discard line */

\"            { 
                    // "starting tag
                    BEGIN(STRING);
                    // printf("str: %s\n", string_buf);
                    // printf("strlen: %d\n", string_length);
                }
<STRING>\"    { 
                    // Closing tag"
                    // printf("endstr: %s\n", string_buf);
                    // printf("strlen: %d\n", string_length);
                    if (string_length > 1024) {
                      cool_yylval.error_msg = "String constant too long";
                      return(ERROR);
                    }
                    cool_yylval.symbol = stringtable.add_string(string_buf);
                    string_buf[0] = '\0';
                    string_length = 0;
                    BEGIN(INITIAL);
                    return(STR_CONST);
                }
<STRING>\\       {   
                    // escape char (ignore)
                }
<STRING>\0       {   
                      BEGIN(BROKENSTRING);
                }
<BROKENSTRING>.*[\"] {
                    // End of the broken string"
                    BEGIN(INITIAL);
                    cool_yylval.error_msg = "String contains null character";
                    return(ERROR);
                }
<STRING>\n      {   
                    // unescaped new line
                    BEGIN(INITIAL);
                    cool_yylval.error_msg = "Unescaped new line in string";
                    return(ERROR);
                }
<STRING>\\\n      {   
                    // escaped backspacsh
                    // printf("captured: %s\n", yytext);
                    curr_lineno++; 
                    addToStr("\n");
                    string_length++;
                    // printf("buffer: %s\n", string_buf);
                }
<STRING><<EOF>> {   
                    BEGIN(INITIAL);
                    cool_yylval.error_msg = "EOF in string constant";
                    return(ERROR);
                }


<STRING>.       {   
                    addToStr(yytext);
                    string_length++;
                    // printf("str: %s\n", string_buf);
                }


"/"             { return '/'; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"("             { return '('; }
")"             { return ')'; }
"="             { return '='; }
"<"             { return '<'; }
"."             { return '.'; }
"~"             { return '~'; }
","             { return ','; }
";"             { return ';'; }
":"             { return ':'; }
"@"             { return '@'; }
"{"             { return '{'; }
"}"             { return '}'; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)      { return(CLASS); }
(?i:else)       { return(ELSE); }
(?i:fi)         { return(FI); }
(?i:if)         { return(IF); }
(?i:in)         { return(IN); }
(?i:inherits)   { return(INHERITS); }
(?i:let)        { return(LET); }
(?i:loop)       { return(LOOP); }
(?i:pool)       { return(POOL); }
(?i:then)       { return(THEN); }
(?i:while)      { return(WHILE); }
(?i:case)       { return(CASE); }
(?i:esac)       { return(ESAC); }
(?i:of)         { return(OF); }
(?i:new)        { return(NEW); }
(?i:isvoid)     { return(ISVOID); }
(?i:not)        { return(NOT); }

t(?i:rue)   {
                cool_yylval.boolean = true;
                return(BOOL_CONST);
            }
f(?i:alse)  { 
                cool_yylval.boolean = false;
                return(BOOL_CONST);
            }
{NUMBER}+      {
                cool_yylval.symbol = inttable.add_string(yytext);
                return (INT_CONST);
            }

[A-Z]{ALPHANUMERIC}* {
                cool_yylval.symbol = idtable.add_string(yytext);
                return(TYPEID);
            }

[a-z]{ALPHANUMERIC}* {
                cool_yylval.symbol = idtable.add_string(yytext);
                return(OBJECTID);
            }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

"_"         { 
              cool_yylval.error_msg = yytext;
              return(ERROR);
            }

\n          { curr_lineno++; }

%%

/* USER SUBROUTINES
 * ======================================================================== */

void addToStr(char* str) {
    strcat(string_buf, str);
}

