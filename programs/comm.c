/* comm.c -- UTOOL. Print lines common to two sorted files

     author: David H. Wolen
     last change: 11/29/82

     usage:    comm -123 file1 file2
               prog |comm file1

     options:  -n (n=1,2,3) print only named columns
                            (default is print all 3)

     input:    2 files or file and STDIN
     output:   STDOUT

     notes:    (1) if only one file is given, STDIN is file 2
               (2) col 1 is lines only in file 1
                   col 2 is lines only in file 2
                   col 3 is lines in both files

     linkage:  a:clink comm -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  STDOUT 1

main(argc,argv)
int  argc;
char *argv[];
{
     int  isstdin, c1flg, c2flg, c3flg, stat1, stat2, k;
     char *s, buf1[BUFSIZ], buf2[BUFSIZ], line1[MAXLINE],
          line2[MAXLINE];


     dioinit(&argc,argv);
     c1flg=c2flg=c3flg=FALSE;

     /* process options */

     while(--argc > 0 && (*++argv)[0] == '-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case '1': c1flg=TRUE; break;
                    case  '2': c2flg=TRUE; break;
                    case  '3': c3flg=TRUE; break;
                    default:   error("comm: invalid option");
                    }

     if(!c1flg && !c2flg && !c3flg)
          c1flg=c2flg=c3flg=TRUE;

     /* open file or files */

     switch(argc)
          {case 1:       /* 1 file and STDIN */
               isstdin=TRUE;
               if(fopen(*argv,buf1)==ERROR)
                    error("comm: can't open file");
               break;
          case 2:        /* 2 files */
               isstdin=FALSE;
               if(fopen(*argv++,buf1)==ERROR)
                    error("comm: can't open file 1");
               if(fopen(*argv,buf2)==ERROR)
                    error("comm: can't open file 2");
               break;
          default:
               error("usage: comm [-123] file1 file2 or file STDIN");
          }

     /* process */

     stat1=fgets(line1,buf1);
     stat2=(isstdin) ? fgets(line2,STDIN) : fgets(line2,buf2);

     while(1)
          {if(!stat1 || !stat2)  break;
          k=strcmp(line1,line2);
          if(k < 0)      /* line only in file 1 */
               {if(c1flg)  prntcol(line1,1,c1flg,c2flg,c3flg);
               stat1=fgets(line1,buf1);
               }
          else if(k > 0) /* line only in file 2 */
               {if(c2flg)  prntcol(line2,2,c1flg,c2flg,c3flg);
               stat2=(isstdin) ? fgets(line2,STDIN) : fgets(line2,buf2);
               }
          else           /* line in both files */
               {if(c3flg)  prntcol(line1,3,c1flg,c2flg,c3flg);
               stat1=fgets(line1,buf1);
               stat2=(isstdin) ? fgets(line2,STDIN) : fgets(line2,buf2);
               }
          }

     if(!stat1 && c2flg) /* end of file 1, print rest of file 2 */
          while(stat2)
               {prntcol(line2,2,c1flg,c2flg,c3flg);
               stat2=(isstdin) ? fgets(line2,STDIN) : fgets(line2,buf2);
               }
     else if(!stat2 && c1flg) /* end of file 2, print rest of file 1 */
          while(stat1)
               {prntcol(line1,1,c1flg,c2flg,c3flg);
               stat1=fgets(line1,buf1);
               }

     dioflush();
}



/* prntcol -- print line as column col */
prntcol(line,col,c1flg,c2flg,c3flg)
char *line;
int  col, c1flg, c2flg, c3flg;
{
     int  i;

     for(i=0; isspace(line[i]); i++) ;    /* skip leading white space */

     switch(col)
          {case 1:
               fputs(&line[i],STDOUT);
               break;
          case 2:
               if(c1flg)    /* 15 blanks */
                    fputs("               ",STDOUT);
               fputs(&line[i],STDOUT);
               break;
          case 3:
               if(c1flg)    /* 10 blanks */
                    fputs("          ",STDOUT);
               if(c2flg)    /* 15 blanks */
                    fputs("               ",STDOUT);
               fputs(&line[i],STDOUT);
               break;
          default:
               error("prntcol: can't happen");
          }
}

