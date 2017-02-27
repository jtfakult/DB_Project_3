//export CLASSPATH=./:/usr/local/oracle11gr203/product/11.2.0/db_1/jdbc/lib/ojdbc6.jar
//COMPILE WITH: javac -source 1.6 -target 1.6 *.java
//git pull https://github.com/jtfakult/DB_Project_3.git

import java.util.Scanner;

public class Reporting
{
	static String choice = "";
	public static void main(String[] args)
	{
		if (args.length != 2 && args.length != 3)
		{
			System.err.println("Please run the program in the following form:\njava Reporting <username> <password>\nExiting...");
			
			System.exit(0);
		}
		
		Account account = new Account(args[0], args[1]);
		
		DataBaseHelper db = new DataBaseHelper(account);
		
		if (args.length == 4)
		{
			choice = args[2];
		}
		
		if (choice.length() == 0)
		{
			choice = promptChoice();
		}
		
		while (!choice.equals("0"))
		{	
			db.setChoice(choice);
			db.execute();
			choice = promptChoice();
		}
		
		db.close();
		System.out.println("Finishing...");
	}
	
	private static String promptChoice()
	{
		System.out.println("Enter the number of your choice\n");
		System.out.println("0- Exit the program");
		System.out.println("1- Report Patient's Basic Information");
		System.out.println("2- Report Doctor's Basic Information");
		System.out.println("3- Report Admissions Information");
		System.out.println("4- Update Admissions Payment");
		
		Scanner scanner = new Scanner(System.in);
		String c = "-";//scanner.nextLine();
		while (!isValid(c.substring(0, 1)) && !c.equals("0"))
		{
			System.out.print("? ");
			c = scanner.nextLine();
		}
		
		return c.substring(0, 1);
	}
	
	private static boolean isValid(String c)
	{
		if (c.equals("")) return false;
		
		try
		{
			int i = Integer.parseInt(c);
			return i >= 0 && i <= 4;
		}
		catch (NumberFormatException e)
		{
			
		}
		
		return false;
	}
	
	/*private static void connectToDB()
	{
		
	}*/
}
