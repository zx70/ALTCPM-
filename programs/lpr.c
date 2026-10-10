/* lpr.c -- UTOOL. Send stdin to printer

     author: David H. Wolen
     last change: 12/1/82

     usage:    prog |lpr -lnp 5 55
               lpr <file

     options:  -l  left margin (default 8)
               -n  lines per page (default 50)
               -p  pause after each page. <cr> to
                   resume, anything else to quit.
                   (default false)


     input:    STDIN
     output:   printer

     notes:    (1)  form feed after each page and at eof
               (2)  if both -l and -n are used, margin
                    value must preceed page size value.


     linkage:  a:clink lpr -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  STDLST 2

main(argc,argv)
int  argc;
char *argv[];
{
     int  margflg, lmarg, psflg, psize, pause, lcount, i;
     char line[MAXLINE], *s;

     dioinit(&argc,argv);
     margflg=psflg=pause=FALSE;
     lmarg=8;
     psize=50;

     while(--argc > 0 && (*++argv)[0]=='-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'L':  margflg=TRUE; break;
                    case 'N':   psflg=TRUE;  break;
                    case 'P':   pause=TRUE;  break;
                    default:    error("lpr: invalid option");
                    }

     if(margflg)
          {if( (lmarg=atoi(*argv++)) < 0)
               error("lpr: left margin < 0");
          }

     if(psflg)
          {if( (psize=atoi(*argv)) < 1)
               error("lpr: page size < 1");
          }

     lcount=1;

     while(fgets(line,STDIN))
          {for(i=0; i<lmarg; i++)  fputs(" ",STDLST);
          fputs(line,STDLST);
          if(++lcount <= psize)  continue;
          else
               {fputs("\f",STDLST);
               lcount=1;
               if(pause)
                    {if(bdos(1)=='\r')  continue;
                    else
                         break;
                    }
               }
          }

     if(lcount > 1)  fputs("\f",STDLST);

     dioflush();
}
