using System;
using System.IO;
using System.Net;
using Microsoft.Win32;

internal static class WpgpInstaller
{
    private const string ScriptUrl = "https://raw.githubusercontent.com/williamkbukowski94/Wpgp-pgp-terminal-tool/main/windows/wpgp.ps1";
    private const string PathKey = @"Environment";

    private static void Frame(string text, ConsoleColor color)
    {
        int width = Math.Max(42, Math.Min(78, Console.WindowWidth - 4));
        string line = new string('=', width);
        Console.ForegroundColor = color;
        Console.WriteLine(line);
        Console.ResetColor();
        Console.WriteLine(text);
        Console.ForegroundColor = color;
        Console.WriteLine(line);
        Console.ResetColor();
    }

    private static string InstallDirectory()
    {
        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Codex", "wpgp");
    }

    private static void Install()
    {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        byte[] script;
        using (WebClient client = new WebClient())
            script = client.DownloadData(ScriptUrl);
        if (script.Length < 1000)
            throw new InvalidDataException("The downloaded PowerShell file was unexpectedly small.");

        string directory = InstallDirectory();
        Directory.CreateDirectory(directory);
        File.WriteAllBytes(Path.Combine(directory, "wpgp.ps1"), script);
        string launcher = "@echo off\r\npowershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File \"%~dp0wpgp.ps1\" %*\r\n";
        File.WriteAllText(Path.Combine(directory, "wpgp.cmd"), launcher);

        using (RegistryKey key = Registry.CurrentUser.OpenSubKey(PathKey, true))
        {
            if (key == null) throw new InvalidOperationException("Could not open the current-user environment settings.");
            string current = (key.GetValue("Path", "", RegistryValueOptions.DoNotExpandEnvironmentNames) ?? "").ToString();
            bool found = false;
            foreach (string entry in current.Split(';'))
                if (String.Equals(entry.TrimEnd('\\'), directory.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase)) found = true;
            if (!found)
            {
                string updated = String.IsNullOrWhiteSpace(current) ? directory : current.TrimEnd(';') + ";" + directory;
                key.SetValue("Path", updated, RegistryValueKind.ExpandString);
            }
        }
    }

    public static int Main()
    {
        Console.Title = "wpgp Windows Installer";
        Console.ForegroundColor = ConsoleColor.White;
        Console.WriteLine();
        Console.WriteLine("  wpgp Windows Installer");
        Console.ResetColor();
        Console.WriteLine("  Downloads the Windows PowerShell app from GitHub and installs it for this user.");
        Console.WriteLine();
        try
        {
            Console.WriteLine("Downloading wpgp from GitHub...");
            Install();
            Console.WriteLine();
            Frame("wpgp is now installed.", ConsoleColor.Green);
            Console.WriteLine();
            Console.WriteLine("Open Windows PowerShell and type 'wpgp' in any directory to run it.");
            Console.WriteLine("GnuPG (Gpg4win) must be installed separately for PGP operations.");
            Console.WriteLine();
            Console.WriteLine("Press any key to exit.");
            Console.ReadKey(true);
            return 0;
        }
        catch (WebException ex)
        {
            Console.Error.WriteLine();
            Frame("wpgp could not be downloaded.", ConsoleColor.Red);
            Console.Error.WriteLine("The GitHub repository must be public for this no-login installer.");
            Console.Error.WriteLine("Download failed: " + ex.Message);
            Console.Error.WriteLine();
            Console.Error.WriteLine("Press any key to exit.");
            Console.ReadKey(true);
            return 2;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine();
            Frame("Installation did not finish.", ConsoleColor.Red);
            Console.Error.WriteLine(ex.Message);
            Console.Error.WriteLine("Press any key to exit.");
            Console.ReadKey(true);
            return 1;
        }
    }
}

