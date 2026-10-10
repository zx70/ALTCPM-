/*  hcat.c -- UTOOL. Horizontally concatenate text files.

     author: David H. Wolen
     last change: 3/16/83

     usage:    hcat file1 n2 file2 n3 file3 ...

               hcat file1 31 file2 51 file3 
                    (begin file1 in col 1, file2 in col 31, file3 in col 51)

     input:    one or more files
     output:   STDOUT

     notes:    1. max of 6 input files
               2. first file starts in col 1

     linkage:  a:clink hcat -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  MAXHCFILS  6    /* max input files */

struct fs                /* file data */
     {char ibuf[BUFSIZ];
     char  line[MAXLINE];
     int   iseof;
     int   col;
     };

main(argc,argv)
int  argc;
char *argv[];
{
     int  i, nfiles;
     char outline[MAXLINE];
     struct fs fstuff[MAXHCFILS];

     dioinit(&argc,argv);
     if(argc/2 > MAXHCFILS)
          error("hcat: too many input files");

     /* process arguments */

     for(i=0; i < argc/2; i++)
          {if(i == 0)    /* start cols (1 for first file) */
               fstuff[i].col=1;
          else if((fstuff[i].col=atoi(*++argv)) <= 0)
               error("hcat: bad column argument");

          if(fopen(*++argv,fstuff[i].ibuf) == ERROR)   /* files */
               error("hcat: can't open file");

          fstuff[i].iseof = FALSE;
          }

     nfiles=i;

     /* process */

     while(hcmore(fstuff,nfiles))       /* until all files are at eof */
          {for(i=0; i < nfiles; i++)    /* get line from each file */
               {if(!fstuff[i].iseof)
                    if(!fgets(fstuff[i].line,fstuff[i].ibuf))
                         fstuff[i].iseof=TRUE;
               }

          setmem(outline,MAXLINE,' ');

          for(i=0; i < nfiles; i++)     /* form output line */
               {if(!fstuff[i].iseof)
                    dohc(fstuff[i].line,fstuff[i].col,outline,MAXLINE);
               }

          if(hcmore(fstuff,nfiles))
               {trail(outline,MAXLINE);       /* delete trailing blanks */
               puts(outline);
               }
          }

     dioflush();
}



/* hcmore -- return false if all input files at eof; else true */
hcmore(fstuff,nfiles)
struct fs fstuff[];
int  nfiles;
{
     int  i;

     for(i=0; i < nfiles; i++)
          {if(!fstuff[i].iseof)
               return(TRUE);
          }

     return(FALSE);
}



/* dohc -- insert line into outline starting at col.  Won't insert
     past end of outline.  */
dohc(line,col,outline,maxout)
char *line, *outline;
int  col, maxout;
{
     int  i, j;

     for(i=0, j=col-1; j < (maxout-1) && line[i] != '\n'; i++, j++)
          outline[j]=line[i];
}



/* trail -- delete trailing blanks from line */
trail(outline,maxout)
char *outline;
int  maxout;
{
     int  i, nfiles;

     for(i=maxout-3; i >= 0; i--)
          if(outline[i] != ' ')
               break;
     outline[++i]='\n';
     outline[++i]='\0';
}
