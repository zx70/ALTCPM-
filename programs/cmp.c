/*  cmp.c -- UTOOL. Compare 2 files or file and std input
     for equality.  
     author: David H. Wolen
     last change: 11/23/82

     usage: cmp file1 file2
            prog |cmp file1

     input:    2 files or file and STDIN
     output:   STDOUT

     linkage: a:clink cmp -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"
#define STDIN 0

main(argc,argv)
int  argc;
char *argv[];
{
     char buf1[BUFSIZ], buf2[BUFSIZ], line1[MAXLINE],
          line2[MAXLINE];
     int  isstdin, lineno, m1, m2;

     dioinit(&argc,argv);

     switch(argc)
          { case 2:      /* stdin and 1 file */
               isstdin=TRUE;
               if(fopen(argv[1],buf2)==ERROR)
                    error("cmp: can't open file");
               break;
            case 3:      /* 2 files */
               isstdin=FALSE;
               if(fopen(argv[1],buf1)==ERROR)
                    error("cmp: can't open file 1");
               if(fopen(argv[2],buf2)==ERROR)
                    error("cmp: can't open file 2");
               break;
            default:
               error("usage: cmp file1 file2 or STDIN file");
          }

     lineno=0;

     while(1)
          {m1=(isstdin) ? fgets(line1,STDIN) : fgets(line1,buf1);
          m2=fgets(line2,buf2);
          if(!m1 || !m2)
               break;
          lineno++;
          if(!eqs(line1,line2))
               printf("%d\n%s%s",lineno,line1,line2);
          }

     if(!m1 && m2)
          out("cmp: eof on file 1");
     else if(!m2 && m1)
          out("cmp: eof on file 2");

     dioflush();
}
