/*  unrot.c -- UTOOL. Unrotate lines rotated by kwic.  Last step
     in making keyword-in-context index.

     author: David H. Wolen
     last change: 12/2/82

     usage: kwic <infile |sort -f |unrot >outfile

     input:   STDIN
     output:  STDOUT
  
     linkage: a:clink unrot -f dio -ca
*/

#include "a:bdscio.h"
#include "dio.h"
#define  STDIN  0
#define  STDOUT 1
#define  FOLD  '$'       /* indicates begin of folded line */
#define  MAXOUT  92      /* width of output lines */

main(argc,argv)
int  argc;
char *argv[];
{
     char inline[MAXLINE], outline[MAXOUT];
     int  i, j, middle;

     dioinit(&argc,argv);

     middle = max(MAXOUT/2,0) -1;

     while(fgets(inline,STDIN))
          {for(i=0; i<MAXOUT; outline[i++]=' ');
          j=middle;           /* copy up to FOLD */
          for(i=0; inline[i] != FOLD && inline[i] != '\n'; i++, j++)
               {if(i > 0 && inline[i-1] == ' ')
                    if(nextj(1,inline,i,j) >= MAXOUT-3)
                         j=0;
               if(j >= MAXOUT -3)
                    j=0;
               outline[j]=inline[i];
               }

          if(inline[i] == FOLD)         /* copy 2nd half working backwards */
               {j=middle-1;
               for(i=strlen(inline)-2; i >= 0; i--)
                    {
                    if(inline[i] == FOLD)
                         break;
                    j--;
                    if(inline[i+1] == ' ')
                         if(nextj(-1,inline,i,j) < 0)
                              j=MAXOUT-3;
                    if(j < 0)
                         j=MAXOUT-3;
                    outline[j]=inline[i];
                    }
               }

          for(i=MAXOUT-3; i >= 0; i--)
               if(outline[i] != ' ')    /* delete trail blanks and terminate line */
                    break;

          outline[++i]='\n';
          outline[++i]='\0';
          fputs(outline,STDOUT);
          }

     dioflush();
}




/* nextj -- see if enough space for another word */
nextj(incr,lbuf,i,j)
char *lbuf;
int  incr, i, j;
{
     int  k;

     for(k=i; k >= 0; k += incr)
          {if(lbuf[k] == ' ' || lbuf[k] == FOLD || lbuf[k] == '\n')
               break;
          j += incr;
          }

     return(j);
}
