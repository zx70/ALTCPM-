/* tr.c -- UTOOL. Transliterate characters

     author: David H. Wolen
     last change: 12/31/82

     usage:    tr src dest
               tr #A-Z# a-z   (change case)
               tr " \t\n" \n  (make one word per line)
               tr !\n         (delete everything but newlines)
               tr 0-9 9       (change digit strings to single digit 9)


     input:    STDIN
     output:   STDOUT

     notes:    (1) - denotes range
               (2) ! denotes "all but"
               (3) \n (newline) \t (tab) \b (backspace) \r (carr ret)
                   \f (form feed) \p (#) \q (")
               (4) if dest is absent, all chars represented by src are
                   deleted
               (5) if dest is shorter than src, all chars of src that 
                   would map to or beyond last char in dest are mapped
                   to last char in dest.  Adjacent instances of such 
                   chars in src cause a single instance of last char
                   in dest to be output.
               (6) use " " to enclose blanks in src and dest
               (7) use # # to enclose capital letters in src and dest


     linkage:  a:clink tr -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  NEGATE '!'
#define  ESCAPE '\\'

main(argc,argv)
int  argc;
char *argv[];
{
     int  c, i, lastto, allbut, squash;
     char arg[MAXLINE], fromset[MAXLINE], toset[MAXLINE];

     dioinit(&argc,argv);

     if(argc <= 1)  error("usage: tr from to");

     rcarg(arg,*++argv);

     allbut=(arg[0] == NEGATE);
     if(allbut)
          i=1;
     else
          i=0;

     if(!makset(arg,i,fromset,MAXLINE))
          error("tr: from set too large");

     if(argc == 2)       /* empty toset */
          toset[0]='\0';
     else
          {rcarg(arg,*++argv);
          if(!makset(arg,0,toset,MAXLINE))
               error("tr: to set too large");
          }

     if(strlen(fromset) < strlen(toset))
          error("tr: from shorter than to");

     lastto=strlen(toset)  -1;
     squash=(strlen(fromset) > lastto +1) || allbut;

     do
          {i=xindex(fromset,(c=getchar()),allbut,lastto);
          if(squash && i >= lastto && lastto >= 0)
               {putchar(toset[lastto]);
               do
                    i=xindex(fromset,(c=getchar()),allbut,lastto);
                    while(i >= lastto);
               }
          if(c != EOF)
               {if(i >= 0 && lastto >= 0)    /* translate */
                    putchar(toset[i]);
               else if(i < 0)                /* copy */
                    putchar(c);
               }                             /* else delete */
          }
          while(c != EOF);

     dioflush();
}



/* makset -- make set from inset[k] in outset. Returns FALSE for no room */
makset(inset,k,outset,maxset)
char *inset, *outset;
int  k, maxset;
{
     int  j, kk;

     j=0;
     kk=k;
     dodash('\0',inset,&kk,outset,&j,maxset);
     return(addstr('\0',outset,&j,maxset));
}



/* xindex -- conditionally invert value from cindex */
xindex(inset,c,allbut,lastto)
char *inset;
int  allbut, lastto, c;
{
     if(c == EOF)  return(-1);
     if(!allbut)  return(cindex(inset,c));

     if(cindex(inset,c) >= 0)  return(-1);
     else
          return(lastto+1);
}
