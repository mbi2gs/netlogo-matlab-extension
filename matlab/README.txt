================================================================

MatNet: The Matlab extension for NetLogo
Written by Matt Biggs, Feb 2013
Contact: mb3ad [at] virginia [dot] edu

Based on code by Henrik Bengtsson for the [Matlab-R extension](http://rss.acs.unt.edu/Rdoc/library/R.matlab/html/R.matlab-package.html)
and on code by Jan C. Thiele for the [Netlogo-R extension](http://netlogo-r-ext.berlios.de/)

This software is distributed under the [MIT Open Source](http://opensource.org/licenses/MIT) license.

When using this software, please cite:

[Biggs MB, Papin JA. (2013). Novel Multiscale Modeling Tool Applied to _Pseudomonas_ _aeruginosa_ Biofilm Formation. _PLoS_ _ONE_, 8(10):e78011.](http://www.plosone.org/article/info:doi/10.1371/journal.pone.0078011)

================================================================

Getting set up:
+ You will need to have [NetLogo](http://ccl.northwestern.edu/netlogo/) and [Matlab](http://www.mathworks.com/products/matlab/) installed before use of this extension. 

+ Download the [NetLogo-Matlab-Extension](https://github.com/mbi2gs/netlogo-matlab-extension/archive/master.zip) as a ZIP file. Unzip it.

+ Place the folder ("matlab") containing "matlab.jar" in your "Netlogo_v#/extensions/" directory.

+ Place the file "matlabServer.m" in your Matlab path ([instructions to do this](http://www3.nd.edu/~nancy/Math20550/Homework/matlabpath.pdf)).

To include MatNet in a NetLogo script, place this at the head of your script:

	extensions[matlab]

When you include MatNet, NetLogo will pause while Matlab starts up. A Matlab
window will be opened (unless you're running Linux), and you will be able to see the output from the server. This window can be minimized and ignored. However, you will need to close these windows when you're done.

Because NetLogo only has two basic datatypes (Strings/Lists of strings and Doubles/Lists of Doubles) that are 
Matlab-compatible, the functions provided by this extension only deal with passing those 
datatypes back and forth between NetLogo and Matlab. All variables passed to Matlab, or results of "eval" 
statements, persist in the Matlab environment between commands, and can be re-accessed. 

The provided functions are:
================================================================
eval:
Description: Eval allows the user to run any valid Matlab command from NetLogo, including 
			 *.m files and custom functions/packages in the Matlab path. 
			 
Input: Valid Matlab command as a String.

Output: None.

Example Usage: 

	matlab:eval "a = 1 + 1"
	
	matlab:eval "c = a / 32.2"
	
	matlab:eval "b = {'efg' ; 'hi12'}"
	
	matlab:eval "someFunction()"

Note: According to the [Matlab documentation](http://www.mathworks.com/help/matlab/ref/eval.html), the eval function cannot create variables. These simple examples (e.g. "a = 1 + 1") _will_ create the variables such as "a" that can then be retrieved from within Netlogo. The difficulty is in getting values from your functions or scripts. The best workaround so far is to use the Matlab [assignin](http://www.mathworks.com/help/matlab/ref/assignin.html) command to create variables in the workspace, rather than pass them back. You may find that Netlogo cannot run a function that was written after the extension was started (will print the error "empty command stream" in the Matlab window). If this happens, close Netlogo, write and save your function, then re-open Netlogo. 

Try this example sequence:

        In a Matlab function in your Matlab path:
        function [] = test_function(testInt)
           testMat = magic(testInt);
           testEigs = eig(testMat);
           assignin('caller','retMat',testMat);
           assignin('caller','retEigs',testEigs);
        end
	
        In Netlogo Script:
        extensions[ matlab ]
        globals [myEigs]

        In Netlogo Command Center: 
        matlab:send-double "sendInt" 3 
        matlab:eval "test_function(sendInt)"
        set myEigs matlab:get-double-list "retEigs"
        show myEigs

2nd Note: Matrix passing is not currently supported by this extension, although a workaround has been suggested: it would be possible to use the "get-double-list" or "send-double-list" command within a loop structure to grab/send each column or row in your target matrix. 	

3rd Note: Currently, if the function sent to Matlab (using the "eval" command) is slow, Netlogo will not wait for the results. If you need Netlogo to wait until Matlab is done, one possible workaround is to do something like the code below using a wait command within a loop. In this example, I set a limit on the number of iterations I'm willing to wait:

    matlab:eval "a=1;"
    matlab:eval "slowFunction();a=a+1;"
    
    ; Don't continue until slowFunction() is done
    set matlabReady? false
    let mlcount 0
    while [ matlabReady? = false ]
    [
      set matlabReturnVal (matlab:get-double "a")
      if matlabReturnVal = 2
      [
        set matlabReady? true
      ]
      if mlcount > 50
      [
        set matlabReady? true
      ]
      set mlcount (mlcount + 1)
      wait 0.1
    ]
================================================================
send-string:
Description: Passes a variable of type "String" to Matlab.

Input: String variable, and a name for that variable to be stored under in the Matlab environment.

Output: None.

Example Usage: 

	matlab:send-string "varName" "This is my 1st string."
	
================================================================	
send-string-list:
Description: Passes a list of "Strings" to Matlab.

Input: List of "strings", and a name for that variable to be stored under in the Matlab environment.

Output: None.

Example Usage: 

	matlab:send-string-list "varName" (list "a" "Billy" "This is my 1st string.")

================================================================	
send-double:
Description: Passes a variable of type "Double" to Matlab.

Input: Variable of type double (just a NetLogo number), and a name for that variable to be stored under in the Matlab environment.
	   
Output: None.

Example Usage: 

	matlab:send-double "varName" 123.4
	
================================================================	
send-double-list:
Description: Passes a list of variables of type "Double" to Matlab.

Input: List of variables of type double (just NetLogo numbers in a list), and a name for that variable to be stored under in the Matlab environment.
	   
Output: None.

Example Usage: 

	matlab:send-double-list "varName" (list 13.4 3.14798 1 2)
	
================================================================	
get-string:
Description: Returns a "string" stored in the Matlab environment (if it exists).

Input: The name for that variable as it appears in Matlab.

Output: String.

Example Usage:

	set myString matlab:get-string "varName"
	
================================================================	
get-string-list:
Description: Returns a list of "strings" stored in the Matlab environment (if it exists).

Input: The name for that variable as it appears in Matlab.

Output: List of strings.

Example Usage:

	set myString matlab:get-string-list "varName"
	
================================================================	
get-double:
Description: Returns a "double" stored in the Matlab environment (if it exists).

Input: The name for that variable as it appears in Matlab.

Output: Double.

Example Usage: 

	set myNumber matlab:get-double "varName"
	
================================================================	
get-double-list:
Description: Returns a list of "doubles" stored in the Matlab environment (if it exists).

Input: The name for that variable as it appears in Matlab.

Output: List of doubles.

Example Usage:

	set myList matlab:get-double-list "varName"
	
	
================================================================	
Versions:

Version 1.0: February 2013. Tested with NetLogo 5.0.3, 5.0.4 and MATLAB R2012a, R2013a on Windows 7 and Ubuntu 12.04.

================================================================
