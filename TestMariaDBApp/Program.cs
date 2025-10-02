using System;

class Program
{
    static void Main()
    {
        using var context = new AppDbContext();

        Console.WriteLine("Connection test successful!");
    }
}
