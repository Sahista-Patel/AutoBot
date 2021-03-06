﻿param
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
        $servicename = $withouttype.Substring($withouttype.IndexOf(" ")+1)
        $serviceresult = Get-WmiObject -ComputerName $server -Class Win32_Service -Filter "Name='$servicename'"
        #$serviceresult = Get-service -ComputerName $server | where-object {$_.Name -eq $servicename}
        if($serviceresult.State -ne "Running"){
            try{
                $serviceresult.StartService()
                $serviceresult = Get-WmiObject -ComputerName $server -Class Win32_Service -Filter "Name='$servicename'"
                $result= "Service ["+$servicename+"] started successfully.`\n Current status: " +$serviceresult.State
                $logcontent= (Get-Date).ToString() + " For Incident: "+ $Incident.number +" Service ["+$servicename+"] started successfully.`r`n Current status: " +$serviceresult.State
                Add-Content $logfile $logcontent
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
         catch {
                $result = "Unable to start service ["+$servicename+"].`\n" + $_
                $logcontent= (Get-Date).ToString() + " For Incident: "+ $Incident.number +" Unable to start service ["+$servicename+"].`r`n" + $_
                Add-Content $logfile $logcontent
                if($holdflag -eq 0){
                # Specify request body....Specify Assignment group
                $body = "{`"work_notes`":`"$result`",
                           `"assignment_group`":`"XXXXXXXX`",
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
        }
        else{
            $result= "Service ["+$servicename+"] is already running.`\n Current status: " +$serviceresult.State
            $logcontent= (Get-Date).ToString() + " For Incident: "+$Incident.number +" Service ["+$servicename+"] is already running.`r`n Current status: " +$serviceresult.State + "`r`n"
            Add-Content $logfile $logcontent
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
      
          
        
 # Send HTTP request
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body

# Print response
    $response.RawContent 
    ############################################################
