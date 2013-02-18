###================================================================
###
#  Matlab extension for NetLogo
###   Written by Matt Biggs, Feb 2013
###   Contact: mb3ad@virginia.edu
###
###	Based on code by Henrik Bengtsson for the [Matlab-R extension](http://rss.acs.unt.edu/Rdoc/library/R.matlab/html/R.matlab-package.html)
###   and on code by Jan C. Thiele for the [Netlogo-R extension](http://netlogo-r-ext.berlios.de/)
###================================================================

##Getting set up:
You will need to have [NetLogo](http://ccl.northwestern.edu/netlogo/) and [Matlab](http://www.mathworks.com/products/matlab/) installed before use of this extension. 
Place the folder ("matlab") containing "matlab.jar" in your "Netlogo_v#/extensions/" directory.
Place the file "matlabServer.m" in your Matlab path.

To include the matlab extension in a netlogo script, place this at the head of your script:

	extensions[matlab]

When you include the Matlab extension, NetLogo will pause while Matlab starts up. A Matlab
window will be opened, and you will be able to see the output from the server. This window 
can be minimized and ignored. However, you will need to close these windows when you're done.

Because NetLogo only has two basic datatypes (Strings/Lists of strings and Doubles/Lists of Doubles) that are 
Matlab-compatible, the functions provided by this extension only deal with passing those 
datatypes back and forth between NetLogo and Matlab. All variables passed to Matlab, or results of "eval" 
statements, persist in the Matlab environment between commands, and can be re-accessed. 

**The provided functions are:**

##eval:
**Description:** Eval allows the user to run any valid Matlab command from NetLogo, including 
			 *.m files and custom functions/packages in the Matlab path. 
			 
**Input:** Valid Matlab command as a String.

**Output:** None.

**Example Usage:** 

	matlab:eval "a = 1 + 1"
	
	matlab:eval "c = a / 32.2"
	
	matlab:eval "b = {'efg' ; 'hi12'}"
	
	matlab:eval "initCobraToolbox()"
	
	
	
##send-string:
**Description:** Passes a variable of type "String" to Matlab.

**Input:** String variable, and a name for that variable to be stored under in the Matlab environment.

**Output:** None.

**Example Usage:** 

	matlab:send-string "varName" "This is my 1st string."
	
	
##send-string-list:
**Description:** Passes a list of "Strings" to Matlab.

**Input:** List of "strings", and a name for that variable to be stored under in the Matlab environment.

**Output:** None.

**Example Usage:** 

	matlab:send-string-list "varName" (list "a" "Billy" "This is my 1st string.")

	
##send-double:
**Description:** Passes a variable of type "Double" to Matlab.

**Input:** Variable of type double (just a NetLogo number), and a name for that variable to be stored 

	   under in the Matlab environment.
	   
**Output:** None.

**Example Usage:** 

	matlab:send-double "varName" 123.4
	
	
##send-double-list:
**Description:** Passes a list of variables of type "Double" to Matlab.

**Input:** List of variables of type double (just NetLogo numbers in a list), and a name for that variable to be stored 

	   under in the Matlab environment.
	   
**Output:** None.

**Example Usage:** 

	matlab:send-double-list "varName" (list 13.4 3.14798 1 2)
	
	
##get-string:
**Description:** Returns a "string" stored in the Matlab environment (if it exists).

**Input:** The name for that variable as it appears in Matlab.

**Output:** String.

**Example Usage: **

	set myString matlab:get-string "varName"
	
	
##get-string-list:
**Description:** Returns a list of "strings" stored in the Matlab environment (if it exists).

**Input:** The name for that variable as it appears in Matlab.

**Output: **List of strings.

**Example Usage: **

	set myString matlab:get-string-list "varName"
	
	
##get-double:
**Description:** Returns a "double" stored in the Matlab environment (if it exists).

**Input:** The name for that variable as it appears in Matlab.

**Output:** Double.

**Example Usage:** 

	set myNumber matlab:get-double "varName"
	
	
##get-double-list:
**Description:** Returns a list of "doubles" stored in the Matlab environment (if it exists).

**Input:** The name for that variable as it appears in Matlab.

**Output:** List of doubles.

**Example Usage: **

	set myList matlab:get-double-list "varName"
	
	
#================================================================	
##Versions:

**Version 1.0:** February 2013. Tested with NetLogo 5.0.3 and MATLAB R2012a on Windows 7 and Ubuntu 12.04.

#================================================================
