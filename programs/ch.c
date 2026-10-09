/*  ch.c -- UTOOL. Change pattern in text file.

     author: David H. Wolen
     last change: 3/4/83

     usage:  ch pattern [newstuff]

     input:  STDIN
     output: STDOUT

     notes:    1.  metacharacters in pattern (same as find)
                    %  begin of line
                    # #  enclose capital letters
                    " "  enclose imbedded blanks
                    ?  match any char except newline
                    $  end of line
                    [c1-c2]  char class
                    [!c1-c2] negated char class
                    *  closure (0 or more occurrences of prev 1 char pattern)
                    escaped chars:  \n (newline) \t (tab) \r (cr) 
                         \f (form feed) \b (backspace) \q (") \p (#)
               2.  If newstuff is omitted, deletion of pattern occurs.
               3.  Newstuff consists of zero or more of the following:
                    c  literal char
                    &  ditto, i.e. whatever was matched
                    \c  escaped char
                    # # and " " as above


     linkage:  a:clink ch -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  DITTO  127      /* rubout */

main(argc,argv)
int  argc;
char *argv[];
{
     char lin[MAXLINE], pat[MAXLINE], sub[MAXLINE], arg[MAXLINE];

     dioinit(&argc,argv);

     if(argc <= 1)
          error("ch: missing pattern");

     rcarg(arg,*++argv);

     if(!getpat(arg,pat))
          error("ch: illegal 'from' pattern");

     if(argc == 2)       /* null 'to' string */
          arg[0]='\0';
     else
          rcarg(arg,*++argv);

     if(!getsub(arg,sub))
          error("ch: illegal 'to' string");

     while(fgets(lin,STDIN))
          subline(lin,pat,sub);

     dioflush();
}



/*  subline -- substitute sub for pat in lin and print */
subline(lin,pat,sub)
char *lin, *pat, *sub;
{
     int  i, lastm, m;

     lastm= -1;
     i=0;

     while(lin[i] != '\0')
          {m=amatch(lin,i,pat,0);
          if(m >= 0 && lastm != m)      /* replace matched text */
               {putsub(lin,i,m,sub);
               lastm=m;
               }

          if(m < 0 || m == i)           /* no match or null match */
               {putchar(lin[i]);
               i++;
               }
          else                          /* skip matched text */
               i=m;
          }
}



/*  getsub -- get substitution string into sub  */
getsub(arg,sub)
char *arg, *sub;
{
     return(makesub(arg,0,'\0',sub) >= 0);
}



/* makesub -- make substitution string from arg in sub */
makesub(arg,from,delim,sub)
char *arg, delim, *sub;
{
     int  i, j;

     j=0;
     i=from;

     while(arg[i] != delim && arg[i] != '\0')
          {if(arg[i] == '&')
               addstr(DITTO,sub,&j,MAXLINE);
          else
               addstr(esc(arg,&i),sub,&j,MAXLINE);
          i++;
          }

     if(arg[i] != delim)      /* missing delimiter */
          return(-1);
     else if(!addstr('\0',sub,&j,MAXLINE))   /* no room */
          return(-1);
     else
          return(i);
}



/* putsub -- output substitution text */
putsub(lin,s1,s2,sub)
char *lin, *sub;
int  s1, s2;
{
     int  i, j;

     i=0;

     while(sub[i] != '\0')
          {if(sub[i] == DITTO)
               for(j=s1; j <= s2-1; j++)
                    putchar(lin[j]);
          else
               putchar(sub[i]);
          i++;
          }
}

