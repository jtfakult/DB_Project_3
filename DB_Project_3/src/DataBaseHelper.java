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

	private Connection connection;

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

			System.out.println(e.getMessage());
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
			System.out.println(e.getMessage());
			System.exit(0);
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

		String query = " SELECT SSN, givenName, surname, address "
				+ " FROM Patients "
				+ " WHERE SSN='" + input + "'";

		try
		{
			ResultSet rs = makeStatement(query);
			
			if (!rs.next())
			{
				System.out.println("Result was empty");
				return;
			}
			else
			{
				do {
					String SSN = rs.getString("SSN");
					String fName = rs.getString("givenName");
					String lName = rs.getString("surname");
					String address = rs.getString("address");
					if (fName == null) { fName = ""; }
					if (lName == null) { lName = ""; }
					if (address == null) { address = "unknown"; }

					System.out.println("Patient SSN: " + SSN);
					System.out.println("Patient First Name: " + fName);
					System.out.println("Patient Last Name: " + lName);
					System.out.println("Patient Address: " + address);
				} while (rs.next());
			}
			
			rs.close();
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
	}

	private void choice2()
	{
		String input = prompt("Enter Doctor ID: ", Integer.class);

		String query = " SELECT doctorID, givenName, surname, gender "
				+ " FROM Doctors "
				+ " WHERE doctorID='" + input + "'";

		try
		{
			ResultSet rs = makeStatement(query);
			
			if (!rs.next())
			{
				System.out.println("Result was empty");
				return;
			}
			else
			{
				do {
					int ID = rs.getInt("doctorID");
					String fName = rs.getString("givenName");
					String lName = rs.getString("surname");
					String gender = rs.getString("gender");
					
					if (fName == null) { fName = ""; }
					if (lName == null) { lName = ""; }
					if (gender == null) { gender = "-"; }

					System.out.println("Doctor ID: " + ID);
					System.out.println("Doctor First Name: " + fName);
					System.out.println("Doctor Last Name: " + lName);
					System.out.println("Doctor Gender: " + gender);
				} while (rs.next());
			}
			
			rs.close();
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
	}

	private void choice3()
	{
		String input = prompt("Enter Admission Number: ", Integer.class);

		String query = " SELECT SSN, admissionID, admissionDate, totalPayment "
			+ " FROM Admissions JOIN Patients ON Admissions.patientID = Patients.patientID "
			+ " WHERE admissionID = " + input;

		// String query = "SELECT A.admissionID, P.SSN, A.startDate, A.totalPayment\n"
		//			+ "FROM Admissions A, Patients P, Rooms R\n"
		//			+ "WHERE A.patientID=P.patientID AND A.roomNumber=R.roomNumber AND A.admissionID='" + input + "'";

		ResultSet rs = makeStatement(query);

		try
		{
			if (!rs.next())
			{
				System.out.println("Result was empty!\n");
				rs.close();
				return;
			}
			else
			{
				do {
					int admissionNumber = rs.getInt("admissionID");
					String SSN = rs.getString("SSN");
					String stayStartDate = rs.getString("admissionDate");
					double totalPayment = rs.getDouble("totalPayment");
					
					if (SSN == null) SSN = "";

					System.out.println("Admission Number: " + admissionNumber);
					System.out.println("Patient SSN: " + SSN);
					System.out.println("Admission date: " + stayStartDate);
					System.out.println("Total Payment: " + totalPayment);
				} while (rs.next());
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}

		query = "SELECT R.roomNumber, R.FromDate, R.ToDate\n"
				+ "FROM Admissions A, Patients P, Rooms R\n"
				+ "WHERE A.patientSSN=P.SSN AND A.roomNumber=R.roomNumber AND A.admissionNumber='" + input + "'";

		query = " SELECT roomNumber, startTime, endTime FROM RoomStays WHERE admissionID = " + input;


		rs = makeStatement(query);

		System.out.println("Rooms:");
		try
		{
			if (!rs.next())
			{
				System.out.println("No rooms recorded!");
			}
			else
			{
				do
				{
					int roomNumber = rs.getInt("roomNumber");
					String fromDate = rs.getString("startTime");
					String toDate = rs.getString("endTime");
					
					if (toDate == null) { toDate = "[current room]"; }
				
					System.out.println("\tRoomNum: " + roomNumber + "\tFromDate: " + fromDate + "\tToDate: " + toDate);
				} while (rs.next());
				rs.close();
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}

		query = " SELECT DISTINCT doctorID "
			+ " FROM Admissions JOIN Examinations on Admissions.admissionID = Examinations.admissionID "
			+ " WHERE Admissions.admissionID = " + input;

		rs = makeStatement(query);

		System.out.println("Doctors who examined this patient during this admission:");
		try
		{
			if (!rs.next())
			{
				System.out.println("\tNo Doctors recorded!");
			}
			else
			{
				do
				{
					int doctorID = rs.getInt("doctorID");

					System.out.println("\tDoctor ID: " + doctorID);
				} while (rs.next());
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
		
		try
		{
			rs.close();
		}
		catch (SQLException e) {}
	}

	private void choice4()
	{
		String number  = prompt("Enter Admission Number: ", Integer.class);

		String query = " SELECT admissionID FROM Admissions WHERE admissionID = " + number;
		ResultSet rs = makeStatement(query);
		try
		{
			if (!rs.next())
			{
				System.out.println("That admission does not exist.");
				rs.close();
				return;
			}
		}
		catch (SQLException e)
		{
			System.out.println("Error verifying admission.\n");
			e.printStackTrace();
			return;
		}

		String payment = prompt("Enter the new total payment: ", Double.class);

		query = " UPDATE Admissions SET totalPayment = " + payment
			+ " WHERE admissionID =" + number;


		try
		{
			Statement st = connection.createStatement();
			st.executeUpdate(query);

			rs.close();
			st.close();
			
			System.out.println("Payment updated!\n");
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
			choice4();
		}
	}

	private String prompt(String text, Class<?> type)
	{

		String input = "";
		System.out.print(text);
		input = scanner.nextLine();

		while (!valid(input, type))
		{
			System.out.println("Please enter a legal value of type: " + type.getName());
			System.out.print(text);
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
		if (type == Double.class)
		{
			try
			{
				double i = Double.parseDouble(s);
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
			System.err.println("Invalid class: " + type.getName() + "...\nHandling as a String");
			return true;
		}
	}

	private ResultSet makeStatement(String statement)
	{
		try
		{
			Statement st = connection.createStatement();
			ResultSet result = st.executeQuery(statement);

			return result;
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}

		return null;
	}
}
