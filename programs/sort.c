/*  sort.c -- UTOOL. (ver. 2) Incore sort of ascii lines.
     Max file size 2000 lines or about 30K.

     author: David H. Wolen
     last change: 5/5/83

     usage: sort <infile >outfile
            sort <infile -kf 1-5 8-12 6-7

     options:  -f fold lower into upper case before comparison
               -k key fields (n1-n2)  10 max
                    if no key fields and no numeric, whole line is used
               -r reverse
               -n numeric (first item on line must be int)
                    neither -f nor -k can be used with -n
               -u unique (according to current sort def of equal)

          input:    STDIN
          output:   STDOUT

          linkage:  a:clink sort -f dio -ca (uses deff3.crl)
*/

#include "a:bdscio.h"
#include "dio.h"

#define LINES 2000                      /* max input lines */
#define MAXKEYS 10                      /* max sort keys */
#define STDIN 0
#define STDERR 4
#define STDOUT 1

int  keys[2][MAXKEYS];                   /* starts & ends of key flds */
char *lineptr[LINES];                    /* ptrs to text lines */

main(argc,argv)
int  argc;
char *argv[];
{
     int  nlines;                       /* numb of input lines */
     int  i, test, foldflag, keyflag,   /* misc  */
          revflag, numflag, uniqflag;
     char *s;

     /* init */

     dioinit(&argc,argv);
     foldflag=keyflag=revflag=numflag=uniqflag=FALSE;

     /* process options, if any */

     while(--argc > 0 && (*++argv)[0]=='-')
          for(s=argv[0]+1; *s != '\0'; s++)
               switch(*s)
                    {case 'F':  foldflag=TRUE; break;
                    case  'K':  keyflag=TRUE; break;
                    case  'R':  revflag=TRUE; break;
                    case  'N':  numflag=TRUE; break;
                    case  'U':  uniqflag=TRUE; break;
                    default:
                         fprintf(STDERR,
                              "sort: invalid option %c\n",*s);
                         exit(dioflush());
                    }

     if(numflag&&keyflag)
          {fprintf(STDERR,"sort: -n and -k don't go together\n");
          exit(dioflush());
          }
     if(numflag&&foldflag)
          {fprintf(STDERR,"sort: -n and -f don't go together\n");
          exit(dioflush());
          }


     /* process key fields, if any */

     if(keyflag)
          {if(argc<=0)
               {fprintf(STDERR,"sort: missing keys\n");
               exit(dioflush());
               }
          if(argc>MAXKEYS)
               {fprintf(STDERR,"sort: more than %d keys\n",MAXKEYS);
               exit(dioflush());
               }

          for(i=0; i<MAXKEYS; i++)  keys[0][i]=-1;

          for(i=0; i<argc; i++)
               if( (test=dokey(*argv++,i)) <0)
                    {fprintf(STDERR,"sort: error in dokey %d\n",test);
                    exit(dioflush());
                    }
          }


     /* read input */

     if( (nlines=filein()) <0)
          {fprintf(STDERR,
               "sort: too much input. Lines(-1) or char(-2): %d\n",nlines);
          exit(dioflush());
          }

     if(nlines==0)
          {fprintf(STDERR,"sort: empty input file\n");
          exit(dioflush());
          }

     fprintf(STDERR,"sort: %d input lines\n",nlines);


     /* sort */

     xsort(lineptr,nlines,foldflag,keyflag,revflag,numflag);


     /* write output */

     output(nlines,uniqflag,foldflag,keyflag,revflag,numflag);

     dioflush();
}


/*  dokey -- process and store  a sort key */
dokey(inkey,nkey)
char  inkey[];
int   nkey;
{
     int  k1,k2;

     if(argrange(inkey,&k1,&k2)==ERROR)  return(-4);

     keys[0][nkey]= --k1;
     keys[1][nkey]= --k2;

     if((k1<0)||(k2<0)||(k1>MAXLINE-1)||(k2>MAXLINE-1))  return(-5);
     else
          return(0);
}



/*  filein -- read input, store lines, store pointers to lines */
filein()
{
     int  len, nlines;
     char *p, *sbrk(), line[MAXLINE];

     nlines=0;

     while(fgets(line,STDIN))
          {if(nlines>LINES)  return(-1);

          line[strlen(line)-1]='\0';    /* zap '\n' */
          len=strlen(line) + 1;   /* account for null byte  */
          if((p=sbrk(len))==ERROR)  return(-2);

          strcpy(p,line);
          lineptr[nlines++]=p;
          }

     return(nlines);
}



/* xsort -- shell sort pointers to text lines  */
xsort(v,n,fold,keys,reverse,numeric)
char  *v[];
int   n, fold, keys, reverse, numeric;
{
     int  gap, i, j;

     for(gap=n/2;gap>0;gap/=2)
          for(i=gap;i<n;i++)
               for(j=i-gap;j>=0;j-=gap)
                    {if(scmp(v[j],v[j+gap],fold,keys,reverse,numeric) <= 0)
                         break;
                    swap(&v[j],&v[j+gap]);
                    }
}




/*  scmp -- string compare. Return <0 if s<t, 0 if s=t, >0 if s>t
     (lie if reverse)
*/
scmp(s,t,fold,keys,reverse,numeric)
char *s, *t;
int  fold, keys, reverse, numeric;
{
     int  result;

     if(numeric)         /* leading integers */
          result=atoi(s) -atoi(t);
     else if(keys)       /* fields */
          result=strcmpaf(s,t,fold);
     else                /* whole line */
          result=xstrcmp(s,t,fold);

     if(reverse)         /* lie for descending sort */
          result *= -1;

     return(result);
}



/*  swap -- exchange pointers.  K&R p. 117  */
swap(px,py)
char  *px[], *py[];
{
     char  *temp;

     temp=*px;
     *px=*py;
     *py=temp;
}



/*  xstrcmp -- return <0 if s<t, 0 if s==t, >0 if s>t.
          If fold, fold lower into upper case before compare.
*/
xstrcmp(s,t,fold)
char *s, *t;
int  fold;
{
     char s1, t1;

     for(; *s != '\0'; s++, t++)
          {s1= (fold) ? toupper(*s) : *s;
           t1= (fold) ? toupper(*t) : *t;

          if(s1 != t1)  return(s1-t1);
          }

     if(*t=='\0')
          return(0);
     else
          return(-1);
}



/*  strcmpaf -- compare using fields.  Return <0 for
          s<t, 0 for s==t, >0 for s>t.  If fold, fold
          lower into upper case before comparison.
*/
strcmpaf(s,t,fold)
char *s, *t;
int  fold;
{
     int  i,j;
     char s1, t1;

     for(i=0; keys[0][i]>=0; i++)
          for(j=keys[0][i]; j<=keys[1][i]; j++)
               {s1 = (fold) ? toupper(s[j]) : s[j];
               t1  = (fold) ? toupper(t[j]) : t[j];
               if(s1 != t1)  return (s1-t1);
               }

     return(0);
}



/*  output -- write output. Delete non-unique lines (current sort def
     of equality) if requested
*/
output(nlines,unique,fold,keys,reverse,numeric)
int  nlines, unique, fold, keys, reverse, numeric;
{
     int  i;

     if(unique)          /* delete non-unique lines */
          {fprintf(STDOUT,"%s\n",lineptr[0]);
          for(i=1; i < nlines; i++)
               if(scmp(lineptr[i],lineptr[i-1],fold,keys,reverse,numeric) != 0)
                    fprintf(STDOUT,"%s\n",lineptr[i]);
          }
     else                /* output all lines */
          for(i=0; i < nlines; i++)
               fprintf(STDOUT,"%s\n",lineptr[i]);
}
