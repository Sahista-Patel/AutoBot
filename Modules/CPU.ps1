param
(
    $Incident,
    [int]$holdflag
)

$logfile = "C:\Users\A667141\eclipse-workspace\Test\Logs\txtlog.txt"



    Write-Host "Working On: " + $Incident.number
    $logcontent = (Get-Date).ToString() +  " Working On: " + $Incident.number + "`r`n"
    Add-Content $logfile $logcontent
    $SysId = $Incident.sys_id.ToString()
    $desc = $Incident.short_description
    #$type = $desc.Substring(0,$desc.IndexOf(" "))
    
    ##########################################Edit worknote
    # Eg. User name="admin", Password="admin" for this code sample.
    $user = "ATOSA667141"
    $pass = "F@izu@1997@@"

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


        $withouttype = $desc.Substring($desc.IndexOf(" ")+1)
        $server = $withouttype.Substring($withouttype.IndexOf(" ")+1)
        $server

        $properties=@(
            @{Name="Process Name"; Expression = {$_.name}},
            @{Name="CPU (%)"; Expression = {$_.PercentProcessorTime}}   
        )
            $AVGProc = Get-WmiObject -computername $server win32_processor | Measure-object -property LoadPercentage -Average | Select Average
            $result= "`\n Before Load: " +$AVGProc.Average
            if ($AVGProc.Average -gt 1){
                $check = Get-WmiObject -computername $server -class Win32_PerfFormattedData_PerfProc_Process | Sort-Object -Property PercentProcessorTime -Descending | Select-Object $properties
                foreach($prc in $check){
                    if ($prc.'Process Name' -contains "notepad"){
                        Get-Process -Name "notepad" -ComputerName $server | Stop-Process
                        $result += "`\n Process named ["+$prc.'Process Name'+"] has been killed."
                        $AVGProc = Get-WmiObject -computername $server win32_processor | Measure-object -property LoadPercentage -Average | Select Average
                    }
                }
            $result += "`\n----------------------------------"
            $result += "`\n After Load: " +$AVGProc.Average
            if($AVGProc.Average -gt 1){
                $check = Get-WmiObject -computername $server -class Win32_PerfFormattedData_PerfProc_Process | Sort-Object -Property PercentProcessorTime -Descending | Select-Object $properties | Select-Object -First 10
                $result += "`\n CPU Load is still beyond threshold. Need Further itervention.`\n Below are the TOP processes. "
                foreach($li in $check){
                    $result += "`\n`\n Name: " + $li.'Process Name' + "`\n CPU: " + $li.'CPU (%)'
                    $li.'Process Name'
                    $li.'CPU (%)'
                }
                if($holdflag -eq 0){
                 # Specify request body
                $body = "{`"work_notes`":`"$result`",
                           `"assignment_group`":`"549714e1dbe614508fa197f2f3961960`",
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
               $result += "`\n Load came down and under threshold. "
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
                $result += "`\n CPU Load is already under threshold."
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
