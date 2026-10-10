/* lline.c -- UTOOL.  find longest line

     author: David H. Wolen
     last change:  7/17/83

     usage:  lline  <infile >outfile

     input:  STDIN
     output: STDOUT

     compiler: BDS C ver. 1.46 (with dio)
     linkage:  clink b:lline -f a:dio -o b:  (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "a:dio.h"

#define  STDIN  0

main(argc,argv)
int  argc;
char *argv[];
{
     int  len, maxlen;
     char line[MAXLINE], savline[MAXLINE];

     dioinit(&argc,argv);
     maxlen=0;

     while(fgets(line,STDIN))
          {len=strlen(line) -1;     /* don't count \n */
          if(len > maxlen)
               {maxlen=len;
               strcpy(savline,line);
               }
          }

     if(maxlen == 0)  error("lline: empty input");

     printf("longest line is %d characters long:\n",maxlen);
     printf("%s",savline);

     dioflush();
}
