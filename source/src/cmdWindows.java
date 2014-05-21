import java.io.*;
import java.net.*;
import java.util.concurrent.*;

public class cmdWindows 
{
	static matlabConnectionHolder mlConn = new matlabConnectionHolder();
	static double[] arrayOdoubles = new double[2];  
	static String[] stringArray = new String[2];
	
	public static void main(String[] args) 
	{
		arrayOdoubles[0] = 543;
		arrayOdoubles[1] = 987;
		String myName = "matt";
		stringArray[0] = "hello";
		stringArray[1] = "goodbye";
				
		System.out.println("hello");
		mlConn.write2MLserver((byte)0);
		mlConn.write2MLserver("a = (1 + 1)");
		mlConn.write2MLserver("c = [1, 2, 3]");
		mlConn.sendDouble2MLserver(12345, "efg");
		mlConn.sendDouble2MLserver(arrayOdoubles, "vector");
		mlConn.sendString2MLserver(myName, "name");
		mlConn.sendStringList2MLserver(stringArray, "strList1");
		
		try
		{
			String[] newStrList = mlConn.getStrListFromMLserver("strList1");
			System.out.println("first string = " + newStrList[0]);
			String[] newStrList2 = mlConn.getStrListFromMLserver("strList13");
			System.out.println("first string = " + newStrList[0]);
		}
		catch (Exception e)
		{
			
		}
		
		try
		{
			System.out.println(mlConn.getStrFromMLserver("name"));
			System.out.println(mlConn.getStrFromMLserver("food"));
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		try
		{
			System.out.println(mlConn.getDoubleFromMLserver("efg"));
			System.out.println(mlConn.getDoubleFromMLserver("food2"));
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		try
		{
			arrayOdoubles = mlConn.getDoubleListFromMLserver("vector");
			System.out.println(mlConn.getDoubleListFromMLserver("$^#@&&@"));
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		System.out.println(arrayOdoubles[0]);
		System.out.println(arrayOdoubles[1]);
		mlConn.write2MLserver((byte)0);
		System.out.println("done");
		
    }
}
