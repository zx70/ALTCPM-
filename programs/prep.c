/*  prep.c -- UTOOL. Convert a text file (including ws doc files)
     to one word per line.
     author: David H. Wolen
     last change: 3/9/83

     usage:   prep <letter.doc -i dict.dat
     options: -o list.dat   only do words on file
              -i list.dat   ignore words on file
              -d            preface output words with input sequence numbers

     input:    STDIN
     output:   STDOUT

     notes:  (a) files for -o and -i must be prepared by prep
                 and sort (-f and -u)
             (b) can't use both -o and -i
             (c) output is lower case
             (d) max file size for -o or -i is 1000 lines or
                 about 30K.

     linkage: a:clink prep -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"
#define  STDOUT 1
#define  STDERR 4
#define  LINES  1000          /* size of list for -o and -i */

char *listp[LINES];           /* pointers to list items */
int  nlist;                   /* number of list items */

main(argc,argv)
int  argc;
char *argv[];
{
     int  only, ignore, sequence, wcount;
     char *s, word[MAXLINE];

     dioinit(&argc,argv);
     only=ignore=sequence=FALSE;
     wcount=0;

     while(--argc > 0 && (*++argv)[0]=='-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'O':
                         only=TRUE;
                         break;
                    case 'I':
                         ignore=TRUE;
                         break;
                    case 'D':
                         sequence=TRUE;
                         break;
                    default:
                         error("prep: invalid option");
                    }

     if(only && ignore)
          error("prep: can't use both -o and -i");

     if(only || ignore)
          readlist(*argv);

     while(getword(word))
          {wcount++;
          if(ignore)
               {if(!pmatch(word) && sequence)
                    fprintf(STDOUT,"%d: %s\n",wcount,word);
               if(!pmatch(word) && !sequence)
                    fprintf(STDOUT,"%s\n",word);
               }
          else if(only)
               {if(pmatch(word) && sequence)
                    fprintf(STDOUT,"%d: %s\n",wcount,word);
               if(pmatch(word) && !sequence)
                    fprintf(STDOUT,"%s\n",word);
               }
          else
               {if(sequence)
                    fprintf(STDOUT,"%d: %s\n",wcount,word);
               else
                    fprintf(STDOUT,"%s\n",word);
               }
          }

     dioflush();
}



/*  readlist -- read and store exclusion or inclusion
          list.  Check to be sure list is sorted and unique.
*/
readlist(filename)
char *filename;
{
     int  len, i;
     char ibuf[BUFSIZ], line[MAXLINE], *sbrk(), *p;

     if(fopen(filename,ibuf)==ERROR)
          error("prep: can't open list file");

     nlist=0;

     while(fgets(line,ibuf))
          {if(nlist > LINES)  error("prep: too many lines in list file");
          line[strlen(line)-1]='\0';   /* zap '\n' */
          len=strlen(line) +1;
          if((p=sbrk(len))==ERROR)  error("prep: too many chars on list file");
          strcpy(p,line);
          listp[nlist++]=p;
          }

     if(nlist < 1)  error("prep: empty list file");

     for(i=1; i<nlist; i++)
          if(pstrcmp(listp[i-1],listp[i]) >=0)
               error("prep: list isn't sorted or has duplicates");
}



/* pstrcmp -- compare strings.  Return <0 if s<t; 0 if
          s==t; >0 if s>t.  For equality, strings must be
          equal in length.  Fold lower into upper case
          before comparison.
*/
pstrcmp(s,t)
char *s, *t;
{
     for(; *s != '\0'; s++, t++)
          if(toupper(*s) != toupper(*t))
               return(toupper(*s)-toupper(*t));

     if(*t == '\0')  return(0);
     else
          return(-1);
}



/*  getword -- get the next word from the standard input.
          Return TRUE for got a word, FALSE for EOF.
*/
getword(word)
char *word;
{
     int  i, c;

     i=0;

     while(1)  /* find start of word */
          {if((c=getchar())==EOF)  return(FALSE);
          c &= 0177;          /* Wordstar hi bit */
          if(isalpha(c))  break;
          }

     word[i++]=tolower(c);

     while(1)
          {if((c=getchar())==EOF) /* push back EOF for next call */
               {ungetch(c);
               break;
               }
          c &= 0177;
          if(!isalpha(c) && c!='\'')  break;      /* allow ' within a word */
          else
               word[i++]=tolower(c);
          }

     if(word[i-1]=='\'')
          word[i-1]='\0';
     else
          word[i]='\0';

     return(TRUE);
}



/*  pmatch -- return TRUE if word is in list, else FALSE.
          Ignore case in the comparison.
*/
pmatch(word)
char *word;
{
     int  low, mid, high;

     low=0;
     high=nlist-1;

     while(low <= high)  /* binary search */
          {mid=(low+high)/2;
          if(pstrcmp(word,listp[mid]) < 0)
               high=mid-1;
          else if (pstrcmp(word,listp[mid]) >0)
               low=mid+1;
          else           /* found match */
               return(TRUE);
          }

     return(FALSE);
}
