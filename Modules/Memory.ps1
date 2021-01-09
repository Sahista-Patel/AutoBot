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
        $server = $withouttype.Substring($withouttype.IndexOf(" ")+1)
        $server

         $properties=@(
            @{Name="Process Name"; Expression = {$_.name}},
            @{Name="Memory (MB)"; Expression = {[Math]::Round(($_.workingSetPrivate / 1mb),2)}}
        )
            $ComputerMemory =  Get-WmiObject -Class WIN32_OperatingSystem -computerName $server
            $Total_Memory = ((($ComputerMemory.TotalVisibleMemorySize - $ComputerMemory.FreePhysicalMemory)*100)/ $ComputerMemory.TotalVisibleMemorySize)
            $RoundMemory = [math]::Round($Total_Memory, 2) 

            $result= "`\n Before Memory: " + $RoundMemory
            if ($RoundMemory -gt 1){
                $memory= Get-WmiObject -computername $server -class Win32_PerfFormattedData_PerfProc_Process | Sort-Object -Property workingSetPrivate -Descending | Select-Object $properties
                foreach($prc in $memory){
                    if ($prc.'Process Name' -contains "notepad"){
                        Get-Process -Name "notepad" -ComputerName $server | Stop-Process
                        $result += "`\n Process named ["+$prc.'Process Name'+"] has been killed."
                        $ComputerMemory =  Get-WmiObject -Class WIN32_OperatingSystem -computerName $server
                                            $Total_Memory = ((($ComputerMemory.TotalVisibleMemorySize - $ComputerMemory.FreePhysicalMemory)*100)/ $ComputerMemory.TotalVisibleMemorySize)
                                            $RoundMemory = [math]::Round($Total_Memory, 2) 
                    }
                }
            $result += "`\n----------------------------------"
            $result += "`\n After Memory: " + $RoundMemory
            if($RoundMemory -gt 1){
                $check = Get-WmiObject -computername $server -class Win32_PerfFormattedData_PerfProc_Process | Sort-Object -Property workingSetPrivate -Descending |
        Select-Object $properties -First 10 
                $result += "`\n Memory consumption is still beyond threshold. Need Further itervention.`\n Below are the TOP processes. "
                foreach($li in $check){
                    $result += "`\n`\n Name: " + $li.'Process Name' + "`\n Memory: " + $li.'Memory (MB)'
                    $li.'Process Name'
                    $li.'Memory (MB)'
                }
                if($holdflag -eq 0){
                 # Specify request body....Specify Assignment group
                $body = "{`"work_notes`":`"$result`",
                           `"assignment_group`":`"XXXXXXX`",
                           `"incident_state`":`"1`"
                         }"
                }
                else{
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
            }
            else {
               $result += "`\n Memory consumption came down and under threshold. "
               if($holdflag -eq 0){
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
                }else{
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
                
            }
            }
            else{
                $result += "`\n Memory consumption is already under threshold."
                if($holdflag -eq 0){
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
                 else{
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
                }
      
          
        
 # Send HTTP request
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body

# Print response
    $response.RawContent 
    ############################################################
