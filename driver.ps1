$csvfile = "C:\Users\A667141\Documents\Inc_Track.csv"
$logfile = "C:\Users\A667141\eclipse-workspace\Test\Logs\txtlog.txt"

$obj = @()
$csvchldcount = 0
Remove-Job -state Completed

#// Set Instance 
$Instance="atosglobaldev"
$InstanceName = "https://"+$Instance+".service-now.com/" 


 
#// Create SN REST API credentials 
$SNowUser = "ATOSA667141" 
$SNowPass = "F@izu@1997" | ConvertTo-SecureString -asPlainText -Force 
$SNowCreds = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $SNowUser, $SNowPass 


$AssignGroup="EOC_L1"
#$num = "INC0010306"


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
    # Eg. User name="admin", Password="admin" for this code sample.
    $user = "ATOSA667141"
    $pass = "F@izu@1997"

    # Build auth header
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))


    # Set proper headers
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))
    $headers.Add('Accept','application/json')
    $headers.Add('Content-Type','application/json')
    # Specify endpoint uri
    $uri = "https://atosglobaldev.service-now.com/api/now/table/incident/"+$SysId+""

    # Specify HTTP method
    $method = "patch"

                # Specify request body
                $body = "{
                            `"work_notes`":`"Working On it.`",  
                            `"incident_state`":`"2`",
                            `"assigned_to`":`"fd318a1bdb0a90508fa197f2f3961979`"
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
    $csv = import-csv "C:\Users\A667141\Documents\Inc_Track.csv"
    $parentcheckrspr = $csv | where CI -Like $csvci
    $parentcheckrs = $parentcheckrspr | where Short_Description -Like $csvdec 
    #$parentcheck
    if ($parentcheckrs -ne $null){
            foreach($parentcheck in $parentcheckrs){
        
            $pr = $parentcheck.Incident_Id
            $URI = "https://atosglobaldev.service-now.com/api/now/table/incident/"+$pr+""
            $parentstcheck = Invoke-RestMethod -Uri $URI -Credential $SNowCreds -Method GET -ContentType "application/json" 
            $parent = $parentstcheck.result
            if ($parent.state -lt 6){
               # $csvsta = "Alive"
                Write-Host "Parent Found For. " + $csvnum + " Parent " + $parent.number
                $csvnum = $parent.number
                Start-Job -FilePath C:\Users\A667141\Documents\Modules\AddParent.ps1 -ArgumentList $Incident1,$csvnum
                $csvpar = $parent.sys_id
                $csvdec = $parent.short_description
                $csvpar = $pr
                $csvpri = $parent.priority
                $csvchldcount = [int]($parentcheck.Child_Count) + 1
                $csvlstup = [Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)
                $csv | where Incident_Id -NE $pr | Export-Csv 'C:\Users\A667141\Documents\Inc_Track.csv' -NoTypeInformation
                #sleep(5)
                $NewRow = "$csvnum,$pr,$csvci,$csvdec,$csvpar,$csvchldcount,$csvpri,$csvlstup"
                $NewRow | Add-Content -Path $csvFile
            }
            else{
                $csv | where Incident_Id -NE $pr | Export-Csv 'C:\Users\A667141\Documents\Inc_Track.csv' -NoTypeInformation
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
                        Start-Job -FilePath C:\Users\A667141\Documents\Modules\Availability.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Availability Module called."
                    } 
                    Disk {
                        Write-Host "Disk Match"
                        Start-Job -FilePath C:\Users\A667141\Documents\Modules\DiskSpace.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Disk Module called."
                    } 
                    Service {
                        Write-Host "Service Match"
                        Start-Job -FilePath C:\Users\A667141\Documents\Modules\Services.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "Service Module called."
                    }
                    CPU {
                        Write-Host "CPU Match"
                        Start-Job -FilePath C:\Users\A667141\Documents\Modules\CPU.ps1 -ArgumentList $objchild,$holdflag
                        Write-Host "CPU Module called."
                    }  
                    Memory {
                        Write-Host "Memory Match"
                        Start-Job -FilePath C:\Users\A667141\Documents\Modules\Memory.ps1 -ArgumentList $objchild,$holdflag
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

#$csv = import-csv "C:\Users\A667141\Documents\Inc_Track.csv"

 $lsthr = $csv | where Last_Updated -LT (([Math]::Round((Get-Date).ToFileTime() / 10000000 - 11644473600)-3600))
 $lsthr
 if($lsthr -ne $null){
        foreach($lsthrobj in $lsthr){
            Write-Host "Hour Gone For Parent: " + $lsthrobj.Incident_Number
        }
}