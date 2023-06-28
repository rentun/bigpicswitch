#Commandline Parameters
param ($action)

# Configuration
$configFile = "C:\Users\ken\Scripts\bigpicswitch\settings.json"
$config = Get-Content -Path $configFile | ConvertFrom-Json
$homeAssistantURI = $config.homeAssistantURI
$accessToken = $config.accesstoken
$multimonitortoolPath = $config.multimonitortoolPath
$tvMonitorConfig = $config.tvMonitorConfig
$desktopMonitorConfig = $config.desktopMonitorConfig
$PCsource = $config.PCsource

$global:retries = $config.retries
$global:entityID = $config.entityID
$global:turnOffURI = "/api/services/media_player/turn_off"
$global:turnOnURI = "/api/services/media_player/turn_on"
$global:switchInputURI = "/api/services/media_player/select_source"
$global:checkStateURI = "/api/states/$entityID"
$global:header = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
# Function to send a command to Home Assistant
function SendHomeAssistantCommand{
    param(
        [Parameter(Mandatory=$true)][string]$uri, 
        [Parameter(Mandatory=$true)][string]$method, 
        [Parameter(Mandatory=$true)][hashtable]$header, 
        [hashtable]$body)
    $fullURI = $homeAssistantURI + $uri
    try {
        if($body){
            $bodyJSON = $body | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $fullURI -Method $method -Headers $header -body $bodyJSON
        }else{
            $response = Invoke-RestMethod -Uri $fullURI -Method $method -Headers $header 
        }
    }
    catch {
        Write-Output "Error: $response"
    }
    return $response
}
function checkState{
    $method = "GET"
    $response = SendHomeAssistantCommand -uri $checkStateURI -method $method -header $header
    return $response.state
}
function switchInput{
    param($source)
    $method = "POST"
    $body = @{
            "entity_id" = $entityID
            "source" = $source
        }
    SendHomeAssistantCommand -uri $switchInputURI -method $method -header $header -body $body
}
function turnOn{
    $method = "POST"
    $body = @{
            "entity_id" = $entityID
        }
    $counter = 0
    $state = checkState
    if($counter -lt $retries){
        while($state -eq "off"){
            SendHomeAssistantCommand -uri $turnOnURI -method $method -header $header -body $body
            Start-Sleep -Seconds 5
            $counter++
            $state = checkState
        }
    }
}
function turnOff{
    $method = "POST"
    $body = @{
            "entity_id" = $entityID
        }
    $counter = 0
    $state = checkState
    if($counter -lt $retries){
        while($state -eq "on"){
            SendHomeAssistantCommand -uri $turnOffURI -method $method -header $header -body $body
            Start-Sleep -Seconds 5
            $counter++
            $state = checkState
        }
    }
}

function bigpicture{
    # Change Windows 11 monitor configuration
    Start-Process -FilePath $multimonitortoolPath -ArgumentList "/loadconfig", $tvMonitorConfig
    #Turn on Samsung Q90 TV
    turnOn
    # Switch Samsung Q90 TV input to HDMI
    switchInput -source $PCsource
    Start-Sleep -Seconds 1
    # Launch Steam Big Picture Mode
    Start-Process -FilePath "steam://open/bigpicture" -Wait
}
function desktop{
    # Exit Steam Big Picture Mode
    Start-Process -FilePath "steam://close/bigpicture" -Wait
    # Change Windows 11 monitor configuration
    Start-Process -FilePath $multimonitortoolPath -ArgumentList "/loadconfig", $desktopMonitorConfig
    # Turn off Samsung Q90 TV
    turnOff

}
if($action -eq "bigpicture"){
    bigpicture
}
 
if($action -eq "desktop"){
    desktop
}  