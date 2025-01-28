if ($null -eq (Get-Module AudioDeviceCmdlets)) {
  Install-Module -Name AudioDeviceCmdlets 
}
if ($null -eq (Get-Module BurntToast)) {
  Install-Module -Name BurntToast -AllowPrerelease
}
Import-Module AudioDeviceCmdlets
Import-Module BurntToast

$PU  = '0x21'##Page UP
$PD = '0x22'##Page DOWN
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

$ToastBuilder = New-BTContentBuilder 
Add-BTText -ContentBuilder $ToastBuilder -Text 'Heading', 'Body' -Bindable
Add-BTDataBinding -ContentBuilder $ToastBuilder -Key 'Heading' -Value "Dispositivo de salida:"
Add-BTDataBinding -ContentBuilder $ToastBuilder -Key 'Body' -Value (Get-audiodevice -playback).Name 
Show-BTNotification -ContentBuilder $ToastBuilder

do
{   
  if([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($PU) -eq -32767 -and [PsOneApi.Keyboard]::GetAsyncKeyState($CTRL) -eq -32767)){ 
    $NewDevice++
    if ($NewDevice -gt $DeviceList.count) {
      $NewDevice = 1
    }
    Set-AudioDevice -index $NewDevice -ErrorAction Continue 
    Add-BTDataBinding -ContentBuilder $ToastBuilder -Key 'Body' -Value (Get-audiodevice -playback).Name 
    Show-BTNotification -ContentBuilder $ToastBuilder
  }
  elseif ([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($PD) -eq -32767 -and [PsOneApi.Keyboard]::GetAsyncKeyState($CTRL) -eq -32767)) {
    $NewDevice--
    if ($NewDevice -lt 1) {
      $NewDevice = $DeviceList.count
    }
    Set-AudioDevice -index $NewDevice -ErrorAction Continue
    Add-BTDataBinding -ContentBuilder $ToastBuilder -Key 'Body' -Value (Get-audiodevice -playback).Name 
    Show-BTNotification -ContentBuilder $ToastBuilder
  }
  elseif ([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($END) -eq -32767 -and [PsOneApi.Keyboard]::GetAsyncKeyState($CTRL) -eq -32767)) {
    Add-BTDataBinding -ContentBuilder $ToastBuilder -Key 'Heading' -Value "Adiosin"
    Add-BTDataBinding -ContentBuilder $ToastBuilder -Key 'Body' -Value ":'("
    Show-BTNotification -ContentBuilder $ToastBuilder 
    Exit 0
  }   
  Start-Sleep -Milliseconds 10
} while($true) 