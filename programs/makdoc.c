/* makdoc.c -- UTOOL.  Make documentation from C source.

     author: David H. Wolen
     last change: 7/1/83

     usage: makdoc -p prog.c >prog.pdo  (programmer doc)
            makdoc prog.c >prog.hlp  (user help file)

     options: -p  output programmer oriented material in addition to 
                  user's manual page

     input:    file or STDIN
     output:   STDOUT

     notes: (1) -p prints program preface and function descriptions.
                Normal usage omits the linkage and compiler lines 
                from the preface and omits the function descriptions.
            (2) filename can't begin with -

     compiler: BDS C ver. 1.46 (with dio)
     linkage: clink b:makdoc -f dio  (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "a:dio.h"
#define STDIN 0
#define STDOUT 1

main(argc,argv)
int  argc;
char *argv[];
{
     int  isstdin, print, udoc;
     char line[MAXLINE], ibuf[BUFSIZ], *s;

     dioinit(&argc,argv);
     udoc=TRUE;

     while(--argc > 0 && (*++argv)[0]=='-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'P':  udoc=FALSE; break;
                    default:  error("makdoc: invalid option");
                    }

     if(argc <= 0)
          isstdin=TRUE;
     else
          {isstdin=FALSE;
          if(fopen(*argv,ibuf) == ERROR)
               error("makdoc: can't open file");
          }

     print=FALSE;

     if(udoc)       /* make user doc */
          {while(isstdin ? fgets(line,STDIN) : fgets(line,ibuf))
               {if(index(line,"/*")==0)  print=TRUE;
               if(print && index(line,"linkage:") < 0 
                    && index(line,"compiler:") < 0)
                    fputs(line,STDOUT);
               if(index(line,"*/") >= 0)  break;
               }
          }

     if(!udoc)      /* make programmer doc */
          {while(isstdin ? fgets(line,STDIN) : fgets(line,ibuf))
               {if(index(line,"/*")==0)  print=TRUE;
               if(print)
                    fputs(line,STDOUT);
               if(index(line,"*/") >= 0)  print=FALSE;
               }
          }

     dioflush();
}
