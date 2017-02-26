import java.sql.Array;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Scanner;

public class DataBaseHelper
{
	private String choice = "";
	private Account account;
	private Scanner scanner;
	
	Connection connection;
	
	public DataBaseHelper(Account a)
	{
		account = a;
		scanner = new Scanner(System.in);
		
		connect();
	}
	
	public void setChoice(String newChoice)
	{
		choice = newChoice;
	}
	
	private void connect()
	{
		System.out.println("-------- Oracle JDBC Connection Testing ------");
        System.out.println("-------- Step 1: Registering Oracle Driver ------");
        try
        {
        	Class.forName("oracle.jdbc.driver.OracleDriver");
        }
        catch (ClassNotFoundException e)
        {
            System.out.println("Where is your Oracle JDBC Driver? Did you follow the execution steps. ");
            System.out.println("");
            System.out.println("*****Open the file and read the comments in the beginning of the file****");
            System.out.println("Run: export CLASSPATH=./:/usr/local/oracle11gr203/product/11.2.0/db_1/jdbc/lib/ojdbc6.jar");
            System.out.println("");
            e.printStackTrace();
            System.exit(0);
        }

        System.out.println("Oracle JDBC Driver Registered Successfully !");


        System.out.println("-------- Step 2: Building a Connection ------");
        connection = null;
        try
        {
            connection = DriverManager.getConnection("jdbc:oracle:thin:@oracle.wpi.edu:1521:orcl", account.getUsername(), account.getPassword());
        }
        catch (SQLException e)
        {
            System.out.println("Connection Failed! Check output console");
            e.printStackTrace();
            return;
        }

        if (connection != null)
        {
            System.out.println("You made it. Connection is successful. Take control of your database now!");
        }
        else
        {
            System.err.println("Failed to make connection!");
            System.exit(0);
        }
	}
	
	public void close()
	{
		try
		{
			connection.close();
		}
		catch (Exception e) { }
	}
	
	private void choice1()
	{
		String input = prompt("Enter Patient SSN: ", String.class);
		
		String query = "SELECT SSN, givenName, surname, address"
				+ "FROM Patient"
				+ "WHERE SSN='" + input + "'";
		
		ResultSet rs = makeStatement(query);
		if (rs == null)
		{
			System.out.println("Result was empty");
			return;
		}
		
		try
		{
			while (rs.next())
			{
				String SSN = rs.getString(0);
				String fName = rs.getString(1);
				String lName = rs.getString(2);
				String address = rs.getString(3);
				
				System.out.println("Patient SSN: " + SSN);
				System.out.println("Patient First Name: " + fName);
				System.out.println("Patient Last Name: " + lName);
				System.out.println("Patient Address: " + address);
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
	}
	
	private void choice2()
	{
		String input = prompt("Enter Doctor ID: ", Integer.class);
		
		String query = "SELECT ID, givenName, surname, gender"
				+ "FROM Doctor"
				+ "WHERE ID='" + input + "'";
		
		ResultSet rs = makeStatement(query);
		if (rs == null)
		{
			System.out.println("Result was empty");
			return;
		}
		
		try
		{
			while (rs.next())
			{
				int ID = rs.getInt(0);
				String fName = rs.getString(1);
				String lName = rs.getString(2);
				String gender = rs.getString(3);
				
				System.out.println("Doctor ID: " + ID);
				System.out.println("Doctor First Name: " + fName);
				System.out.println("Doctor Last Name: " + lName);
				System.out.println("Doctor Gender: " + gender);
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
	}

	private void choice3()
	{
		String input = prompt("Enter Admission Number: ", Integer.class);
		
		String query = "SELECT A.admissionNumber, P.SSN, A.startDate, A.totalPayment"
				+ "FROM Admission A, Patient P, Room R"
				+ "WHERE A.patientSSN=P.SSN AND A.roomNumber=R.roomNumber AND A.admissionNumber='" + input + "'";
		
		ResultSet rs = makeStatement(query);
		if (rs == null)
		{
			System.out.println("Result was empty");
			return;
		}
		
		try
		{
			while (rs.next())
			{
				int admissionNumber = rs.getInt(0);
				String SSN = rs.getString(1);
				String stayStartDate = rs.getString(2);
				String stayEndDate = rs.getString(3);
				double totalPayment = rs.getDouble(4);
				
				System.out.println("Admission Number: " + admissionNumber);
				System.out.println("Patient SSN: " + SSN);
				System.out.println("Admission date: " + stayStartDate);
				System.out.println("Total Payment: " + totalPayment);
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
		
		query = "SELECT R.roomNumber, R.FromDate, R.ToDate"
				+ "FROM Admission A, Patient P, Room R"
				+ "WHERE A.patientSSN=P.SSN AND A.roomNumber=R.roomNumber AND A.admissionNumber='" + input + "'";
		
		rs = makeStatement(query);
		if (rs == null)
		{
			System.out.println("Result was empty");
			return;
		}
		
		try
		{
			System.out.println("Rooms:");
			while (rs.next())
			{
				int roomNumber = rs.getInt(0);
				String fromDate = rs.getString(1);
				String toDate = rs.getString(2);
				
				System.out.println("RoomNum: " + roomNumber + "\tFromDate: " + fromDate + "\tToDate: " + toDate);
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
		
		query = "SELECT D.doctorID"
				+ "FROM Admission A, Patient P, Doctor D"
				+ "WHERE A.patientSSN=P.SSN AND A.doctorID=D.doctorID AND A.admissionNumber='" + input + "'";
		
		rs = makeStatement(query);
		if (rs == null)
		{
			System.out.println("Result was empty");
			return;
		}
		
		try
		{
			System.out.println("Doctors who Examined this patient during this admission:");
			while (rs.next())
			{
				int doctorID = rs.getInt(0);
				
				System.out.println("Doctor ID: " + doctorID);
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
	}
	
	public void execute()
	{
		if (choice.equals("1"))
		{
			choice1();
		}
		else if (choice.equals("2"))
		{
			choice2();
		}
		else if (choice.equals("3"))
		{
			choice3();
		}
		else if (choice.equals("4"))
		{
			System.out.println("No choice 4 yet");
			//choice4();
		}
	}
	
	private String prompt(String text, Class<?> type)
	{
		
		String input = "";
		System.out.println(text);
		input = scanner.nextLine();
		
		while (!valid(input, type))
		{
			System.out.println("Please enter a legal value of type: " + type.getName());
			System.out.println(text);
			input = scanner.nextLine();
		}
		
		return input;
	}
	
	private boolean valid(String s, Class<?> type)
	{
		if (s.length() == 0) return false;
		
		if (type == Integer.class)
		{
			try
			{
				int i = Integer.parseInt(s);
				return true;
			}
			catch (NumberFormatException e)
			{
				return false;
			}
		}
		else if (type == String.class)
		{
			return true;
		}
		else
		{
			System.err.println("Invalud class: " + type.getName() + "...\nHandling as a String");
			return true;
		}
	}
	
	private ResultSet makeStatement(String statement)
	{
		try
        {
        	Statement st = connection.createStatement(); 
        	ResultSet result = 	st.executeQuery(statement);
        	
        	while (result.next())
        	{
        		System.out.println("Got employee: " + result.getString("name"));
        	}
        	
        	result.close();
        	
        	st.close();
        	
        	connection.close();
        	
        	return result;
        }
        catch (SQLException e)
        {
        	e.printStackTrace();
        }
		
		return null;
	}
}
