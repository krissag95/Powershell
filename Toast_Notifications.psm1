If ($PSVersionTable.PSVersion.Major -lt 6)
{
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
}
else
{
    # Check for the NuGet package provider and install it if necessary
    if ($null -eq (Get-PackageProvider -Name NuGet))
    {
        try
        {
            $null = Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop
        }
        catch
        {
            throw $_.Exception.Message
        }
    }
    # Check for the Microsoft.Windows.SDK.NET.Ref NuGet package and install it if necessary
    If ($null -eq (Get-Package -ProviderName NuGet -Name Microsoft.Windows.SDK.NET.Ref -AllVersions -ErrorAction SilentlyContinue))
    {
        try
        {
            $null = Install-Package -Name Microsoft.Windows.SDK.NET.Ref -ProviderName NuGet -Force -Scope CurrentUser -ErrorAction Stop
        }
        catch
        {
            throw $_.Exception.Message
        }
    }
    # Get the latest version of the WinRT.Runtime.dll and Microsoft.Windows.SDK.NET.dll files
    $WinRTRuntime = Get-ChildItem -Path "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\Microsoft.Windows.SDK.NET.Ref.*" -Filter "WinRT.Runtime.dll" -Recurse -ErrorAction SilentlyContinue |
    Sort-Object -Property VersionInfo.FileVersion -Desc | Select-Object -ExpandProperty FullName | Select-Object -First 1
    $WinSDKNet = Get-ChildItem -Path "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\Microsoft.Windows.SDK.NET.Ref.*" -Filter "Microsoft.Windows.SDK.NET.dll" -Recurse -ErrorAction SilentlyContinue |
    Sort-Object -Property VersionInfo.FileVersion -Desc | Select-Object -ExpandProperty FullName | Select-Object -First 1
    # Load the WinRT.Runtime.dll and Microsoft.Windows.SDK.NET.dll files
    Add-Type -Path $WinRTRuntime -ErrorAction Stop
    Add-Type -Path $WinSDKNet -ErrorAction Stop
}

function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )

    #[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|Where-Object {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text|Where-Object {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "Powershell"
    $Toast.Group = "Powershell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}

#Show-Notification -ToastTitle "Dispositivo de salida:" -ToastText "<Salida>"