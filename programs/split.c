/* split.c -- UTOOL.  Read STDIN and write it out in n-line chunks to  files

     author: David H. Wolen
     last change:   3/31/83

     usage:    split [-n] [outname]

               split <infile
               split <infile -66 chunk

     options:  n       - number of  lines per file; default 100
               outname - filename for output files; default "temp"
                         (program assigns extentions .a ... .z).

     input:    STDIN
     output:   1 to 26 files

     notes:    (1)  output files are named outname.a ... outname.z if
                    outname is given as an argument.  Otherwise, they're
                    named temp.a ... temp.z (on the default drive).
               (2)  If the input is large, the 26th file may have n lines
                    written to it before end of input is reached.  In that
                    case, the rest of the input will also be
                    transferred to it.
               (3)  outname can't begin with "-"
               (4)  outname can contain a drive prefix; e.g. a:outname

     linkage:  a:clink split -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  DLINES 100      /* default lines per output file */
#define  DNAME  "temp"   /* default name for output files */

main(argc,argv)
int  argc;
char *argv[];
{
     int  nl, i;
     char fnamprfx[20], filename[20];

     dioinit(&argc,argv);

     /* process options */

     --argc; ++argv;

     if(argc == 0)      /* default nl and name */
          {nl=DLINES;
          strcpy(fnamprfx,DNAME);
          }
     else if(argc == 1 && *argv[0] == '-')   /* default name */
          {nl=atoi(*argv) *(-1);
          if(nl <= 0)
               error("split: bad lines per file argument");
          strcpy(fnamprfx,DNAME);
          }
     else if(argc == 1 && *argv[0] != '-')   /* default lines per  file */
          {nl=DLINES;
          strcpy(fnamprfx,*argv);
          }
     else if(argc == 2)       /* no defaults */
          {nl=atoi(*argv) *(-1);
          if(nl <= 0)
               error("split: bad lines per file argument");
          strcpy(fnamprfx,*++argv);
          }
     else
          error("usage: split [-n] [outname]");


     /* main logic */

     for(i=0; i < 26; i++)
          {makename(fnamprfx,i,filename);
          if( !spcopy(nl,filename,i))
               break;
          }

     dioflush();
}



/* makename -- make filename of the form fnamprfx.c where c= a ... z  */
makename(prefix,index,outname)
char *prefix, *outname;
int  index;
{
     char suffix[3], *letters;

     letters="abcdefghijklmnopqrstuvwxyz";  /* poor man's static */

     strcpy(outname,prefix);
     suffix[0]='.';
     suffix[1]=letters[index];
     suffix[2]='\0';
     strcat(outname,suffix);
}



/* spcopy -- copy nl lines from STDIN to outname */
spcopy(nl,outname,ifile)
int  nl, ifile;
char *outname;
{
     char line[MAXLINE], obuf[BUFSIZ];
     int  gotit, i;

     if(fcreat(outname,obuf) == ERROR)
          error("split: can't create output file");

     for(i=0; i < nl; i++)
          {if(!(gotit=fgets(line,STDIN)))
               break;
          fputs(line,obuf);
          }

     if(gotit && ifile >= 25)      /* put rest of input on last output file */
          while((gotit=fgets(line,STDIN)))
               fputs(line,obuf);

     fefc(obuf);
     return(gotit);
}
