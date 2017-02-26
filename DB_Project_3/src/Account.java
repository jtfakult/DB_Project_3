
public class Account
{
	private String username;
	private String password;
	
	public Account(String user, String pass)
	{
		username = user;
		password = pass;
	}
	
	public String getUsername()
	{
		return username;
	}
	
	String getPassword() //Package private because why not
	{
		return password;
	}
}
