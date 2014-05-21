import java.io.*;
import java.net.*;
import java.util.Random;


public class matlabConnectionHolder 
{
	  int PORT = 5000;	
	  Socket mlSocket = null;
	  ObjectInputStream ois = null;
	  ObjectOutputStream oos = null;
	  Process matlabProc = null;
	  static String OS = System.getProperty("os.name").toLowerCase();
	  
	  /*
	   * Constructor
	   */
	  public matlabConnectionHolder() 
	  {	
		// create a random port number for java and matlab
	        Random randomGenerator = new Random();
                int randomInt = randomGenerator.nextInt(40000);
                PORT = PORT + randomInt;

		// This insures that matlab is closed when the program is closed
		  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() 
		  {
		        public void run() {
		            System.out.println("In shutdown hook");
		            try { closeMLserver(); } catch (Exception e){ /* ignore */};
		        }
		  }, "Shutdown-thread"));
		  
		  startMatlabServer();
		  
		  boolean connected = false;			
		  while(!connected)
		  {
		  	connected = connect2MLserver();
		  	try 
			{
				Thread.sleep(1000);
			}
		  	catch (Exception e){}
		  }
	  }
	  
	  /*
	   * Constructor that resets port number (probably never needed)
	   */
	  public matlabConnectionHolder(int newPort) 
	  {	
		  // This insures that matlab is closed when the program is closed
		  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() 
		  {
		        public void run() {
		            System.out.println("In shutdown hook");
		            try { closeMLserver(); } catch (Exception e){ /* ignore */};
		        }
		  }, "Shutdown-thread"));
		  
		  PORT = newPort;
		  
		  startMatlabServer();
		  
		  boolean connected = false;
		  while(!connected)
		  {
		  	connected = connect2MLserver();
		  	try 
			{
				Thread.sleep(1000);
			}
		  	catch (Exception e){}
		  }
	  }
	  
	  // initialize matlab server
	  public boolean startMatlabServer() 
	  {		      
		  try 
		  {
			 if (isWindows())
			 {
				 final String dosCommand = "cmd /c matlab -nosplash -r matlabServer1(" + PORT + ")";
				 matlabProc = Runtime.getRuntime().exec(dosCommand);
			     return true;
			 }
			 else 
			 {
				 final String dosCommand = "matlab -nosplash -r matlabServer1(" + PORT + ")";
				 matlabProc = Runtime.getRuntime().exec(dosCommand);
			     return true;
			 }
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }
	  }
	  
	  // Same as startMatlabServer but Matlab is minimized on startup
	  public boolean startMatlabServerMin() 
	  {
		  try 
		  {
			 if (isWindows())
			 {
				 final String dosCommand = "cmd /c matlab -automate -r matlabServer";
				 matlabProc = Runtime.getRuntime().exec(dosCommand);
			     return true;
			 }
			 else 
			 {
				 final String dosCommand = "matlab -automate -r matlabServer";
				 matlabProc = Runtime.getRuntime().exec(dosCommand);
			     return true;
			 }
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }
	  }

	  // connect to matlab server
	  public boolean connect2MLserver()
	  {
		  try 
		  {
			 mlSocket = new Socket("localhost", PORT);
			 
			 // Initialize the object reader and writer			 
			 oos = new ObjectOutputStream(mlSocket.getOutputStream());
			 oos.flush();
			 ois = new ObjectInputStream(mlSocket.getInputStream());
			
		     return true;
		  } 
		  catch (ConnectException ce) 
		  {
		     //ce.printStackTrace();
		     return false;
		  }
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }
	  }
	  
	  // write character to the server
	  public boolean write2MLserver(byte aChar)
	  {
		  try 
		  {
			  oos.writeByte(aChar);
			  oos.flush();
			 
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }	  
	  }
	  
	// write string to the server
	  public boolean write2MLserver(String command)
	  {
		  try 
		  {
			  oos.writeByte((byte)1);
			  oos.writeBytes(command);
			  oos.writeByte((byte)13);
			  //oos.writeObject();
			  oos.flush();
			 
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }	  
	  }
	  
	  // write double to the server
	  public boolean sendDouble2MLserver(double object2send, String objectName)
	  {
		  try 
		  {
			  oos.writeByte((byte)2);
			  oos.writeObject(object2send);
			  oos.writeBytes(objectName);
			  oos.writeByte((byte)13);
			  oos.flush();
			 
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }	  
	  }
	  
	  // write double[] to the server
	  public boolean sendDouble2MLserver(double[] object2send, String objectName)
	  {
		  try 
		  {
			  oos.writeByte((byte)2);
			  oos.writeObject(object2send);
			  oos.writeBytes(objectName);
			  oos.writeByte((byte)13);
			  oos.flush();
			 
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }	  
	  }
	  
	  // write character[] to the server
	  public boolean sendString2MLserver(String object2send, String objectName)
	  {
		  try 
		  {
			  oos.writeByte((byte)3);
			  oos.writeBytes(object2send);
			  oos.writeByte((byte)13);
			  oos.writeBytes(objectName);
			  oos.writeByte((byte)13);
			  oos.flush();
			 
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }	  
	  }
	  
	  // write string[] to the server
	  public boolean sendStringList2MLserver(String[] stringList, String objectName)
	  {
		  try 
		  {
			  oos.writeByte((byte)4);
			  oos.writeInt(stringList.length);
			  oos.writeBytes(objectName);
			  oos.writeByte((byte)13);
			  
			  for (int i = 0; i < stringList.length; i++)
			  {				  
				  oos.writeBytes(stringList[i]);
				  oos.writeByte((byte)13);			  
			  }
			  oos.flush();
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }	  
	  }
	  
	  // get string object from the server
	  public String getStrFromMLserver(String objectname) throws Exception
	  {
		  try 
		  {
			  // Send name of desired variable
			  oos.writeByte((byte)5);
			  oos.writeBytes(objectname);
			  oos.writeByte((byte)13);
			  oos.flush();
			  
			  // Receive string
			  char msg = 'a';
			  int lengthOfString = ois.readInt();
			  String var2return = "";
			  if (lengthOfString > -1)
			  {
				  try
				  {
					  msg = (char)ois.readByte();
					  while((byte)msg != 13)
					  {
						  var2return += msg;
						  msg = (char)ois.readByte();
					  }
				  }
				  catch (Exception e)
				  {
					  return "";
				  }
			  }
			  else
			  {
				  ois.readByte();
				  throw new Exception();
			  }

		     return var2return;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return null;
		  }	  
	  }
	  
	  // get string list object from the server
	  public String[] getStrListFromMLserver(String objectname) throws Exception
	  {
		  try 
		  {
			  // Send name of desired variable
			  oos.writeByte((byte)6);
			  oos.writeBytes(objectname);
			  oos.writeByte((byte)13);
			  oos.flush();
			  
			  // Receive string
			  char msg = 'a';
			  String[] incomingList = null;
			  int lengthOfStringList = ois.readInt();
			  String nextStringInList = "";
			  
			  if (lengthOfStringList > -1)
			  {
				  try
				  {		
					  incomingList = new String[lengthOfStringList];
					  for (int i = 0; i < lengthOfStringList; i++)
					  {
						  msg = (char)ois.readByte();
						  while((byte)msg != 13)
						  {
							  nextStringInList += msg;
							  msg = (char)ois.readByte();
						  }
						  incomingList[i] = nextStringInList;
						  nextStringInList = "";
					  }
				  }
				  catch (Exception e)
				  {
					  return null;
				  }
			  }
			  else
			  {
				  ois.readByte();
				  throw new Exception();
			  }

		     return incomingList;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return null;
		  }	  
	  }
	  
	  // get double object from the server
	  public double getDoubleFromMLserver(String objectname) throws Exception
	  {
		  try 
		  {
			  // Send name of desired variable
			  oos.writeByte((byte)7);
			  oos.writeBytes(objectname);
			  oos.writeByte((byte)13);
			  oos.flush();
			  
			  // Receive double
			 double var2return = 0;
			 int sizeOfArray = 0;			
			 try
			 {
				 sizeOfArray = ois.readInt(); // Should equal 1
				 if (sizeOfArray == 1)
				 {
					 var2return = (Double)ois.readObject();
					 ois.readByte();
				 }
				 else
				 {
					 ois.readByte();
					 throw new Exception();
				 }
			 }
			 catch (Exception e)
			 {
				//e.printStackTrace();
			     return 0;
			 }
			 
		     return var2return;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return 0;
		  }	  
	  }
	  
	  // get double[] object from the server
	  public double[] getDoubleListFromMLserver(String objectname) throws Exception
	  {
		  double[] var2return = {};
		  try 
		  {
			  // Send name of desired variable
			  oos.writeByte((byte)7);
			  oos.writeBytes(objectname);
			  oos.writeByte((byte)13);
			  oos.flush();
			  
			  // Receive double
			  int sizeOfArray = 0;			
			 try
			 {
				 sizeOfArray = ois.readInt();
				 if (sizeOfArray > -1)
				 {
				 System.out.println("array is of len: " + sizeOfArray);
				 var2return = (double[])ois.readObject();
				 ois.readByte();
				 }
				 else
				 {
					 ois.readByte();
					 throw new Exception();
				 }
			 }
			 catch (Exception e)
			 {
				//e.printStackTrace();
			     return var2return;
			 }
			 
		     return var2return;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return var2return;
		  }	  
	  }
	  
	  // close the matlab server by sending an ASCII 6 
	  public boolean closeMLserver()
	  {
		  try 
		  {
			  oos.writeByte((byte)8);
			  oos.flush();
			 
			 mlSocket.close();
			 ois.close();
			 oos.close();
			  
		     return true;
		  } 
		  catch (IOException e) 
		  {
		     //e.printStackTrace();
		     return false;
		  }
		  
	  }
	  
	  public static boolean isWindows() {
		  
			return (OS.indexOf("win") >= 0);
	 
		}
	 
		public static boolean isMac() {
	 
			return (OS.indexOf("mac") >= 0);
	 
		}
	 
		public static boolean isUnix() {
	 
			return (OS.indexOf("nix") >= 0 || OS.indexOf("nux") >= 0 || OS.indexOf("aix") > 0 );
	 
		}
}
