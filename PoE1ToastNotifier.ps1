#This tool allows for windows native toast notification popups to occur when matching a condition read in the client.txt file for pathofexile 1.
# As it only reads the client file it does not break the TOS.

# instructions: save this file as yourfilename.ps1, right click and run in powershell.
# you may need to disable windows DND settings for it to work in-game
# Settings > System > Focus Assist > Automatic Rules/When I'm Playing a Game - set to off.


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

# Define match patterns and corresponding messages
$conditions = @(
## to test if this works on your machine, remove the # from the next line and type "test" into your local chat.  don't forget to re-add the # when done.
#    @{ Pattern = 'test'; Title = 'TEST POPUP MESSAGE'; Message = 'Your notifications are working!' },
    @{ Pattern = 'Spawning discoverable Hideout'; Title = 'HIDEOUT FOUND'; Message = 'A Hideout is in this map!' },
    @{ Pattern = 'A Reflecting Mist has manifested nearby'; Title = 'REFLECTING MIST'; Message = 'Reflecting Mist has Spawned!' },
    @{ Pattern = 'The Nameless Seer has appeared nearby'; Title = 'NAMELESS SEER'; Message = 'Nameless Seer has Spawned' }
    # Add more conditions here, make sure to add a comma to the end of the previous line but not the last one.
    # To remove a condition, comment out with a # before the line.
)

# Monitor log file - change below to suit your location.

Get-Content 'C:\Program Files (x86)\Steam\steamapps\common\Path of Exile\logs\Client.txt' -Tail 1 -Wait | ForEach-Object {
    foreach ($condition in $conditions) {
        if ($_ -match $condition.Pattern) {
            Show-Notification -ToastTitle $condition.Title -ToastText $condition.Message
            Write-Host $_
            break
        }
    }
}
