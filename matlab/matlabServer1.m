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

fprintf(1, '----------------------\n');
fprintf(1, 'Matlab server started!\n');
fprintf(1, '----------------------\n');


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Initiate server socket to which clients may connect
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

% Ports 1-1023 are reserved for the Internet Assigned Numbers Authority.
% Ports 49152-65535 are dynamic ports for the OS. [3]
if (myPort < 1023 | myPort > 65535)
  error('Cannot not open connection. Port is out of range [1023,65535]: %d', myPort);
end

fprintf(1, 'Trying to open server socket (port %d)...', myPort);
server = java.net.ServerSocket(myPort);
fprintf(1, 'done.\n');


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Wait for client to connect
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% Create a socket object from the ServerSocket to listen and accept
% connections.
% Open input and output streams

% Wait for the client to connect
clientSocket = server.accept();

fprintf(1, 'Connected to client.\n');

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
        fprintf(1, 'Received cmd: %d\n', cmd);
        
        if (cmd < 0 | cmd > 8)
          fprintf(1, 'Unknown command code: %d\n', cmd);
          cmd = 0;
        else
          state = cmd;
          fprintf(1,'state = %d\n',state);
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
        
        fprintf('command = %s\n',command);
        eval(command);
        fprintf('eval done\n');
        
    catch EOFexception
        fprintf('empty command stream.\n');
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
        fprintf('empty object stream.\n');
    end
    fprintf(1, 'object is of class: %s\n', class(object));
    
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
    fprintf(1, 'object name is: %s\n', objectName);
    %Finally, save the object under the name
    try
        eval(strcat(objectName,' = object'));           
        fprintf('object received and saved\n');
    catch exception
        fprintf('Error recieving object\n');
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
    fprintf(1, 'object is of class: %s\n', class(object));
    
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
    fprintf(1, 'object name is: %s\n', objectName);
    
    %Finally, save the object under the name
    try
        eval(strcat(objectName,' = object'));           
        fprintf('string received and saved\n');
    catch exception
        fprintf('Error recieving string\n');
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
    fprintf(1, 'object name is: %s\n', objectName);
    
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
        fprintf('string received and saved\n');
    catch exception
        fprintf('Error recieving string\n');
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
        fprintf(1, 'String with name %s exists.\n', objectName);
        oos.writeInt(length(eval(objectName)));
        oos.writeBytes(eval(objectName));
        oos.writeByte(13);
        oos.flush();
        fprintf('Sent object of type string\n');
    else
       fprintf(1, 'String with name %s does not exist or is of wrong dimensions.\n', objectName);
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
        fprintf(1, 'String list with name %s exists.\n', objectName);
        
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
        fprintf('Sent object of type string\n');
    else
       fprintf(1, 'String list with name %s does not exist or is of wrong dimensions.\n', objectName);
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
        fprintf(1, 'double or double[] with name %s exists.\n', objectName); 
               
        sizeOfObj = size(eval(objectName));
        if length(sizeOfObj) <= 2
            oos.writeInt(max(sizeOfObj));
            object2send = eval(objectName)
            oos.writeObject(object2send);
            oos.writeByte(13);
            oos.flush();
            fprintf('Sent object of type double.\n');
        else
            oos.writeInt(-1);
            oos.writeByte(13);
            fprintf('Object is too high dimensional.\n');
        end        
    else
       fprintf(1, 'object with name %s does not exist or is of wrong dimensions.\n', objectName);
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

fprintf(1, '-----------------------\n');
fprintf(1, 'Matlab server shutdown!\n');
fprintf(1, '-----------------------\n');
oos.write(0);
close(clientSocket);
close(server);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HISTORY:
% o Created February 2013.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
