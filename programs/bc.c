/*
HEADER:		;
TITLE:		Binary Calculator;
VERSION:	1.0;

DESCRIPTION:	"Evaluates arithmetic and logic expressions entered
		at the console, and prints the result in decimal,
		hexadecimal, octal, binary, and ASCII notations.

		Compilation requires files BC.C, BCANLYZ.C, and BCDEF.H.
		BC.DOC contains instructions for compiling and using.";

KEYWORDS:	Arithmetic, logical, expression, evaluator, calculator;
SYSTEM:		CP/M-80;
FILENAME:	BC.C;
WARNINGS:	"BC is limited to integers, 0 to 65535.";
SEE-ALSO:	BCANLYZ.C, BCDEF.H, BC.DOC, BCREVIEW.DOC;
AUTHORS:	Jan Larsson;
COMPILERS:	BDS C;
*/
/************************************************************************/
main(){
char string[100];
unsigned res ;
char line[255] ;
puts(" + + +  bc  binary calculator  2.0  + + + \n");
puts("         (c) 1981  Occam Mjukisar \n");
puts("\n Want to have instructions (y/n) ?? ");
if(tolower(getchar()) == 'y')tellhim();
putchar('\n');putchar('\n');
for(;;){
printf("Enter expression : ");
gets( line );
lcase(line);
res = anlyz( line );
printf("Decimal: %6u           Hex: %04x\n",res,res);
printf("Octal  : %06o           ",res);
if((res & 0x007f) >= ' ')printf("Ascii:  %c\n",res & 0x007f);
else printf("\n");
printf("Binary : ");
binout( res, 0);
printf("\n\n");
}
}

lcase( s )
char *s ;
{
	while(*s != '\0'){
		if(*s == '\''){*s = *s ; s++ ; *s = *s ;s++;}
		*s = tolower(*s);
		s++ ;
		}
}


tellhim(){
puts("\n");
puts("\n");
puts(" This program acts as a general binary\n");
puts(" calculator with 16-bit precision. In\n");
puts(" the expression you may have any number\n");
puts(" of nested parentheses and numbers may\n");
puts(" be expressed in several ways.\n");
puts("\n");
puts(" Allowed number bases:\n");
puts("           b = binary\n");
puts("           o = octal\n");
puts("           q = octal\n");
puts("           d = decimal\n");
puts("           h = hexadecimal\n");
puts("         'a' = ascii value\n");
puts("     default = decimal\n\n");
puts("Legal operators:\n");
puts("           + = plus\n");
puts("           - = minus\n");
puts("           * = multiplication\n");
puts("           / = division\n");
puts("  'mod' or % = modulus\n");
puts("  'and' or & = bitwise and\n");
puts("  'xor' or ~ = bitwise xor\n");
puts("   'or' or | = bitwise or\n");
puts("  'shl' or < = shift left, zero fill\n");
puts("  'shr' or > = shift right, zero fill\n");
puts("\n");
puts("Unary operators:\n");
puts("           - = negation\n");
puts("  'not' or ~ = one's complement\n");
puts("  (note that two unary operators before\n");
puts("   one operand (like 'not -7') is illegal\n");
puts("   but will not draw any error message)\n");
puts("\n");
}


