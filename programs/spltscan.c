/*   split, splitr, scan, scanr, scann, scannr --  character handling
          functions similar to HIS TEX
*/

/*   split - splits instring. Puts leftmost col characters
          in starl and the rest in starr.  instring
          must be terminated by '\0' .  starl and
          starr will be terminated by '\0 .  Strange
          cases are handled as in TEX.
*/

#include "a:bdscio.h"
#define CLASC '_'
#define STDERR 4


split(instring,col,starl,starr)   /* split from left  */
char instring[], starl[], starr[];
int  col;
{
     int  i,j;

     /*  special cases  */

     if(instring[0]=='\0')
          {starl[0]=starr[0]='\0';
          return;
          }
     if(col<=0)
          {starl[0]='\0';
          strcpy(starr,instring);
          return;
          }
     if(col>strlen(instring))
          {strcpy(starl,instring);
          starr[0]='\0';
          return;
          }

     /*  normal case  */

     for(i=0;i<col;i++)
          starl[i]=instring[i];
     starl[i]='\0';

     for(j=0;;j++)
          {starr[j]=instring[i++];
          if(starr[j]=='\0') break;
          }
}

/*  splitr - splits instring from the right.  Puts
          rightmost col characters in starr and the
          rest in starl.  instring must be terminated
          by '\0'.  starr and starl will be terminated
          by '\0'.  Strange cases handled as in TEX.
*/

splitr(instring,col,starl,starr)  /* split from right */
char  instring[], starl[], starr[];
int  col;
{
     int  xcol;

     /* convert to equivalent split */

     xcol=strlen(instring) - col ;
     split(instring,xcol,starl,starr);

}


/* scan - scans instring from left for pat.  pat can
          contain characters or class (prefixed by _).
          instring must be terminated by '\0'.
          Returns TRUE or FALSE.
*/


scan(instring,pat,starl,starm,starr)  /* scan from left  */
char  instring[], pat[], starl[], starm[], starr[];
{
     char  starlx[MAXLINE], starrx[MAXLINE];
     int   col, i, alp, num, low, up;

     /*  special cases  */

     if(instring[0]=='\0')
          {starl[0]=starm[0]=starr[0]='\0';
          return(FALSE);
          }
     if(pat[0]=='\0')
          {strcpy(starl,instring);
          starm[0]=starr[0]='\0';
          return(FALSE);
          }

     /*  normal case without class  */

     if(pat[0]==CLASC)  goto class;

     if((col=index(instring,pat))<0)
          {strcpy(starl,instring);
          starm[0]=starr[0]='\0';
          return(FALSE);
          }
     else
          {strcpy(starm,pat);
          split(instring,col,starlx,starrx);
          strcpy(starl,starlx);
          split(instring,(col+strlen(pat)),starlx,starrx);
          strcpy(starr,starrx);
          return(TRUE);
          }

     /*  normal case with class  */

     class: if(getclass(pat,&alp,&num,&low,&up)==ERROR)
          {fprintf(STDERR,"\nbad class in scan %s",pat);
          fprintf(STDERR," treated as null\n");
          strcpy(starl,instring);
          starm[0]=starr[0]='\0';
          return(FALSE);
          }

     for(i=0;instring[i]!='\0';i++)
          {if(alp && isalpha(instring[i]))  break;
          if(num && isdigit(instring[i]))  break;
          if(low && islower(instring[i]))  break;
          if(up && isupper(instring[i]))  break;
          }

     if(instring[i]=='\0')
          {strcpy(starl,instring);
          starm[0]=starr[0]='\0';
          return(FALSE);
          }
     else
          {split(instring,i,starlx,starrx);
          strcpy(starl,starlx);
          strcpy(starr,starrx);
          starm[0]='\0';
          return(TRUE);
          }

}


/* getclass -- figure out class for scan operators  */

getclass(pat,alp,num,low,up)
char  pat[];
int   *alp, *num, *low, *up;
{
     *alp=*num=*up=*low=FALSE;

     if((     pat[1]=='a')&&(pat[2]=='\0'))  *alp=TRUE;
     else if((pat[1]=='n')&&(pat[2]=='\0'))  *num=TRUE;
     else if((pat[1]=='l')&&(pat[2]=='c'))   *low=TRUE;
     else if((pat[1]=='u')&&(pat[2]=='c'))   *up=TRUE;
     else if((pat[1]=='a')&&(pat[2]=='n'))   *alp=*num=TRUE;
     else return(ERROR);

     return(OK);
}


/*  scann - scans instring from left for non-match
     on pat.  pat can contain one character or
     a class.  instring must be terminated by '\0'.
     Returns TRUE or FALSE. (As in TEX, the true
     and false results are not intuitively obvious.
*/

scann(instring,pat,starl,starm,starr) /* scan from left for non-match  */
char  instring[], pat[], starl[], starm[], starr[];
{
     int  i, alp, num, low, up;

     /*  special cases  */

     if(pat[0]=='\0')
          {fprintf(STDERR,"\nerror in scann null pat\n");
          starm[0]=starr[0]=starl[0]='\0';
          return(FALSE);
          }

     if(instring[0]=='\0')
          {starl[0]=starm[0]=starr[0]='\0';
          return(FALSE);
          }


     /*  normal case without class  */

     if(pat[0]==CLASC)  goto class;

     if(pat[1]!='\0')
          {fprintf(STDERR,"\npat>1 char in scann %s",pat);
          fprintf(STDERR," used first\n");
          }

     for(i=0;instring[i]!='\0';i++)
          if(pat[0]!=instring[i])  break;

     if(instring[i]=='\0')
          {strcpy(starl,instring);
          starr[0]=starm[0]='\0';
          return(TRUE);
          }
     else
          {split(instring,i,starl,starr);
          starm[0]='\0';
          if(starr[0]=='\0')  return(TRUE);
          else
               return(FALSE);
          }


     /*  normal case with class  */

     class:  if(getclass(pat,&alp,&num,&low,&up)==ERROR)
          {fprintf(STDERR,"\nbad class in scann is %s",pat);
          fprintf(STDERR," treated as null\n");
          strcpy(starl,instring);
          starm[0]=starr[0]='\0';
          return(FALSE);
          }

     for(i=0;instring[i]!='\0';i++)
          {if(alp && !isalpha(instring[i]))  break;
          if (num && !isdigit(instring[i]))  break;
          if (low && !islower(instring[i]))  break;
          if (up  && !isupper(instring[i]))  break;
          }

     if(instring[i]=='\0')
          {strcpy(starl,instring);
          starm[0]=starr[0]='\0';
          return(TRUE);
          }
     else
          {split(instring,i,starl,starr);
          starm[0]='\0';
          if(starr[0]=='\0')  return(TRUE);
          else
               return(FALSE);
          }

}



/*  scanr - scans instring from right for pat.
          pat can contain characters or a class
          (prefixed by _).  instring must be terminated
          by '\0'.  Returns TRUE or FALSE.
*/

scanr(instring,pat,starl,starm,starr)  /* scan from right */
char  instring[], pat[], starl[], starm[], starr[];
{
     int   i, alp, num, low, up;

     /*  special cases  */

     if(instring[0]=='\0')
          {starl[0]=starm[0]=starr[0]='\0';
          return(FALSE);
          }
     if(pat[0]=='\0')
          {strcpy(starr,instring);
          starl[0]=starm[0]='\0';
          return(FALSE);
          }

     /*  normal case without class  */

     if(pat[0]==CLASC)  goto class;

     if(index(instring,pat)<0)
          {strcpy(starr,instring);
          starl[0]=starm[0]='\0';
          return(FALSE);
          }
     else
          {scan(instring,pat,starl,starm,starr);
          return(TRUE);
          }

     /*  normal case with class  */

     class:  if(getclass(pat,&alp,&num,&low,&up)==ERROR)
          {fprintf(STDERR,"\nbad class in scanr %s",pat);
          fprintf(STDERR," treated as null\n");
          strcpy(starr,instring);
          starl[0]=starm[0]='\0';
          return(FALSE);
          }

     for(i=strlen(instring)-1;i>=0;i--)
          {if(alp && isalpha(instring[i]))  break;
          if(num  && isdigit(instring[i]))   break;
          if(low  && islower(instring[i]))   break;
          if(up   && isupper(instring[i]))    break;
          }

     if(i<0)
          {strcpy(starr,instring);
          starl[0]=starm[0]='\0';
          return(FALSE);
          }
     else
          {split(instring,i+1,starl,starr);
          starm[0]='\0';
          return(TRUE);
          }
}




/*  scannr - scans instring from right for non-match
          on pat.  pat can contain one character or
          a class (prefixed by _).  instring must be
          terminated by '\0'.  Returns TRUE or FALSE
          (as in TEX, the TRUE and FALSE results are
          not intuitively obvious).
*/

scannr(instring,pat,starl,starm,starr)  /* scan from right for non-match */
char  instring[], pat[], starl[], starm[], starr[];
{
     int  col, i, alp, num, low, up;

     /*  special cases  */

     if(pat[0]=='\0')
          {fprintf(STDERR,"\nerror in scannr null pat\n");
          starl[0]=starm[0]=starr[0]='\0';
          return(FALSE);
          }
     if(instring[0]=='\0')
          {starl[0]=starm[0]=starr[0]='\0';
          return(FALSE);
          }

     /*  normal case without class  */

     if(pat[0]==CLASC)  goto class;

     if(pat[1]!='\0')
          {fprintf(STDERR,"\npat>1 char in scannr %s",pat);
          fprintf(STDERR," used first\n");
          }

     for(i=strlen(instring)-1;i >= 0;i--)
          if(pat[0]!=instring[i]) break;

     if(i<0)
          {starl[0]=starm[0]='\0';
          strcpy(starr,instring);
          return(TRUE);
          }
     else
          {starm[0]='\0';
          split(instring,i+1,starl,starr);
          return(FALSE);
          }

     /* normal case with class */

     class:  if(getclass(pat,&alp,&num,&low,&up)==ERROR)
          {fprintf(STDERR,"\nbad class in scannr %s",pat);
          fprintf(STDERR," treated as null\n");
          starl[0]=starm[0]=starr[0]='\0';
          return(FALSE);
          }

     for(i=strlen(instring)-1;i >= 0;i--)
          {if(alp && !isalpha(instring[i])) break;
          if(num && !isdigit(instring[i]))  break;
          if(low && !islower(instring[i]))  break;
          if(up && !isupper(instring[i]))   break;
          }

     if(i<0)
          {starl[0]=starm[0]='\0';
          strcpy(starr,instring);
          return(TRUE);
          }
     else
          {starm[0]='\0';
          split(instring,i+1,starl,starr);
          return(FALSE);
          }
}
