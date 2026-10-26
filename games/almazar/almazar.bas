5  CLRSCREEN$ = CHR$(27)+"*"
10 PRINT CLRSCREEN$:PRINT TAB(10)"The Search for Almazar: Part I":PRINT TAB(16)"The proving Ground":PRINT
20 '
30 PRINT"  The Series.":PRINT :PRINT"  The Game begins at one end of a road, by an old"
32 PRINT"abandoned shack (just like the original ADVENTURE).":PRINT"You can explore many different scenarios -but be ":PRINT"careful.
40 PRINT"There are many traps for the unwary and unthinking":PRINT"adventurer.
42 PRINT:PRINT "[Press any key for more information]";
45 I$=INKEY$:IF I$<>"" GOTO 50 ELSE 45
50 PRINT CLRSCREEN$:PRINT"The program accepts 1 or 2 word commands..."
51 PRINT "Some examples:":PRINT"  To take an object, type TAKE OBJECT or T OBJECT.":PRINT"  To go North, type North or N for short":PRINT"  To see what you are carrying, type"; 
55 PRINT"  INVE(NTORY)."
60 PRINT"  Type SCORE to get current score":PRINT"  Type SAVE and the game will be saved for later":PRINT"  play."
65 PRINT"  Type QUIT for termination":PRINT"  To light a lamp type LIGHT LAMP or conversely -":PRINT"   OFF LAMP
66 PRINT:PRINT "[Press any key for more information]";
67 I$=INKEY$:IF I$<>"" GOTO 70 ELSE 67
70 PRINT"  To get a description of the room, type LOOK":PRINT:PRINT"Other commands include:-  SMASH":PRINT TAB(27)"TOSS":PRINT TAB(27)"SHOW":PRINT TAB(27)"CROSS  etc.
75 PRINT"In addition, one may type ENTER to enter a shack":PRINT TAB(24)"or LEAVE to leave a shack.":PRINT"Of course, if there is no way out, you cannot leave.
80 PRINT"A hint - Caves are often dark & dangerous.
82 PRINT:PRINT "[Press any key for more information]";
85 I$=INKEY$:IF I$<>"" GOTO 90 ELSE 85
90 PRINT CLRSCREEN$:PRINT"You have a limited no. of turns to accomplish":PRINT"your task. If you do not finish on time you will ...":PRINT:PRINT"From time to time you need a hint, so just type":PRINT"          HINT or HELP."
95 PRINT"Remember - nothing is free in todays world.":PRINT"          GOOD LUCK"
97 PRINT:PRINT "[Press any key to start ALMAZAR]";
100 I$=INKEY$:IF I$="" GOTO 100 ELSE PRINT CLRSCREEN$: RUN "SFAMAIN"
