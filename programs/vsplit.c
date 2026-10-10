/* vsplit.c -- UTOOL. Vertically split a text file.

     author: David H. Wolen
     last change: 2/20/83

     usage:    vsplit cc col

               vsplit ll 80   (output first 80 cols of each line)
               vsplit lr 10   (delete first 10 cols, output rest)
               vsplit rl 10   (delete last 10 cols, output rest)
               vsplit rr 15   (output last 15 cols)

     options:  ll   split from left, output left part
               lr   split from left, output right part
               rl   split from right, output left part
               rr   split from right, output right part

     input:    STDIN
     output:   STDOUT

     notes:    1. If input line contains only <cr><lf>, so will output
               2. If ll and col > line length, output will be whole line
               3. If lr and col > line length, output will be <cr><lf>
               4. If ll and col <= 0, output will be <cr><lf>
               5. If lr and col <= 0, output will be whole line
               6. If rl and col > line length, output will be <cr><lf>
               7. If rr and col > line length, output will be whole line
               8. If rl and col <= 0, output will be whole line
               9. If rr and col <= 0, output will be <cr><lf>

     linkage:  a:clink vsplit spltscan -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  STDOUT 1

main(argc,argv)
int  argc;
char *argv[];
{
     int  leftsplt, leftout, col;
     char line[MAXLINE], left[MAXLINE], right[MAXLINE];

     dioinit(&argc,argv);

     /* process options */

     if(argc < 3)
          error("usage: vsplit option col");

     if(eqs(argv[1],"LL"))
          leftsplt=leftout=TRUE;
     else if(eqs(argv[1],"LR"))
          {leftsplt=TRUE;
          leftout=FALSE;
          }
     else if(eqs(argv[1],"RL"))
          {leftsplt=FALSE;
          leftout=TRUE;
          }
     else if(eqs(argv[1],"RR"))
          leftsplt=leftout=FALSE;
     else
          error("vsplit: valid options are ll lr rl rr");

     col=atoi(argv[2]);

     /* main */

     while(fgets(line,STDIN))
          {line[strlen(line)-1]='\0';   /* zap newline */

          if(leftsplt)
               split(line,col,left,right);
          else
               splitr(line,col,left,right);

          if(leftout)
               fprintf(STDOUT,"%s\n",left);
          else
               fprintf(STDOUT,"%s\n",right);
          }

     dioflush();
}
