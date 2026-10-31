using System;
using System.IO;
using System.Net;
using System.Diagnostics;
using Microsoft.Win32;

internal static class WpgpInstaller
{
    private const string ScriptUrl = "https://raw.githubusercontent.com/williamkbukowski94/Wpgp-pgp-terminal-tool/main/windows/wpgp.ps1";
    private const string PathKey = @"Environment";
    private const string Gpg4winInstallerUrl = "https://files.gpg4win.org/gpg4win-latest.exe";

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
        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Documents", "Codex", "wpgp");
    }

    private static string FindGpg()
    {
        string path = Environment.GetEnvironmentVariable("Path") ?? "";
        foreach (string entry in path.Split(';'))
        {
            string candidate = Path.Combine(entry.Trim(), "gpg.exe");
            if (File.Exists(candidate)) return candidate;
        }
        string[] known = {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "GnuPG", "bin", "gpg.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "GnuPG", "bin", "gpg.exe")
        };
        foreach (string candidate in known)
            if (File.Exists(candidate)) return candidate;
        return null;
    }

    private static bool AskToInstallGpg4win()
    {
        if (FindGpg() != null)
        {
            Console.WriteLine("GnuPG was found. Skipping Gpg4win installation.");
            return true;
        }

        Console.WriteLine("GnuPG was not found. wpgp needs Gpg4win for PGP operations.");
        Console.WriteLine("The setup can download the official Gpg4win installer and open its interactive setup.");
        Console.Write("Install Gpg4win now? [y/N] ");
        string answer = Console.ReadLine();
        if (!String.Equals(answer, "y", StringComparison.OrdinalIgnoreCase) &&
            !String.Equals(answer, "yes", StringComparison.OrdinalIgnoreCase))
        {
            Console.WriteLine("Gpg4win was skipped. wpgp will install, but PGP actions need GnuPG.");
            return false;
        }

        string installerPath = Path.Combine(Path.GetTempPath(), "gpg4win-setup.exe");
        try
        {
            Console.WriteLine("Downloading Gpg4win from the official Gpg4win site...");
            using (WebClient client = new WebClient())
                client.DownloadFile(Gpg4winInstallerUrl, installerPath);
            Console.WriteLine("Starting Gpg4win's interactive installer. Follow its prompts and approve Windows' UAC prompt if shown.");
            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = installerPath;
            info.UseShellExecute = true;
            using (Process process = Process.Start(info))
                process.WaitForExit();
            if (FindGpg() != null)
            {
                Console.WriteLine("GnuPG is ready.");
                return true;
            }
            Console.WriteLine("Gpg4win setup finished, but gpg.exe was not found. Complete its setup, then rerun this installer.");
            return false;
        }
        catch (Exception ex)
        {
            Console.WriteLine("Gpg4win was not installed: " + ex.Message);
            Console.WriteLine("Continuing with wpgp setup. PGP actions need GnuPG.");
            return false;
        }
        finally
        {
            try { if (File.Exists(installerPath)) File.Delete(installerPath); }
            catch { }
        }
    }

    private static bool Install()
    {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        bool gpgReady = AskToInstallGpg4win();
        byte[] script;
        using (WebClient client = new WebClient())
            script = client.DownloadData(ScriptUrl);
        if (script.Length < 1000)
            throw new InvalidDataException("The downloaded PowerShell file was unexpectedly small.");

        string directory = InstallDirectory();
        Directory.CreateDirectory(directory);
        File.WriteAllBytes(Path.Combine(directory, "wpgp-core.ps1"), script);
        string oldScript = Path.Combine(directory, "wpgp.ps1");
        if (File.Exists(oldScript)) File.Delete(oldScript);
        string launcher = "@echo off\r\npowershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File \"%~dp0wpgp-core.ps1\" %*\r\n";
        File.WriteAllText(Path.Combine(directory, "wpgp.cmd"), launcher);

        using (RegistryKey key = Registry.CurrentUser.OpenSubKey(PathKey, true))
        {
            if (key == null) throw new InvalidOperationException("Could not open the current-user environment settings.");
            string current = (key.GetValue("Path", "", RegistryValueOptions.DoNotExpandEnvironmentNames) ?? "").ToString();
            string legacyDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Codex", "wpgp");
            string[] entries = current.Split(';');
            System.Collections.Generic.List<string> updatedEntries = new System.Collections.Generic.List<string>();
            bool found = false;
            foreach (string entry in entries)
            {
                if (String.Equals(entry.TrimEnd('\\'), directory.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase))
                {
                    if (!found) updatedEntries.Add(directory);
                    found = true;
                    continue;
                }
                if (!String.Equals(legacyDirectory.TrimEnd('\\'), directory.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase) &&
                    String.Equals(entry.TrimEnd('\\'), legacyDirectory.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase))
                    continue;
                if (!String.IsNullOrWhiteSpace(entry)) updatedEntries.Add(entry);
            }
            if (!found) updatedEntries.Add(directory);
            string updated = String.Join(";", updatedEntries.ToArray());
            if (!String.Equals(updated, current, StringComparison.OrdinalIgnoreCase))
                key.SetValue("Path", updated, RegistryValueKind.ExpandString);
        }
        return gpgReady;
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
            Console.WriteLine();
            Console.WriteLine("Configuring Windows for this user:");
            Console.WriteLine("Downloading wpgp from GitHub...");
            bool gpgReady = Install();
            Console.WriteLine();
            Frame("wpgp is now installed.", ConsoleColor.Green);
            Console.WriteLine();
            Console.WriteLine("Open Windows PowerShell and type 'wpgp' in any directory to run it.");
            if (!gpgReady)
                Console.WriteLine("Gpg4win was skipped or not completed; install it later to enable PGP operations.");
            Console.WriteLine("The launcher uses a process-only execution-policy bypass; machine policy is not changed.");
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

