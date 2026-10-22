/* incl.c -- UTOOL. Expand included files

     author: David H. Wolen
     last change: 12/5/82

     usage:    incl <file

     input:    STDIN
     output:   STDOUT

     notes:    Replaces lines that begin with #include "file"
               with file contents.  The #include doesn't have
               to start in column 1.  Up to 8 open files at a
               time.

     linkage:  a:clink incl -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  STDOUT 1
#define  STDERR 4

main(argc,argv)
int  argc;
char *argv[];
{
     int  isstdin;
     char ibuf[BUFSIZ];

     dioinit(&argc,argv);

     if(argc==1)
          isstdin=TRUE;
     else
          {isstdin=FALSE;
          if(fopen(*++argv,ibuf)==ERROR)
               {fprintf(STDERR,"incl: can't open %s\n",*argv);
               exit(dioflush());
               }
          }

     finclude(ibuf,isstdin);
     dioflush();
}



/* finclude -- recursive file include */
finclude(ibuf,isstdin)
char *ibuf;
int  isstdin;
{
     char fbuf[BUFSIZ], line[MAXLINE], str[MAXLINE];
     int  loc, i;

     while( isstdin ? fgets(line,STDIN) : fgets(line,ibuf))
          {loc=getword(line,0,str);
          if(!eqs(str,"#include"))
               fputs(line,STDOUT);
          else
               {loc=getword(line,loc,str);
               str[strlen(str)-1]='\0';      /* remove quotes */
               for(i=0; i<strlen(str); i++)
                    str[i]=str[i+1];
               if(fopen(str,fbuf)==ERROR)
                    {fprintf(STDERR,"incl: can't open %s\n",str);
                    exit(dioflush());
                    }
               finclude(fbuf,FALSE);    /* recursion */
               fclose(fbuf);
               }
          }
}



/* getword -- get word from s[i] into out */
getword(s,i,out)
char *s, *out;
int  i;
{
     int  j;

     while(isspace(s[i]))
          i++;

     j=0;

     while(!isspace(s[i]) && s[i] != '\0')
          out[j++]=s[i++];

     out[j]='\0';

     if(s[i]=='\0')
          return (-1);
     else
          return (i);
}
