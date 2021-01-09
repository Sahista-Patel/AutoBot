param
(
    $Incident,
    [int]$holdflag
)

$logfile = "C:\Test\Logs\txtlog.txt"



    Write-Host "Working On: " + $Incident.number
    $logcontent = (Get-Date).ToString() +  " Working On: " + $Incident.number + "`r`n"
    Add-Content $logfile $logcontent
    $SysId = $Incident.sys_id.ToString()
    $desc = $Incident.short_description
    #$type = $desc.Substring(0,$desc.IndexOf(" "))
    
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


        $withouttype = $desc.Substring($desc.IndexOf(" ")+1)
        $server = $withouttype.Substring(0,$withouttype.IndexOf(" "))
        #$server
        $Disk = $withouttype.Substring($withouttype.IndexOf(" ")+1)
        #$Disk

        $result = ""
        
        
        $Before = Get-WmiObject Win32_LogicalDisk -ComputerName $server | Where-Object { $_.DeviceID -eq $Disk} | Select-Object SystemName, 
                @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, 
                @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, 
                @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, 
                @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } }
        $detaillist=$Before
        #Write-Host "\nSystem Name: " + $detaillist.SystemName
        #Write-Host "\nBefore walu. System Name: " + $Before.SystemName
        
        $result += "`\nBefore Cleanup`\nSystemName    : "+ $detaillist.SystemName
        $result += "`\nDrive         : "+ $detaillist.Drive  
        $result += "`\nSize (GB)     : "+ $detaillist.'Size (GB)'
        $result += "`\nFreeSpace (GB): "+ $detaillist.'FreeSpace (GB)'
        $result += "`\nPercentFree   : "+ $detaillist.PercentFree
        if($detaillist.PercentFree -lt 90){
            $pathtmp = $Disk + "\tmp\*"
            Remove-Item -Recurse  $pathtmp -Force -Verbose -ErrorAction SilentlyContinue 
            $Before = Get-WmiObject Win32_LogicalDisk -ComputerName $server | Where-Object { $_.DeviceID -eq $Disk} | Select-Object SystemName, 
                @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, 
                @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, 
                @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, 
                @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } }
            $detaillist=$Before
            $result += "`\n----------------------------------"
            $result += "`\nAfter Cleanup`\nSystemName    : "+ $detaillist.SystemName
            $result += "`\nDrive         : "+ $detaillist.Drive  
            $result += "`\nSize (GB)     : "+ $detaillist.'Size (GB)'
            $result += "`\nFreeSpace (GB): "+ $detaillist.'FreeSpace (GB)'
            $result += "`\nPercentFree   : "+ $detaillist.PercentFree
        }
        else{
            $result += "`\nEnough free space available. Under threshold.`\n False Alarm."
            #Add-Content $logfile $logcontent
        }
        if($holdflag -eq 0){
        if($detaillist.PercentFree -lt 90){
                $result += "`\nAfter Clean up. Still free space is beyond threshold.`\nNeed further intervention.."
                # Specify request body....Specify Assignment group ID
                $body = "{`"work_notes`":`"$result`",
                           `"assignment_group`":`"XXXXXXXX`",
                           `"incident_state`":`"1`"
                         }"
         }
         else{
            # Specify request body
                $body = "{
                            `"work_notes`":`"$result`",  
                            `"incident_state`":`"6`",
                            `"u_sub_close_code`":`"Monitoring`",
                            `"u_sub_close_code_2`":`"FalseUnwanted`",
                            `"u_resolution_code`":`"Repaired`",
                            `"close_code`":`"Resolved`",
                            `"close_notes`":`"$result`"
                            }"
         }
         }
         else{
         if($detaillist.PercentFree -lt 90){
                $result += "`\nAfter Clean up. Still free space is beyond threshold.`\nNeed further intervention.."      
         }
                $pendingtimer = ((Get-date).AddDays(1)).ToString()
                $result += "`\n`\nMultiple incidents received added children cases.Putting On-Hold.E-Mailed to Team.`\n"
                $logcontent = (Get-Date).ToString() + " Kept On-Hold as Multiple. Made parent. "+ $Incident.number
                # Specify request body
                    $body = "{
                            `"work_notes`":`"$result`",
                            `"incident_state`":`"4`",
                            `"u_on_hold_reasoning`":`"1`",
                            `"u_pending_timer`":`"$pendingtimer`"
                            }"
         }

          
        
 # Send HTTP request
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body

# Print response
    $response.RawContent 
    ############################################################
