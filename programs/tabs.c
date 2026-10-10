/* tabs.c -- UTOOL. Convert tabs to blanks (-d) or blanks
     to tabs and blanks (-e).

     author: David H. Wolen
     last change:   2/12/83

     usage:    tabs -d
               tabs -e 5 21 &5

     options:  -d   detab (convert tab chars to  blanks)
               -e   entab (convert blanks to tab chars and blanks)

     input:    STDIN
     output:   STDOUT

     notes:    (1) either -d or -e is required
               (2) default tab stops are at columns 8, 16, 24, ...
               (3) &n in the command line sets tabs every n columns.
                   E.G. "5 21 &5" sets tabs at columns 5, 21, 26, 31, ...
                   Anything after the &n will be ignored.

     linkage:  a:clink tabs -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  TABSPACE 8      /* default tabs every 8 columns */

int  tabflags[MAXLINE];  /* [0] isn't used */

main(argc,argv)
int  argc;
char *argv[];
{
     int  dodetab, doentab;
     char *s;

     dioinit(&argc,argv);
     dodetab=doentab=FALSE;

     /* process options */

     while(--argc > 0 && (*++argv)[0] == '-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'D':
                         dodetab=TRUE;
                         break;
                    case 'E':
                         doentab=TRUE;
                         break;
                    default:
                         error("tabs: invalid option. Use -d or -e");
                    }

     if( (!dodetab && !doentab) || (dodetab && doentab) )
          error("tabs: must give -d or -e");

     /* main */

     if(settabs(argc,argv) == ERROR)
          error("tabs: bad tab argument");

     if(dodetab)
          detab();
     else if(doentab)
          entab();

     dioflush();
}



/* settabs -- set initial tab stops from command line or default */
settabs(argc,argv)
int  argc;
char *argv[];
{
     int  i, lastab, itab, doincr;

     for(i=0; i < MAXLINE; i++)
          tabflags[i]=FALSE;

     if(argc <= 0)       /* default tab stops */
          {for(i=1; i < MAXLINE; i++)
               tabflags[i]=(i % TABSPACE == 0);
          return(OK);
          }

     lastab=0;           /* tabs from command line */
     doincr=FALSE;
     while(argc-- > 0)
          {if( *argv[0] == '&')
               {*argv[0]=' ';
               doincr=TRUE;
               }
          itab=atoi(*argv);

          if( itab <= 0)
               return(ERROR);

          itab=min(itab,MAXLINE-1);

          if(doincr)
               {for(i=lastab+1; i < MAXLINE; i++)
                    tabflags[i]=((i-lastab) % itab == 0);
               return(OK);
               }
          else
               {tabflags[itab]=TRUE;
               lastab=itab;
               argv++;
               }
          }

     return(OK);
}



/* detab -- convert tab chars to blanks */
detab()
{
     int  c, col;

     col=1;

     while( (c=getchar()) != EOF)
          {if(c == '\t')
               do
                    {putchar(' ');
                    col++;
                    }
                    while(!tabpos(col));
          else if(c == '\n')
               {putchar('\n');
               col=1;
               }
          else
               {putchar(c);
               col++;
               }
          }
}



/* tabpos -- return true if col is a tab stop, else false */
tabpos(col)
int  col;
{
     if(col >= MAXLINE)
          return(TRUE);
     else
          return(tabflags[col]);
}



/* entab -- convert blanks to tab chars and blanks */
entab()
{
     int  c, col, newcol;

     col=1;

     do
          {newcol=col;
          while( (c=getchar()) == ' ')  /* collect blanks */
               {newcol++;
               if(tabpos(newcol))
                    {putchar('\t');
                    col=newcol;
                    }
               }

          while(col < newcol)       /* output leftover blanks */
               {putchar(' ');
               col++;
               }

          if(c != EOF)
               {putchar(c);
               if(c == '\n')
                    col=1;
               else
                    col++;
               }

          } while(c != EOF);
}

