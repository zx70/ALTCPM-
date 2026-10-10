/* tee.c -- UTOOL.  Copy STDIN to STDOUT and named file.

     author: David H. Wolen
     last change: 1/16/83

     usage:  tee [-a] outfile

     options:  -a   append to outfile instead of copying to it

     input:  STDIN
     output: STDOUT and file

     notes:    (a)  if -a and outfile doesn't exist, the
                    option is ignored.
               (b)  if -a, it creates and releases a temp
                    file (temptee.$$$) on the logged drive.

     linkage:  a:clink tee -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  STDOUT 1

main(argc,argv)
int  argc;
char *argv[];
{
     int  append;
     char *s, ibuf[BUFSIZ], obuf[BUFSIZ];

     dioinit(&argc,argv);
     append=FALSE;

     /* process options */

     while(--argc > 0 && (*++argv)[0] == '-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'A':
                         append=TRUE;
                         break;
                    default:
                         error("usage: tee [-a] outfile");
                    }

     if(!append)
          {if(fcreat(*argv,obuf) == ERROR)
               error("tee: can't create output file");
          if(tfcopy(STDIN,obuf,TRUE) == ERROR)
               error("tee: file output error");
          fefc(obuf);
          }
     else
          {if(fcreat("temptee.$$$",obuf) == ERROR)
               error("tee: can't create temp file");
          if(fopen(*argv,ibuf) != ERROR)
               if(tfcopy(ibuf,obuf,FALSE) == ERROR)
                    terror("tee: file output error copying prior to append");
          if(tfcopy(STDIN,obuf,TRUE) == ERROR)
               terror("tee: file output error during append");
          fefc(obuf);
          unlink(*argv);
          if(rename("temptee.$$$",*argv) == ERROR)
               error("tee: output is on temptee.$$$ ; can't rename");
          }

     dioflush();
}




/* tfcopy -- copy file fin to fout, line by line.  Returns OK or
     ERROR.  If echo, output goes to both fout and STDOUT.
*/
tfcopy(fin,fout,echo)
char *fin, *fout;
int  echo;
{
     int  c;
     char line[MAXLINE];

     while(fgets(line,fin))
          {if(fputs(line,fout) == ERROR)
               return(ERROR);
          if(echo)
               fputs(line,STDOUT);
          }

     return(OK);
}



/* terror -- release temp file, then normal error */
terror(msg)
char *msg;
{
     unlink("temptee.$$$");
     error(msg);
}
