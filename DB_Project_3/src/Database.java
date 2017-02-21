import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.SQLException;

public class Database
{
	public static void main(String[] args)
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
            System.out.println("");
            e.printStackTrace();
            return;
        }

        System.out.println("Oracle JDBC Driver Registered Successfully !");


        System.out.println("-------- Step 2: Building a Connection ------");
        Connection connection = null;
        try
        {
            connection = DriverManager.getConnection("jdbc:oracle:thin:@oracle.wpi.edu:1521:orcl", "jtfakult", "JTFAKULT");
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
            System.out.println("Failed to make connection!");
        }
	}
}
