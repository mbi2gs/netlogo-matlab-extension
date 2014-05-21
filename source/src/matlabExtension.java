import org.nlogo.api.*;

public class matlabExtension extends DefaultClassManager 
{
	  // mlConn holds the matlab connection ... this is only loaded once
	static matlabConnectionHolder mlConn = new matlabConnectionHolder();
	  
	  public void runOnce(org.nlogo.api.ExtensionManager em)
	  {
		  // not used
	  }
	  
	  public void load(PrimitiveManager primitiveManager) 
	  {
	    primitiveManager.addPrimitive("eval", new matlabEval());
	    primitiveManager.addPrimitive("send-string", new matlabSendString());
	    primitiveManager.addPrimitive("send-string-list", new matlabSendStringList());
	    primitiveManager.addPrimitive("send-double", new matlabSendDouble());
	    primitiveManager.addPrimitive("send-double-list", new matlabSendDoubleList());
	    primitiveManager.addPrimitive("get-string", new matlabGetString());
	    primitiveManager.addPrimitive("get-string-list", new matlabGetStringList());
	    primitiveManager.addPrimitive("get-double", new matlabGetDouble());
	    primitiveManager.addPrimitive("get-double-list", new matlabGetDoubleList());
	  }  
	  
	  /*
	   * Send any MatLab command as a string to be evaluated
	   */
	  public static class matlabEval extends DefaultCommand
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.commandSyntax(new int[] {Syntax.StringType()});
		  }
		  
	  	  public void perform(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		  	String matlabCmd = "";
		  		try 
		  		{
		  			matlabCmd = args[0].getString();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			mlConn.write2MLserver(matlabCmd);	
	  	  		}
		  		catch (Exception e)
		  		{
		  			throw new ExtensionException( e.getMessage() ) ;
		  		}
	  	  } 
	    
	  }
	  
	  /*
	   * Send a string to be stored as a variable in MatLab
	   */
	  public static class matlabSendString extends DefaultCommand
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.commandSyntax(new int[] {Syntax.StringType(), Syntax.StringType()});
		  }
		  
	  	  public void perform(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
	  		  	String string2send = "";	  		  	
		  		try 
		  		{
		  			varName = args[0].getString();  
		  			string2send = args[1].getString();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			mlConn.sendString2MLserver(string2send, varName);	
		  		}
		  		catch (Exception e)
		  		{
		  			throw new ExtensionException( e.getMessage() ) ;
		  		}
	  	  } 	    
	  }
	  
	  /*
	   * Send a string list to be stored as a variable in MatLab
	   */
	  public static class matlabSendStringList extends DefaultCommand
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.commandSyntax(new int[] {Syntax.StringType(), Syntax.ListType()});
		  }
		  
	  	  public void perform(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
	  		  	LogoList listFromArgs = null;	  		  	
		  		try 
		  		{
		  			varName = args[0].getString();  
		  			listFromArgs = args[1].getList();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			String[] converted = new String[listFromArgs.size()];
		  			for(int i = 0; i < listFromArgs.size(); i++)
		  			{
		  				converted[i] = (String)listFromArgs.get(i);
		  			}	
		  			mlConn.sendStringList2MLserver(converted, varName);
		  		}
		  		catch (Exception e)
		  		{
		  			throw new ExtensionException( e.getMessage() ) ;
		  		}
	  	  } 
	    
	  }
	  
	  /*
	   * Send a double to be stored as a variable in the Matlab environment
	   */
	  public static class matlabSendDouble extends DefaultCommand
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.commandSyntax(new int[] {Syntax.StringType(), Syntax.NumberType()});
		  }
		  
	  	  public void perform(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
	  		  	double var2send = 0;
		  		try 
		  		{
		  			varName = args[0].getString(); 
		  			var2send = args[1].getDoubleValue();		  			 
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try 
		  		{
		  			mlConn.sendDouble2MLserver(var2send, varName);  
		  	    }
		  	    catch(Exception e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
	  	  } 
	    
	  }
	  
	  /*
	   * Send a list of numbers to be stored as an nx1 vector in Matlab
	   */
	  public static class matlabSendDoubleList extends DefaultCommand
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.commandSyntax(new int[] {Syntax.StringType(), Syntax.ListType()});
		  }
		  
	  	  public void perform(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		    LogoList listFromArgs = null;
	  		  	String varName = "";
		  		try 
		  		{
		  			varName = args[0].getString();
		  			listFromArgs = args[1].getList();		  			  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try 
		  		{
		  			double[] converted = new double[listFromArgs.size()];
		  			for(int i = 0; i < listFromArgs.size(); i++)
		  			{
		  				converted[i] = (Double)listFromArgs.get(i);
		  			}
		  			mlConn.sendDouble2MLserver(converted, varName);  
		  	    }
		  	    catch(Exception e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }			  
	  	  } 
	    
	  }
	  
	  /*
	   * Returns a string stored in the Matlab environment (if it exists)
	   */
	  public static class matlabGetString extends DefaultReporter
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.reporterSyntax(new int[] {Syntax.StringType()}, Syntax.StringType());
		  }
		  
	  	  public Object report(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
		  		try 
		  		{
		  			varName = args[0].getString();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			return mlConn.getStrFromMLserver(varName);
	  	  		}
		  	    catch(Exception e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
	  	  } 	    
	  }
	  
	  /*
	   * Returns a string list stored in the Matlab environment (if it exists)
	   */
	  public static class matlabGetStringList extends DefaultReporter
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.reporterSyntax(new int[] {Syntax.StringType()}, Syntax.ListType());
		  }
		  
	  	  public Object report(Argument args[], Context context)
	  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
		  		try 
		  		{
		  			varName = args[0].getString();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			String[] stringList = mlConn.getStrListFromMLserver(varName);
		  			LogoListBuilder list = new LogoListBuilder(); 
		  			for (int i = 0; i < stringList.length; i++)
		  			{
		  				list.add(stringList[i]);
		  			}
		  			return list.toLogoList();
	  	  		}
		  	    catch(Exception e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
	  	  } 
	    
	  }
	  
	  /*
	   * Returns a double that has been stored in the Matlab environment (if it exists)	  
	   */
	  public static class matlabGetDouble extends DefaultReporter
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.reporterSyntax(new int[] {Syntax.StringType()}, Syntax.NumberType());
		  }
		  
		  public Object report(Argument args[], Context context)
		  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
		  		try 
		  		{
		  			varName = args[0].getString();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			return mlConn.getDoubleFromMLserver(varName);
	  	  		}
		  	    catch(Exception e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
	  	  } 
	    
	  }
	  
	  /*
	   * Returns a double[] (as a LogoList) that is stored in the Matlab environment (if it exists)
	   */
	  public static class matlabGetDoubleList extends DefaultReporter
	  {	 
		  public Syntax getSyntax() 
		  {
			    return Syntax.reporterSyntax(new int[] {Syntax.StringType()}, Syntax.ListType());
		  }
		  
		  public Object report(Argument args[], Context context)
		  	      throws ExtensionException 
	  	  {  
	  		  	String varName = "";
		  		try 
		  		{
		  			varName = args[0].getString();  
		  	    }
		  	    catch(LogoException e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
		  		
		  		try
		  		{
		  			double[] doubleList = mlConn.getDoubleListFromMLserver(varName);
		  			LogoListBuilder list = new LogoListBuilder(); 
		  			for (int i = 0; i < doubleList.length; i++)
		  			{
		  				list.add(Double.valueOf(doubleList[i]));
		  			}
		  			return list.toLogoList();
	  	  		}
		  	    catch(Exception e) 
		  	    {
		  	      throw new ExtensionException( e.getMessage() ) ;
		  	    }
	  	  } 
	    
	  }
 
}