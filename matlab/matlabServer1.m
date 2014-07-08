function matlabServer1(myPort)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MatlabServer
%
% This scripts starts a minimalistic Matlab "server".
%
% When started, the server listens for connections at port myPort.
%
% Requirements:
% This requires Matlab with Java support, i.e. Matlab v6 or higher.
%
% Author: Matthew Biggs 2013
% Based on code written by Henrik Bengtsson, 2002-2010 for the R extension
% in Netlogo
%
% 
% 
% 
% 
%    Information for Kirschner-Linderman version
%
%
% This file is included in the Netlogo-Matlab extension written by Matt Briggs 
% at the University of Virginia.  It can be found here: https:
% //github.com/mbi2gs/netlogo-matlab-extension/wiki.  The current package
% contains code to run in headless mode in which port(socket) numbers are 
% randomly generated.  This allows multiple copies of the program to be run 
% simultaneously.  This can be run in headless mode if the thread=1 option is 
% added to the netlogo command line to limit the number of threads created  
% for the Matlab server to 1.  
% 
% The version we use, creates a file in the /tmp directory and keeps track of 
% the current port(socket) number be assigned.  Each Netlogo run, locks this 
% file, increments the port(socket) number in the file, uses the new port(socket) 
% number to start the Matlab server, then releases the file.  This allows multiple
% batch jobs to run with independent port(socket) numbers and avoids the 
% possiblility of duplicate port(socket) numbers.  This has only been
% tested on Linux machines.  In order to run on Windows/Mac
% servers/clusters, the /tmp directory will have to be changed.
% 
% In order to run the Netlogo-Matlab interface there is a series of things you
% need to do.  First download the software from https:
% //github.com/mbi2gs/netlogo-matlab-extension/wiki.  This zip file contains 
% matlab.jar,  a copy of this file, the java source and a README.txt.  The 
% matlab.jar contains the compiled java code needed for communicating between
% Netlogo and Matlab by opening a port(socket}.  The matlab.jar file needs to be in 
% the extensions directory in Netlogo installation directory.  If you go to 
% the root directory for the Netlogo installation, you will see an “extensions” 
% subdirectory.  Go into the “extensions” subdirectory.  You will see a list 
% of sub-directories for each of the Netlogo supplied extensions (such as: 
% array, bitmap, …).  Create a matlab directory.  Put the matlab.jar into the
% newly created Matlab directory.  This will allow Netlogo to find it when it 
% executes it's “extension [matlab]” command in the code.  The java source is 
% needed to recreate matlab.jar.  The README.txt contains information on the 
% calls you can add to your Netlogo model in order to communicate between 
% Matlab and Netlogo.
% 
% Now open your Netlogo model in Netlogo.  Select the “Code” tab and enter the
% line “extensions [matlab]” at the top of the program.  This notifies Netlogo,
% that the model will be referring to code in the  netlogo-x.x.x/extensions/matlab
% directory.  You can now add calls to your model that will allow communication
% back and forth between Netlogo and Matlab.  Save your model.
% 
% Now you need to add this Matlab file (matlabServer1.m) to a directory 
% referenced in “File” “Set Path” path structure in Matlab.  
% 
% You are now set up to run the Netlogo-Matlab extension.  This is with the 
% default code to create radomly generated port(socket) number.  It is possible
% to run into duplicate port(socket) numbers if you are running with enough 
% cpu's or clusters in batch mode.  For 20 simultaneous cpu's the odds are 
% about .5%.  
% 
% For our runs, we have rewritten the code to create a temporary file,
% “/tmp/portNo.txt”,  which keeps track of the current port(socket) number 
% being used.  Each time a new Netlogo-Matlab process is started up, this file
% is locked and the port number inside is incremented by 1.  This is the number
% used for the port(socket) number for the new run and then the file is unlocked.
% This prevents current jobs from running into common port(socket) numbers.  
% In order to change Matt Brigg's code, you need to unpack the matlab.jar file, 
% unload the java files from the zip file, swap in our file, compile it, and 
% reconstruct the matlab.jar file.  You can extract the matlab.jar files with:
%
% jar xvf matlab.jar.   
%
% You can compile the java files with the command: 
%
% javac -classpath "/path/netlogo-x.x.x/NetLogo.jar" -d classes 
%                         matlabConnectionHolder.java matlabExtension.java
%
% You can recreate the matalab.jar file witth the command: 
%
% jar cvfm matlab.jar manifest.txt -C classes.
% 
% Replace the matlab.jar file in netlogo-x.x.x/extensions/matlab with this file.
% 
% There are a couple of other problems to watch out for when running 
% Netlogo-Matlab in batch mode.  When running Netlogo headless, Netlogo tries 
% to launch multiple Matlab port(socket) sessions to take advantage of multiple
% cpus (for their ability to do parameter runs inside Netlogo).  In order to 
% inhibit this, we use the command line option “threads=1” to force only
% 1 Matlab port(socket) session per Netlogo session.  The “threads=1”
% option is coded in the net-qsub.sh script and should be taken care of 
% automatically. Secondly, Netlogo views the directory where it's software
% scripts reside as the home user directory.  When creating new files, this 
% must be taken into account to make sure all the files end up where they 
% should.
%     
% Matlab currently only allows 2^16 characters to be written to command window
% while in headless mode.  Make sure your matlab .m files don't write anything
% to the commmand line.  This usually occurs from print statements or by leaving
% the terminating character (semi-colon) off of each program line.  The print 
% lines in this program have been turned off.  You can re-enable them by changing
% "debug" to true.     
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running MatlabServer v1.0');

%  addpath R/R_LIBS/linux/library/R.matlab/misc/

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Matlab version-dependent setup
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
isVersion7 = eval('length(regexp(version, ''^7'')) ~= 0', '0');
if (~isVersion7)
  disp('Matlab v6.x detected.');
  % Default save option
  saveOption = '';
  % In Matlab v6 only the static Java CLASSPATH is supported. It is
  % specified by a 'classpath.txt' file. The default one can be found
  % by which('classpath.txt'). If a 'classpath.txt' exists in the 
  % current(!) directory (that Matlab is started from), it *replaces*
  % the global one. Thus, it is not possible to add additional paths;
  % the global ones has to be copied to the local 'classpath.txt' file.
  %
  % To do the above automatically from R, does not seem to be an option.
else
  disp('Matlab v7.x or higher detected.');
  % Matlab v7 saves compressed files, which is not recognized by
  % R.matlab's readMat(); force saving in old format.
  saveOption = '-V6';
  disp('Saving with option -V6.');

  % In Matlab v7 both static and dynamic Java CLASSPATH:s exist.
  % Using dynamic ones, it is possible to add the file
  % InputStreamByteWrapper.class to CLASSPATH, given it is
  % in the same directory as this script.
  javaaddpath({fileparts(which('MatlabServer'))});
  disp('Added InputStreamByteWrapper to dynamic Java CLASSPATH.');
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Import Java classes
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
import java.io.*;
import java.net.*;

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% If an old Matlab server is running, close it
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% If a server object exists from a previous run, close it.
if (exist('server'))
  close(server); 
  clear server;
end

% If an input stream exists from a previous run, close it.
if (exist('is'))
  close(is);
  clear is;
end

% If an output stream exists from a previous run, close it.
if (exist('os'))
  close(os);
  clear os;
end
debug = false;
if (debug) 
  fprintf(1, '----------------------\n');
  fprintf(1, 'Matlab server started!\n');
  fprintf(1, '----------------------\n');
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Initiate server socket to which clients may connect
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

% Ports 1-1023 are reserved for the Internet Assigned Numbers Authority.
% Ports 49152-65535 are dynamic ports for the OS. [3]
if (myPort < 1023 | myPort > 65535)
  error('Cannot not open connection. Port is out of range [1023,65535]: %d', myPort);
end

if (debug) 
  fprintf(1, 'Trying to open server socket (port %d)...', myPort);
end
server = java.net.ServerSocket(myPort);
if (debug) 
  fprintf(1, 'done.\n');
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Wait for client to connect
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Create a socket object from the ServerSocket to listen and accept
% connections.
% Open input and output streams

% Wait for the client to connect
clientSocket = server.accept();

if (debug) 
  fprintf(1, 'Connected to client.\n');
end

% ...client connected.
in = clientSocket.getInputStream();
os = clientSocket.getOutputStream();
%bos = java.io.BufferedWriter(java.io.OutputStreamWriter(os));
%bfs = java.io.BufferedReader(java.io.InputStreamReader(in));
oos = java.io.ObjectOutputStream(os);
oos.flush();
ois = java.io.ObjectInputStream(in);

% Global storage for recieved objects
object = '';

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% The Matlab server state machine
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

state = 0;
while (state >= 0),
  if (state == 0)
    try
        cmd = native2unicode(ois.readByte());
	if (debug) 
          fprintf(1, 'Received cmd: %d\n', cmd);
     	end
        
        if (cmd < 0 | cmd > 8)
	  if (debug) 
            fprintf(1, 'Unknown command code: %d\n', cmd);
	  end
          cmd = 0;
        else
          state = cmd;
	  if (debug) 
            fprintf(1,'state = %d\n',state);
	  end
        end
    catch exception
        cmd = 0;
        % ignore exceptions at this point
    end
    
    
  %-------------------
  % 'receive command'
  %-------------------
  elseif (state == 1)
    try
        msg = native2unicode(ois.readByte());
        
        command = '';
        while not(uint8(msg) == 13)
            command = strcat(command,msg);
            try
                msg = native2unicode(ois.readByte());
            catch EOFexception
                msg = native2unicode(13);
            end        
        end
        
	if (debug) 
          fprintf('command = %s\n',command);
	end
        eval(command);
	if (debug) 
          fprintf('eval done\n');
	end
        
    catch EOFexception
	if (debug) 
          fprintf('empty command stream.\n');
	end
    end
    flush(oos);
    state = 0;
  
  %-------------------
  % 'receive double from Netlogo'
  %  Only accept two types of objects:
  %  1) Characters or character arrays
  %  2) Doubles or double arrays <-----
  %-------------------
  elseif (state == 2)      
    % First receive the object  
    try
       object = ois.readObject();
    catch EOFexception
	if (debug) 
          fprintf('empty object stream.\n');
	end
    end
    if (debug) 
      fprintf(1, 'object is of class: %s\n', class(object));
    end
    
    % Then receive the name 
    msg = native2unicode(ois.readByte());        
    objectName = '';
    while not(uint8(msg) == 13)
        objectName = strcat(objectName,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    if (debug) 
      fprintf(1, 'object name is: %s\n', objectName);
    end
    %Finally, save the object under the name
    try
        eval(strcat(objectName,' = object;'));           
	if (debug) 
          fprintf('object received and saved\n');
	end
    catch exception
	if (debug) 
          fprintf('Error recieving object\n');
	end
    end
    object = '';
    flush(oos);
    state = 0;
  
    
  %-------------------
  % 'receive string from Netlogo'
  %  Only accept two types of objects:
  %  1) Characters or character arrays <---
  %  2) Doubles or double arrays
  %-------------------
  elseif (state == 3)
      
    % First receive the object  
    % Then recieve the name 
    msg = native2unicode(ois.readByte());        
    object = '';
    while not(uint8(msg) == 13)
        object = strcat(object,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    if (debug) 
      fprintf(1, 'object is of class: %s\n', class(object));
    end
    
    % Then receive the name 
    msg = native2unicode(ois.readByte());        
    objectName = '';
    while not(uint8(msg) == 13)
        objectName = strcat(objectName,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    if (debug) 
      fprintf(1, 'object name is: %s\n', objectName);
    end
    
    %Finally, save the object under the name
    try
        eval(strcat(objectName,' = object'));           
	if (debug) 
          fprintf('string received and saved\n');
	end
    catch exception
	if (debug) 
          fprintf('Error recieving string\n');
	end
    end
    object = '';
    flush(oos);
    state = 0;
    
  %-------------------
  % 'receive string list from Netlogo'
  %  Only accept two types of objects:
  %  1) Characters or character arrays <---
  %  2) Doubles or double arrays
  %-------------------
  elseif (state == 4)
      
    % First receive the length of the object  
    objLen = ois.readInt();
    
    % Then receive the name 
    msg = native2unicode(ois.readByte());        
    objectName = '';
    while not(uint8(msg) == 13)
        objectName = strcat(objectName,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    if (debug) 
      fprintf(1, 'object name is: %s\n', objectName);
    end
    
    % Get each string and store in a cell
    strList = {};
    for i = 1:objLen
        msg = native2unicode(ois.readByte());        
        stringI = '';
        while not(uint8(msg) == 13)
            stringI = strcat(stringI,msg);
            try
                msg = native2unicode(ois.readByte());
            catch EOFexception
                msg = native2unicode(13);
            end        
        end
        strList = [strList; stringI];
    end
    
    %Finally, save the object under the name
    try
        eval(strcat(objectName,' = strList'));           
	if (debug) 
          fprintf('string received and saved\n');
	end
    catch exception
	if (debug) 
          fprintf('Error recieving string\n');
	end
    end
    strList = {};
    flush(oos);
    state = 0;
    
  %-------------------
  % 'return string'
  % Only return strings or doubles because
  % That's all that Netlogo uses
  %-------------------
  elseif (state == 5)
    % Get name of object that has been requested
    msg = native2unicode(ois.readByte());        
    objectName = '';
    while not(uint8(msg) == 13)
        objectName = strcat(objectName,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    
    % If the object exists, send it to the client
    if exist(objectName, 'var') && length(size(eval(objectName))) <= 2 && min(size(eval(objectName))) == 1 && strcmpi(class(eval(objectName)), 'char')
	if (debug) 
          fprintf(1, 'String with name %s exists.\n', objectName);
	end
        oos.writeInt(length(eval(objectName)));
        oos.writeBytes(eval(objectName));
        oos.writeByte(13);
        oos.flush();
	if (debug) 
          fprintf('Sent object of type string\n');
	end
    else
	if (debug) 
          fprintf(1, 'String with name %s does not exist or is of wrong dimensions.\n', objectName);
	end
       oos.writeInt(-1);
       oos.writeByte(13);
    end
    flush(oos);
    state = 0;
    
  %-------------------
  % 'return string list'
  % Only return strings or doubles because
  % That's all that Netlogo uses
  %-------------------
  elseif (state == 6)
    % Get name of object that has been requested
    msg = native2unicode(ois.readByte());        
    objectName = '';
    while not(uint8(msg) == 13)
        objectName = strcat(objectName,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    
    % If the object exists, send it to the client
    if exist(objectName, 'var') && length(size(eval(objectName))) <= 2 && min(size(eval(objectName))) == 1 && strcmpi(class(eval(objectName)), 'cell')
	if (debug) 
          fprintf(1, 'String list with name %s exists.\n', objectName);
	end
        
        %first send list length
        object = eval(objectName);
        objLen = length(object);
        oos.writeInt(objLen);
        
        % then send each string in turn
        for i = 1:objLen
            oos.writeBytes(object(i));
            oos.writeByte(13);
            oos.flush();
        end
	if (debug) 
          fprintf('Sent object of type string\n');
	end
    else
	if (debug) 
          fprintf(1, 'String list with name %s does not exist or is of wrong dimensions.\n', objectName);
	end
       oos.writeInt(-1);
       oos.writeByte(13);
    end
    flush(oos);
    state = 0;
  
  %-------------------
  % 'return double'
  % Only return strings or doubles because
  % That's all that Netlogo uses
  %-------------------
  elseif (state == 7)
    % Get name of object that has been requested
    msg = native2unicode(ois.readByte());  
    objectName = '';
    while not(uint8(msg) == 13)
        objectName = strcat(objectName,msg);
        try
            msg = native2unicode(ois.readByte());
        catch EOFexception
            msg = native2unicode(13);
        end        
    end
    
    % If the object exists, send it to the client
    if exist(objectName, 'var') && length(size(eval(objectName))) <= 2 && min(size(eval(objectName))) == 1 && strcmpi(class(eval(objectName)), 'double')
	if (debug)
          fprintf(1, 'double or double[] with name %s exists.\n', objectName); 
	end
               
        sizeOfObj = size(eval(objectName));
        if length(sizeOfObj) <= 2
            oos.writeInt(max(sizeOfObj));
            object2send = eval(objectName);
            oos.writeObject(object2send);
            oos.writeByte(13);
            oos.flush();
	    if (debug)
              fprintf('Sent object of type double.\n');
	    end
        else
            oos.writeInt(-1);
            oos.writeByte(13);
	    if (debug)
              fprintf('Object is too high dimensional.\n');
	    end
        end        
    else
	if (debug)
          fprintf(1, 'object with name %s does not exist or is of wrong dimensions.\n', objectName);
	end
       oos.writeInt(-1);
       oos.writeByte(13);
    end
    flush(oos);
    state = 0;
    
  %-------------------
  % 'endServer'
  %-------------------
  elseif (state == 8)
    flush(oos);
    state = -1;
  end
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Shutting down the Matlab server
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

if (debug)
  fprintf(1, '-----------------------\n');
  fprintf(1, 'Matlab server shutdown!\n');
  fprintf(1, '-----------------------\n');
end
oos.write(0);
close(clientSocket);
close(server);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HISTORY:
% o Created February 2013.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
