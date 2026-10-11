#include <bdscio.h>

#define ASCII '\''
#define SNOT '?'
#define LPAREN '('
#define NEWLINE '\n'
#define FORMFEED '\f'
#define EOL '\0'
#define RPAREN ')'
#define COMMA ','
#define SEMICOLON ';'
#define NOT '~'
#define MINUS '-'
#define PLUS '+'
#define SPACE ' '
#define COLON ':'
#define TAB '\t'
#define MULT '*'
#define DIV '/'
#define MOD '%'
#define XOR '^'
#define OR '|'
#define AND '&'
#define SHL '<'
#define SHR '>'
#define TXAND "and"
#define TXXOR "xor"
#define TXSHL "shl"
#define TXSHR "shr"
#define TXMOD "mod"
#define TXNOT "not"
#define TXOR "or"
#define BINARY 'B'
#define OCTAL 'O'
#define OQTAL 'Q'
#define DECIMAL 'D'
#define HEX 'H'
#define DEFAULTBASE 10
#define NIL 0
#define MACDEF 10
#define REPTDEF 12
#define IRPDEF 14
#define IRPCDEF 16
#define EXIDEF 18
#define EMACDEF 20
#define IFDEF 40
#define ELSDEF 42
#define FIDEF 44
#define EQUDEF 60
#define SETDEF 62
#define ORGDEF 64
#define ENDDEF 66
#define DBDEF 80
#define DWDEF 82
#define DSDEF 84
#define TITDEF 100
#define PAGDEF 102
#define EJEDEF 104
#define LOFFDEF 106
#define LONDEF 108
#define NOMDEF 110
#define MDEF 112
#define PSIZDEF 114
#define PWIDEF 116
#define INCDEF 140
#define NOOP 0


struct symentry {
	char *symbol ;
	char stype ;
	union {
	   char *mpar ;
	   unsigned svalue ;
	   } u ;
	struct atom *mbody ;
	struct symentry *left ;
	struct symentry *right ;
	};

struct atom {
	struct atom *next ;
	char *body ;
	};

struct symentry *xroot, dum_symbol ;

unsigned xsvalue, xline ;

char xstype, *xw, w[35], clin[255], csymbol[20], cmnem[16], cop[200] ;
char bsymbol, bmnem, bop, xeof, ccomment[128], bcomment ;
char eval, lmacro, cond, tlcond, lcond, l_no_of_args, no_of_args ;
char class ;
char *argtab[100] ;
struct symentry *curmacro ;
struct atom *xexplin, *explin ;
struct atom *cmlin, *curmlin ;
struct symentry *mx_root ;

int xsymlin, xpass, xresult, bulle ;

struct symentry  *m_root, *lm_root ;

struct atom  *d_root, *e_root, dum_lista ;

int e_level ;

char expanding, lm_def, m_def, mcall, macrodef ;
