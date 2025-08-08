################################################################################################################ 
# This tool allows for windows native toast notification popups to occur when matching a condition read in the client.txt file for pathofexile 1.
# As it only reads the client file it does not break the TOS.

# instructions: save this file as yourfilename.ps1, right click and run in powershell.
# you may need to disable windows DND settings for it to work in-game
# Settings > System > Focus Assist > Automatic Rules/When I'm Playing a Game - set to off.

################################################################################################################ 
#Configurable file paths
# Path to Client.txt
$clientLogPath = 'C:\Program Files (x86)\Steam\steamapps\common\Path of Exile\logs\Client.txt'  

# Folder containing sound files (no trailing backslash).  Sound files must be .wav and should be under 3 seconds.
$defaultSoundFolder = "C:\Sounds"  

# Use Windows default sound if no file is specified or found
$defaultSystemSoundFallback = $true  

################################################################################################################ 
# Define match patterns, messages, and optional sound filenames
# if you want to use a custom sound file just add the filename.wav in the relevant section, otherwise windows default notification if blank.

$conditions = @(

## to test if this works on your machine, remove the # from the next line and type "test" into your local chat.  don't forget to re-add the # when done.
#    @{ Pattern = 'test'; Title = 'TEST POPUP MESSAGE'; Message = 'Your notifications are working!'; SoundFile = "test.wav" },

    @{ Pattern = 'Spawning discoverable Hideout'; Title = 'HIDEOUT FOUND'; Message = 'A Hideout is in this map!'; SoundFile = "" },
    @{ Pattern = 'A Reflecting Mist has manifested nearby'; Title = 'REFLECTING MIST'; Message = 'Reflecting Mist has Spawned!'; SoundFile = "" },
    @{ Pattern = 'The Nameless Seer has appeared nearby'; Title = 'NAMELESS SEER'; Message = 'Nameless Seer has Spawned'; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: You there! A moment of your time?'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: Go on, Exile - approach the tear.'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: What are you doing? Approach the tear!'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: Here, Exile! Another tear!'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = "Eagon Caeserius: Over here, don't dally!"; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: Here, Exile! Another tear!'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: Exile, we have yet to unravel this one!'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" },
    @{ Pattern = 'Eagon Caeserius: Look, Exile - a fresh tear!'; Title = 'EAGON TEAR FOUND'; Message = 'A Tear has been found' ; SoundFile = "" }
)

################################################################################################################ 
#Actual code bit:

#show notification when you get a match:

function Show-Notification {
    [CmdletBinding()]
    Param (
        [string] $ToastTitle,
        [string] $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $rawXml = [xml] $template.GetXml()
    ($rawXml.toast.visual.binding.text | Where-Object {$_.id -eq "1"}).AppendChild($rawXml.CreateTextNode($ToastTitle)) > $null
    ($rawXml.toast.visual.binding.text | Where-Object {$_.id -eq "2"}).AppendChild($rawXml.CreateTextNode($ToastText)) > $null

    $serializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $serializedXml.LoadXml($rawXml.OuterXml)

    $toast = [Windows.UI.Notifications.ToastNotification]::new($serializedXml)
    $toast.Tag = "PowerShell"
    $toast.Group = "PowerShell"
    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $notifier.Show($toast)
}

#Plays the sound (defaults to windows default sounds if none specified or found)

function Play-Sound {
    param (
        [string] $filename
    )

    $fullPath = if ($filename) { Join-Path -Path $defaultSoundFolder -ChildPath $filename } else { "" }

    if ($fullPath -and (Test-Path $fullPath)) {
        Add-Type -AssemblyName presentationcore
        $player = New-Object System.Media.SoundPlayer $fullPath
        $player.Play()
    } elseif ($defaultSystemSoundFallback) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Media.SystemSounds]::Exclamation.Play()
    }
}

################################################################################################################ 

# Monitor log file and show notification/play sound when conditions are met:

Get-Content $clientLogPath -Tail 1 -Wait | ForEach-Object {
    foreach ($condition in $conditions) {
        if ($_ -match $condition.Pattern) {
            Show-Notification -ToastTitle $condition.Title -ToastText $condition.Message
            Play-Sound -filename $condition.SoundFile
            Write-Host $_
            break
        }
    }
}
