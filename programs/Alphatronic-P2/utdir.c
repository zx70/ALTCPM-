/*  utdir.c -- UTOOL.  Sorted file directory.

     author: David H. Wolen
     last change: 6/5/83

     usage:    utdir *.*           all files on current drive
               utdir !*.com        all files on current drive except .com
               utdir b:*.* !b:*.c  all files on b: except .c
               utdir ?.com         all .com files with single letter 
                                        file name on current drive

     options:  none

     input:    command line only
     output:   STDOUT

     notes:    1.  max of 200 files after expansion
               2.  metacharacters in filename:
                    ! except
                    ? wildcard match a single character
                    * wildcard match 1 or more characters

     linkage:  a:clink utdir -f a:dio -f a:wildexp -ca
*/

#include "a:bdscio.h"
#include "a:dio.h"


main(argc,argv)
int  argc;
char *argv[];
{
     int  i, strcmp();

     if(wildexp(&argc,&argv) == ERROR)
          error("utdir: error in wildexp");
     dioinit(&argc,argv);

     if(argc == 1)
          error("utdir: no matching files");

     qsort(&argv[1],argc-1,2,&strcmp);  /* skip first argv */

     for(i=1; i < argc; i++)
          printf("%s\n",argv[i]);

     dioflush();
}



/* strcmp -- special version. Library version has args *s, *t  */
strcmp(s,t)
char **s, **t;
{
     char *s1, *t1;
     int  i;

     s1=*s;
     t1=*t;
     i=0;

     while(s1[i] == t1[i])
          if(s1[i++] == '\0')
               return(0);

     return(s1[i] - t1[i]);
}
