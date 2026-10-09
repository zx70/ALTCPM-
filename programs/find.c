/* find.c -- UTOOL. Find patterns in text files (ver. 3) 

     author: David H. Wolen
     last change: 5/2/83

     usage:     find [-axn] pattern1 [pattern2 ... pattern10]

     options:  -a   output lines which contain all patterns
                    (default is output lines matching any pattern)
               -x   output lines that fail the match criteria
               -n   line numbers for output
               -c   just output count of matching lines
               -f   fold (ignore case in character comparisons)

     input:    STDIN
     output:   STDOUT

     notes:    1. -x pat1 pat2 : output if line contains neither pat
               2. -ax pat1 pat2 : output if line doesn't contain both pats
               3. metacharacters in pattern
                    %    match pattern at beginning of line
                    # #  enclose capital letters
                    " "  enclose embedded blanks
                    ?    match any char except newline
                    $    end of line
                    [c1-c2]  character class
                    [!c1-c2] negated character class
                    *    closure (0 or more occurrences of prev pattern)
                    escaped chars:  \n (newline)  \t (tab)  \r (cr)
                         \f (form feed)  \b (backspace)  \q (")  \p (#)
               4. first pattern can't begin with "-"
               5. up to MAXPATS patterns allowed (currently 10)
               6. if -c and -n, the latter will be ignored

     linkage:  a:clink find -f dio -ca (uses deff3.crl)

*/

#include "a:bdscio.h"
#include "dio.h"

#define  STDIN  0
#define  MAXPATS 10      /* max patterns */



main(argc,argv)
int  argc;
char *argv[];
{
     int  lineno, except, number, all, numpats, print,
          count, icount, fold;
     char line[MAXLINE], *s, newarg[MAXLINE], foldtemp[MAXLINE],
          pat[MAXPATS][MAXLINE];

     dioinit(&argc,argv);
     lineno=0;
     except=number=all=count=fold=FALSE;
     numpats=icount=0;

     /* process options */

     while(--argc > 0 && (*++argv)[0] == '-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'A':  all=TRUE;     break;
                     case 'N':  number=TRUE;  break;
                     case 'X':  except=TRUE;  break;
                     case 'C':  count=TRUE;   break;
                     case 'F':  fold=TRUE;    break;
                     default:   error("find: invalid option");
                    }

     /* process patterns */

     if(argc <= 0)  error("find: missing pattern");

     while(argc > 0)
          {if(++numpats > MAXPATS)  error("find: too many patterns");
          rcarg(newarg,*argv++);
          if(fold)
               {stoupper(foldtemp,newarg);
               strcpy(newarg,foldtemp);
               }
          if(!getpat(newarg,pat[numpats-1]))
               error("find: illegal pattern");
          argc--;
          }

     /* look for patterns in stdin */

     while(fgets(line,STDIN))
          {lineno++;
          if(fold)
               stoupper(foldtemp,line);
          else
               strcpy(foldtemp,line);
          if(gmatch(foldtemp,pat,numpats,all))
               print=TRUE;
          else
               print=FALSE;

          if(except)  print= !print;

          if(print && !count)
               {if(number)  printf("%d: ",lineno);
               printf("%s",line);
               }
          else if(print && count)
               icount++;
          }

     if(count)
          printf("%d matched\n",icount);

     dioflush();
}



/* gmatch -- match patterns  */
gmatch(line,pat,numpats,all)
char *line, pat[MAXPATS][MAXLINE];
int  numpats, all;
{
     int  gotone, i;

     for(i=0; i < numpats; i++)
          {gotone=match(line,pat[i]);
          if(!all && gotone)  return(TRUE);
          else if(all && !gotone)  return(FALSE);
          }

     return(all);
}



/*  match -- find match anywhere in line  */
match(lin,pat)
char *lin, *pat;
{
     int  i, pos;

     pos= -1;
     i=0;

     while(lin[i] != '\0' && pos < 0)
          {pos=amatch(lin,i,pat,0);
          i++;
          }

     return(pos >= 0);
}



/* stoupper -- convert string to upper case
     usage: stoupper(outstr,instr);
*/
stoupper(s,t)
char *s, *t;
{
     while(*s++ = toupper(*t++))
          ;
}

