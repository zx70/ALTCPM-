/*  wc.c -- UTOOL. Count lines, words and characters in 
     standard input.  Can handle Wordstar doc files. 

     author: David H. Wolen
     last change: 9/9/82

     usage: wc <infile

     input:   STDIN
     output:  STDOUT
  
     linkage: a:clink wc -f dio -ca
*/

#include "a:bdscio.h"
#define  STDOUT  1

main(argc,argv)
int  argc;
char *argv;
{
     int  c, inword;
     unsigned  nl, nw, nc;

     dioinit(&argc,argv);
     nl=nw=nc=0;
     inword=FALSE;

     while( (c=getchar()) != EOF)
          {c &= 0177;    /* WS doc hi bit */
          nc++;
          if(c=='\n')  nl++;
          if(c==' ' || c=='\n' || c=='\t')
               inword=FALSE;
          else if (!inword)
               {inword=TRUE;
               nw++;
               }
          }

     fprintf(STDOUT,"lines=%u words=%u chars=%u\n",nl,nw,nc);
     dioflush();
}

