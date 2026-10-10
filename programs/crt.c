/*  crt.c -- UTOOL. Display text file (including ws doc)
     a screen at a time.
     author: David H. Wolen
     last change: 6/12/83

     usage: crt -n file
            prog |crt
               <cr> forward a screen
               anything else to quit
     option: -n  line numbers

     input:    file or STDIN
     output:   STDOUT

     linkage: a:clink crt -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "a:dio.h"
#define PSIZE 14         /* 22 lines per screen */
#define STDIN 0

main(argc,argv)
int  argc;
char *argv[];
{
     char ibuf[BUFSIZ], line[MAXLINE], *s;
     int  lnflag, lcount, lineno, i, isstdin, len;

     dioinit(&argc,argv);
     lnflag=FALSE;
     lineno=1;
     lcount=1;

     while(--argc>0 && (*++argv)[0]=='-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'N':          /* line numbers */
                         lnflag=TRUE;
                         break;
                    default:
                         error("usage: crt -n file or STDIN");
                    }

     switch(argc)
          {case 0:       /* STDIN */
               isstdin=TRUE;
               break;
          case 1:        /* file input */
               isstdin=FALSE;
               if(fopen(*argv,ibuf)==ERROR)
                    error("crt: can't open file");
               break;
          default:
               error("usage: crt -n file or STDIN");
          }

     while(isstdin ? fgets(line,STDIN) : fgets(line,ibuf))
          {len=strlen(line);
          for(i=0; i < len; i++)
               line[i]=undoc(line[i]);
          if(lnflag)
               printf("%4d: ",lineno++);
          puts(line);
          if(++lcount <= PSIZE)  continue;

          if(bdos(1)=='\r')        /* console input */
               {lcount=1;
               continue;
               }
          else
               break;
          }

     dioflush();
}

