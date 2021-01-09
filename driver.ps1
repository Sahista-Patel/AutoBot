<#
.SYNOPSIS
    This script will fetch the ServiceNow 'New' Incidents for specific assignment queue.
    1. It will keep them In-Progress.
    2. Check the descriptions of each incident and create parallel process for each type of issue.
    3. If Multiple Incidents for same issue it will create parent child reletionship or if active incident found then resolve child Incidents by giving parent reference.
    4. It will check Active Incident track in start of the run and update the file if in resolved state.
    5. There are 5 types of issue resolved autmatically for windows servers
        1. Availability
        2. CPU Utilisation beyond threshold
        3. Memory Utilisation beyond threshold
        4. Diskspace Utilisation beyond threshold
        5. Service stopped

.DESCRIPTION
    It will check current status of the server for respective issue.
    If false alarm found it will resolve the incident with an appropriate Work-Note and Resolution Note.
    For genuine alarm it will try to reslove, for example start the service remotely for perticular server, 
    Delete temp [Specified folders] for disk space issue,
    Kill unncessary processes [Specified processes] if running, etc
    If able to resolve then close the Incident with specific WorkNote,
    Else if unable to resolve then transfer it to second level group.

.INPUTS
    Place folders in proper folder.
    Please set varibles like below and as and when guided by comment through code for each file.
    Set log file path (example) {$logfile = "C:\Test\Logs\txtlog.txt"}
    Set your servicenow Instance (example) {$Instance="InstanceName"}
    Set your servicenow Instance in uri also in place of 'InstanceName'(example) {
        $uri = "https://InstanceName/api/now/table/incident/"+$SysId+""}
    Set your UserName and Password for SNOW Instance (example) {
        $user = "UserName"
        $pass = "Password"}
    Set 1st level assignment group Name which work need to be automated (example) {$AssignGroup="AssignmentgroupName"} 
    Set BOT sysId for assigned to (example) {
       ``"assigned_to`":`"fd318a1bdb0a90508XXXXXXXX`",} 
    Set 2nd level assignment group ID [As per your SNOW Instance] to which incident needs to be forwarded if need further intervention (example) {
       `"assignment_group`":`"XXXXXXX`",} 
    Set path of the Incident Track (example) {
        ﻿$csvfile = "C:\Documents\Inc_Track.csv"}

.EXAMPLE
    .\driver.ps1

.NOTES
    This will execute the script and if scheduled in interval of 5 minutes than entire L0 and L1 task will be automated for ITIL.

.AUTHOR
    Harsh Parecha
    Sahista Patel
#>

$csvfile = "C:\Documents\Inc_Track.csv"
$logfile = "C:\Test\Logs\txtlog.txt"

$obj = @()
$csvchldcount = 0
Remove-Job -state Completed

#// Set Instance 
$Instance="InstanceName"
$InstanceName = "https://"+$Instance+".service-now.com/" 


 
#// Create SN REST API credentials 
$SNowUser = "UserName" 
$SNowPass = "Password" | ConvertTo-SecureString -asPlainText -Force 
$SNowCreds = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $SNowUser, $SNowPass 


$AssignGroup="AssignmentgroupName"


#// Get all incidents Assigned To 
#$URI = $InstanceName+"api/now/table/incident?sysparm_query=assignment_group.name="+$AssignGroup+"^incident_state=1^ORincident_state=2^ORincident_state=3^ORincident_state=4^ORincident_state=5^ORincident_state=10" 
$URI = $InstanceName+"api/now/table/incident?sysparm_query=assignment_group.name="+$AssignGroup+"^incident_state=1" 
$Requests = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method GET -ContentType "application/json" 
 
#$Requests.result
$URI = ""
#In-Progress putting
$($Requests.result).length
if($($Requests.result).length -ne 0){
Write-Host "Keeping In-Progress"
$logcontent = (Get-Date).ToString() + " Incident list fetched and keeping them In-Progress`r`n"
Add-Content $logfile $logcontent
foreach ($Incident1 in $Requests.result) { 
    
    $SysId = $Incident1.sys_id.ToString()
    

    ##########################################Edit worknote
    # Eg. User name="UserName", Password="Password" for this code sample.
    $user = "UserName"
    $pass = "Password"

    # Build auth header
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))


    # Set proper headers
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))
    $headers.Add('Accept','application/json')
    $headers.Add('Content-Type','application/json')
    # Specify endpoint uri
    $uri = "https://InstanceName/api/now/table/incident/"+$SysId+""

    # Specify HTTP method
    $method = "patch"

                # Specify request body.....Specify BOT ID for assigned to
                $body = "{
                            `"work_notes`":`"Working On it.`",  
                            `"incident_state`":`"2`",
                            `"assigned_to`":`"fd318a1bdb0a90508XXXXXXXX`"
                            }"
     
    # Send HTTP request
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body

    # Print response
    $response.RawContent 
    ############################################################
    Write-Host "Kept In-Progress" + $Incident1.number
   $logcontent = (Get-Date).ToString() + " Kept In-Progress: " + $Incident1.number + "`r`n"
    Add-Content $logfile $logcontent

} 






foreach ($Incident1 in $Requests.result) {
    #$Parentflag = 0 
    $csvchldcount = 0
    $csvnum = $Incident1.number
    ##Write-Host "Number: " + $csvnum
    $csvincsysid = $Incident1.sys_id
    $csvpri = $Incident1.priority
    ##Write-Host "Priority: " + $csvpri
    $csvci = $Incident1.cmdb_ci.value
    ##Write-Host "Cmdb CI: " + $csvci
    $csvdec = $Incident1.short_description
    ##Write-Host "Description: " + $csvdec
    $SysId = $Incident1.sys_id.ToString()
    $csvpar = $SysId

  #  $csvsta = $null

    $parentcheckrs = $null
    ##$csv | where {$_.Short_Description -eq "CPU LAPTOP-HR8RU4NU"}
    $csv = import-csv "C:\Documents\Inc_Track.csv"
    $parentcheckrspr = $csv | where CI -Like $csvci
    $parentcheckrs = $parentcheckrspr | where Short_Description -Like $csvdec 
    #$parentcheck
    if ($parentcheckrs -ne $null){
            foreach($parentcheck in $parentcheckrs){
        
            $pr = $parentcheck.Incident_Id
            $URI = "https://InstanceName/api/now/table/incident/"+$pr+""
            $parentstcheck = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method GET -ContentType "application/json" 
            $parent = $parentstcheck.result
            if ($parent.state -lt 6){
               # $csvsta = "Alive"
                Write-Host "Parent Found For. " + $csvnum + " Parent " + $parent.number
                $csvnum = $parent.number
                Start-Job -FilePath C:\Modules\AddParent.ps1 -ArgumentList $Incident1,$csvnum
                $csvpar = $parent.sys_id
                $csvdec = $parent.short_description
                $csvpar = $pr
                $csvpri = $parent.priority
                $csvchldcount = [int]($parentcheck.Child_Count) + 1
                $csvlstup = [Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)
                $csv | where Incident_Id -NE $pr | Export-Csv 'C:\Documents\Inc_Track.csv' -NoTypeInformation
                #sleep(5)
                $NewRow = "$csvnum,$pr,$csvci,$csvdec,$csvpar,$csvchldcount,$csvpri,$csvlstup"
                $NewRow | Add-Content -Path $csvFile
            }
            else{
                $csv | where Incident_Id -NE $pr | Export-Csv 'C:\Documents\Inc_Track.csv' -NoTypeInformation
                #$csvsta = "Dead"
                $obj += $Incident1
                $csvlstup = [Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)
                $NewRow = "$csvnum,$csvincsysid,$csvci,$csvdec,$csvpar,$csvchldcount,$csvpri,$csvlstup"
                $NewRow | Add-Content -Path $csvFile
            }
            }
        }
    else{
        $obj += $Incident1
        $csvlstup = [Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)
        $NewRow = "$csvnum,$csvincsysid,$csvci,$csvdec,$csvpar,$csvchldcount,$csvpri,$csvlstup"
        $NewRow | Add-Content -Path $csvFile
    }

    }
    
    }
    

    foreach($objchild in $obj){
    $csvdec = $objchild.short_description
    $type = $csvdec.Substring(0,$csvdec.IndexOf(" "))
    $QualifiedAsParent = $csv | where Incident_Number -Like $objchild.number
    if($QualifiedAsParent -ne $null){
        foreach($SAsParent in $QualifiedAsParent){
            if([int]($SAsParent.Child_Count) -lt 2){
                $holdflag = 0
            }else{
                $holdflag = 1
            }
                switch($type) {
                    Availability {
                        Write-Host "Availability Match."
                        Start-Job -FilePath C:\Modules\Availability.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Availability Module called."
                    } 
                    Disk {
                        Write-Host "Disk Match"
                        Start-Job -FilePath C:\Modules\DiskSpace.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Disk Module called."
                    } 
                    Service {
                        Write-Host "Service Match"
                        Start-Job -FilePath C:\Modules\Services.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Service Module called."
                    }
                    CPU {
                        Write-Host "CPU Match"
                        Start-Job -FilePath C:\Modules\CPU.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "CPU Module called."
                    }  
                    Memory {
                        Write-Host "Memory Match"
                        Start-Job -FilePath C:\Modules\Memory.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Service Module called."
                    } 
                    Default {
                        Write-Host "No Match"
                    }
                }
        }
    }
 }

# [Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)

 $lsthr = $csv | where Last_Updated -LT (([Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)-3600))
 $lsthr
 if($lsthr -ne $null){
        foreach($lsthrobj in $lsthr){
            Write-Host "Hour Gone For Parent: " + $lsthrobj.Incident_Number
        }
}
