Import-Module $env:ProgramFiles\PSScripts\Toast_Notifications.psm1
if ($null -eq (Get-Module AudioDeviceCmdlets)) {
  Install-Module -Name AudioDeviceCmdlets 
}
Import-Module AudioDeviceCmdlets

$PU  = '0x21'##Page UP
#$PD = '0x22'##Page DOWN
$END = '0x23'##END
$CTRL = '0x11'##Ctrl
$DeviceList = Get-AudioDevice -List | Where-Object {$_.Type -eq "Playback"}
$CurrentDevice = (Get-AudioDevice -playback).Index
$NewDevice = $CurrentDevice
$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi

do
{   
  if([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($PU) -eq -32767 -and [PsOneApi.Keyboard]::GetAsyncKeyState($CTRL) -eq -32767)){ 
    $NewDevice++
    if ($NewDevice -gt $DeviceList.count) {
      $NewDevice = 1
    }
    Set-AudioDevice -index $NewDevice -ErrorAction Continue
    (Get-audiodevice -playback).Name | Show-Notification -ToastTitle "Dispositivo de salida:" #-ToastText "<Salida1>"
  }
  <#elseif ([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($PD) -eq -32767 -and [PsOneApi.Keyboard]::GetAsyncKeyState($CTRL) -eq -32767)) {
    Show-Notification -ToastTitle "Dispositivo de salida:" -ToastText "<Salida2>"
  }#>
  elseif ([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($END) -eq -32767 -and [PsOneApi.Keyboard]::GetAsyncKeyState($CTRL) -eq -32767)) {
    Show-Notification -ToastTitle "Adiosin" -ToastText ":'("
    Exit 0
  }   
  Start-Sleep -Milliseconds 10
} while($true) 