C
C     Program to TEST the functions supported in CPMLIB.
C
C     Version 1.0
C     January 12, 1982
C
C     Author:     William R. Brandoni
C
C     Language:   Microsoft FORTRAN-80
C
C
C     To use this program:
C     (assuming drive A: is the system + FORTRAN drive and
C      drive B: contains all of the CPMLIB files)
C     1) Compile using F80
C     2) Link using L80, as follows:
C            A>L80 B:TEST,B:CPMLIB/S,FORLIB/S,B:TEST/N/E
C     3) Run the TEST program
C
C
      IMPLICIT LOGICAL*1 ( A-H, O-Z )
      DIMENSION ARRAY(80)
      DIMENSION FILNAM(25)
      DIMENSION FILNM2(25)
C         The array FUNCT should be dimensioned as follows:
C         1st dimension (6) = max. number of characters in function names
C         2nd dimension (5) = value of variable NFUNC
      DIMENSION FUNCT(6, 5)
C
      DATA FUNCT / 'I','N','C','H','R',' ',
     A             'I','N','K','E','Y',' ',
     B             'E','R','A','S','E',' ',
     C             'R','E','N','A','M','E',
     D             'E','X','I','S','T',' '/
C         The variable NFUNC should be the number of functions
C         searched for in the program.
      DATA NFUNC /  5  /
C         The variable NTEST is the maximum number of characters
C         tested in the function search.
      DATA NTEST /  3  /
      DATA YES   / 'Y' /
      DATA ZERO  /  0  /
C
C                             Get the command line tail
C                             (tests the GETCMD routine)
C                             and see what other routine is
C                             to be tested.
C
      CALL GETCMD ( ARRAY )
C
C         See what command is desired
C
      NBYTES = ARRAY(1)
      IF ( NBYTES .GT. 0 ) GOTO 20
      WRITE ( 3, 9000 )
      GOTO 8950
C
   20 NLONG = NBYTES
      IF ( NLONG .GT. NTEST ) NLONG = NTEST
      DO 50 J = 1, NFUNC
      KFUNC = J
      K2    = 0
      DO 40 K = 1, NLONG
      K1 = K + 1
      IF ( ARRAY(K1) .EQ. FUNCT(K,J) ) K2 = K2 + 1
   40 CONTINUE
      IF ( K2 .EQ. NLONG ) GOTO 60
   50 CONTINUE
      WRITE ( 3, 9100 )
      GOTO 8900
   60 GOTO ( 100, 200, 300, 400, 500 ), KFUNC
C
C     INCHR routine
C
  100 CONTINUE
      WRITE ( 3, 9980 )
      READ  ( 3, 9995 ) NOPT
      WRITE ( 3, 9200 )
      CALL INCHR ( NOPT, A )
      WRITE ( 3, 9210 ) A, A
      GOTO 8900
C
C     INKEY routine
C
  200 CONTINUE
      WRITE ( 3, 9980 )
      READ  ( 3, 9995 ) NOPT
      WRITE ( 3, 9200 )
      CALL INKEY ( NOPT, A )
      WRITE ( 3, 9210 ) A, A
      GOTO 8900
C
C     ERASE routine
C
  300 CONTINUE
      WRITE ( 3, 9985 )
      READ  ( 3, 9995 ) NDRIVE
      WRITE ( 3, 9300 )
      READ  ( 3, 9990 ) (FILNAM(J), J = 1, 25 )
      CALL ERASE ( NDRIVE, FILNAM, 25 )
      GOTO 8900
C
C     RENAME routine
C
  400 CONTINUE
      WRITE ( 3, 9985 )
      READ  ( 3, 9995 ) NDRIVE
      WRITE ( 3, 9400 )
      READ  ( 3, 9990 ) (FILNAM(J), J = 1, 25 )
      WRITE ( 3, 9410 )
      READ  ( 3, 9990 ) (FILNM2(J), J = 1, 25 )
      CALL RENAME ( NDRIVE, FILNAM, FILNM2, 25, 25 )
      GOTO 8900
C
C     EXIST routine
C
  500 CONTINUE
      WRITE ( 3, 9985 )
      READ  ( 3, 9995 ) NDRIVE
      WRITE ( 3, 9500 )
      READ  ( 3, 9990 ) (FILNAM(J), J = 1, 25 )
      CALL EXIST ( NDRIVE, FILNAM, 25, IOK )
      IF ( IOK .EQ. 1 ) WRITE ( 3, 9510 )
      IF ( IOK .EQ. 0 ) WRITE ( 3, 9520 )
      GOTO 8900
C
C     All done
C
 8900 CONTINUE
      WRITE ( 3, 9989 )
      CALL INCHR ( 2, ANS )
      IF ( ANS .EQ. YES ) GOTO 60
 8950 CONTINUE
C
C     Formats
C
 9000 FORMAT(//,' To test a function, type the function name',/,
     A          ' after the program name on the command line.',//,
     B          ' For example:',/,
     C          '               A>TEST ERASE',//,
     D          ' will test the erase function.',//)
 9100 FORMAT(/,' Invalid function name.' )
 9200 FORMAT(/,' Touch any key .... ')
 9210 FORMAT(/,' The key was ASCII ', I3, ' which is graphic ', A1 )
 9300 FORMAT(/,' Enter name of file to erase ... ')
 9400 FORMAT(/,' Enter old name of file ... ')
 9410 FORMAT(/,' Enter new name of file ... ')
 9500 FORMAT(/,' Enter name of file to test ... ')
 9510 FORMAT(/,' ... FILE EXISTS ...')
 9520 FORMAT(/,' ... FILE DOES NOT EXIST ...')
 9980 FORMAT(/,' Option ... ')
 9985 FORMAT(/,' Drive ( 0, 1, 2, etc.) ... ')
 9989 FORMAT(//,' Another try (y/n) ... ')
 9990 FORMAT(25A1)
 9995 FORMAT(I5)
       END
