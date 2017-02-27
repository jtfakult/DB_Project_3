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
		else if (args.length == 2)
		{
			System.out.println("1- Report Patient's Basic Information\n2- Report Doctor's Basic Information\n3- Report Admissions Information\n4- Update Admissions Payment");
			return;
		}
		// args.length == 3
		choice = args[2];
		if (!choice.equals("1") && !choice.equals("2") && !choice.equals("3") && !choice.equals("4") && !choice.equals("i"))
		{
			System.out.println("Invalid argument.");
			return;
		}

		Account account = new Account(args[0], args[1]);
		DataBaseHelper db = new DataBaseHelper(account);

		if (!choice.equals("i"))
		{
			db.setChoice(choice);
			db.execute();
			db.close();
			return;
		}

		// Interactive mode

		while (!choice.equals("0"))
		{
			db.setChoice(choice);
			db.execute();
			choice = promptChoice();
		}

		db.close();
		System.out.println("Exiting...");
	}

	private static String promptChoice()
	{
		System.out.println("Enter the number of your choice\n0- Exit the program\n1- Report Patient's Basic Information\n2- Report Doctor's Basic Information\n3- Report Admissions Information\n4- Update Admissions Payment");

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
