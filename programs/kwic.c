/*  kwic.c -- UTOOL. Rotate lines to put keyword at front.
     First step in making keyword-in-context index.

     author: David H. Wolen
     last change: 12/1/82

     usage:    kwic <infile |sort -f |unrot

     input:    STDIN
     output:   STDOUT
     linkage:  a:clink kwic -f dio -ca
*/

#include "a:bdscio.h"
#include "dio.h"
#define  STDIN  0
#define  FOLD  '$'       /* indicates begin of folded line */

main(argc,argv)
int  argc;
char *argv[];
{
     char line[MAXLINE];

     dioinit(&argc,argv);

     while(fgets(line,STDIN))
          putrot(line);

     dioflush();
}



/* putrot -- create lines with keyword at front  */
putrot(line)
char *line;
{
     int  i;

     for(i=0; line[i] != '\n' && line[i] != '\0'; i++)
          if(isalpha(line[i]) || isdigit(line[i]))
               {rotate(line,i);         /* token starts at i */
               i++;
               while(isalpha(line[i]) || isdigit(line[i]))
                    i++;
               }
}



/* rotate -- output rotated line  */
rotate(line,n)
char *line;
int  n;
{
     int  i;

     for(i=n; line[i] != '\n'; i++)
          putchar(line[i]);

     putchar(FOLD);

     for(i=0; i<n; i++)
          putchar(line[i]);

     putchar('\n');
}
