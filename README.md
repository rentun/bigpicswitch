# BigPicSwitch
This is a very personalized script to switch my display configuration over to my TV and launch steam big picture so I can play games on my couch without having to manually change a bunch of settings.
## Install
run 
```bigpicswitch.ps1```
### Dependancies
* A samsung TV (I use a Q90A)
* A homeassistant server running https://github.com/ollo69/ha-samsungtv-smart
* A locally installed copy of multimonitor tool https://www.nirsoft.net/utils/multi_monitor_tool.html
* Steam
## Background
I use a Samsung TV in my living room to play games on, but switching it on, switching to the correct input, changing my monitor configuration, and launching big picture mode is always so much of a hassle that I almost never use it to play games on and instead just sit at my monitor. This script is an attempt to fix that.
## Usage
This script is called with the commandline parameter -action <action> where <action> is either "desktop" or "bigpicture". The script will then use the homeassistant REST API, multimonitortool.exe, and the Steam browser protocol to switch the TV on, turn to the correct input, change the monitor configuration to the correct one, and launch/close steam big picture mode.
`powershell bigpicswitch.ps1 -action bigpicture` launch big picture mode
`powershell bigpicswitch.ps1 -action desktop` launch big desktop mode
