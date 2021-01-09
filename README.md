# AutoBot

This script will fetch the ServiceNow 'New' Incidents for specific assignment queue.<br>
    &emsp; 1. It will keep them In-Progress.<br>
    &emsp; 2. Check the descriptions of each incident and create parallel process for each type of issue.<br>
    &emsp; 3. If Multiple Incidents for same issue it will create parent child reletionship.<br>
    &emsp; 4. or If active incident found then resolve child Incidents by giving parent reference.<br>
    &emsp; 5. It will check Active Incident track in start of the run and update the file if in resolved state.<br>
    &emsp; 6. There are 5 types of issue resolved autmatically for windows servers<br>
        &emsp;&emsp; 1. Availability<br>
        &emsp;&emsp; 2. CPU Utilisation beyond threshold<br>
        &emsp;&emsp; 3. Memory Utilisation beyond threshold<br>
        &emsp;&emsp; 4. Diskspace Utilisation beyond threshold<br>
        &emsp;&emsp; 5. Service stopped<br>
It will check current status of the server for respective issue.<br>
    If false alarm found it will resolve the incident with an appropriate Work-Note and Resolution Note.<br>
    For genuine alarm it will try to reslove, for example start the service remotely for perticular server, <br>
    Delete temp {Specified folders} for disk space issue,<br>
    Kill unncessary processes {Specified processes} if running, etc<br>
    If able to resolve then close the Incident with specific WorkNote,<br>
    Else if unable to resolve then transfer it to second level group.<br>

# Prerequisites

Windows OS - Powershell<br>
ServiceNow - Instance Access with API<br>
Run on Terminal Server - from which infrstructure remotely accessible<br>

# Note

This will execute the script and if scheduled in interval of 5 minutes than entire L0 and L1 task will be automated for ITIL.

# Use

Open Powershell<br>
run "C:\driver.ps1"

# Input
Place folders in proper folder.<br>
    Please set varibles like below and as and when guided by comment through code for each file.<br>
    Set log file path (example) {$logfile = "C:\Test\Logs\txtlog.txt"}<br>
    Set your servicenow Instance (example) {$Instance="InstanceName"}<br>
    Set your servicenow Instance in uri also in place of 'InstanceName'(example) {<br>
    &emsp;     $uri = "https://InstanceName/api/now/table/incident/"+$SysId+""}<br>
    Set your UserName and Password for SNOW Instance (example) {<br>
    &emsp;     $user = "UserName"<br>
    &emsp;     $pass = "Password"}<br>
    Set 1st level assignment group Name which work need to be automated (example) {$AssignGroup="AssignmentgroupName"}<br>
    Set BOT sysId for assigned to (example) {<br>
    &emsp;    "assigned_to`":`"fd318a1bdb0a90508XXXXXXXX",} <br>
    Set 2nd level assignment group ID {As per your SNOW Instance} to which incident needs to be forwarded if need further intervention (example) {<br>
    &emsp;    "assignment_group`":`"XXXXXXX",} <br>
    Set path of the Incident Track (example) {<br>
    &emsp;     $csvfile = "C:\Documents\Inc_Track.csv"}<br>


# Example O/P

Run the Script and watch the magic of BOT. <p>&#128521;</p>

# License
Copyright 2020 Harsh & Sahista

# Contribution
[Harsh Parecha] (https://github.com/TheLastJediCoder)<br>
[Sahista Patel] (https://github.com/Sahista-Patel)<br>
We love contributions, please comment to contribute!

# Code of Conduct
Contributors have adopted the Covenant as its Code of Conduct. Please understand copyright and what actions will not be abided.
