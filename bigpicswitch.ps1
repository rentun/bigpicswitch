#Commandline Parameters
param ($action)

# Configuration
$configFile = Get-Content -Path settings.json | ConvertFrom-Json
$homeAssistantURI = $configFile.homeAssistantURI
$accessToken = $configFile.accesstoken
$multimonitortoolPath = $configFile.multimonitortoolPath
$retries = $configFile.retries
$global:retrycounter = 0

# Function to send a command to Home Assistant
function SendHomeAssistantCommand{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$command,

        [Parameter(Mandatory=$false)]
        [string]$source
    )


    $turnOffURI = "/api/services/media_player/turn_off"
    $turnOnURI = "/api/services/media_player/turn_on"
    $switchInputURI = "/api/services/media_player/select_source"
    $checkStateURI = "/api/states/media_player.samsung_tv_2"
    if($retryCounter -gt $retries){return "Retries Exceeded, exiting"}
 
    if($command -eq "turnoff"){
        $method = "POST"
        $apipath = $turnOffURI
    }
    if($command -eq "turnon"){
        $method = "POST"
        $apipath = $turnOnURI
    }
    
    if($command -eq "checkstate"){
        $method = "GET"
        $apipath = $checkStateURI
    } elseif($command -eq "switchinput"){
        $method = "POST"
        $apipath = $switchInputURI
        $data = @{
            "entity_id" = "media_player.samsung_tv_2"
            "source" = $source
        }
    } else{
        $data = @{
            "entity_id" = "media_player.samsung_tv_2"
        }
    }

    
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $body = $data | ConvertTo-Json
    
    $fullURI = $homeAssistantURI + $apipath
    Write-Host "Sending $fullURI with $headers and $body using $method"
    if($command -eq "switchinput"){
        Invoke-RestMethod -Uri $fullURI -Method $method -Headers $headers -Body $body
    }
    if($command -eq "checkstate"){
        return Invoke-RestMethod -Uri $fullURI -Method $method -Headers $headers
    }
    if($command -eq "turnon"){
        $response = SendHomeAssistantCommand -command "checkState"
        Write-Host "command is turn on. Checking state: TV says it is $($response.state)"
        if($response.state -eq "off"){
            Write-Host "TV is off. resending turn on command then waiting to recheck "
            Invoke-RestMethod -Uri $fullURI -Method $method -Headers $headers -Body $body
            Start-Sleep -Seconds 5
            $retryCounter++
            SendHomeAssistantCommand -command "turnon"
            Start-Sleep -Seconds 5
            
        }
    }
    if($command -eq "turnoff"){
        $response = SendHomeAssistantCommand -command "checkState"
        Write-Host "command is turn off. Checking state: TV says it is $($response.state)"
        if($response.state -eq "on"){
            Write-Host "TV is on. resending turn on command then waiting to recheck"
            Invoke-RestMethod -Uri $fullURI -Method $method -Headers $headers -Body $body
            Start-Sleep -Seconds 5
            $retryCounter++
            SendHomeAssistantCommand -command "turnoff"
        }
    }
}


if($action -eq "bigpicture"){
    # Turn on Samsung Q90 TV
    SendHomeAssistantCommand -command "turnon"
    # Switch Samsung Q90 TV input to HDMI
    SendHomeAssistantCommand -source "PC" -command "switchinput"
    # Change Windows 11 monitor configuration
    Start-Process -FilePath $multimonitortoolPath -ArgumentList "/loadconfig", "C:\Users\ken\Documents\MonitorConfigs\ExtendtoTV.cfg"
    Start-Sleep -Seconds 2
    # Launch Steam Big Picture Mode
    Start-Process -FilePath "steam://open/bigpicture" -Wait
}
if($action -eq "desktop"){
    # Exit Steam Big Picture Mode
Start-Process -FilePath "steam://close/bigpicture" -Wait
# Change Windows 11 monitor configuration
Start-Process -FilePath $multimonitortoolPath -ArgumentList "/loadconfig", "C:\Users\ken\Documents\MonitorConfigs\desktoponly.cfg"
# Switch Samsung Q90 TV input to HDMI
SendHomeAssistantCommand -command "switchinput" -source "AVR_X2700H"
# Turn off Samsung Q90 TV
SendHomeAssistantCommand -command "turnoff"
    }