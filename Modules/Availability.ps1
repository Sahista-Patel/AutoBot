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


            $server = $desc.Substring($desc.IndexOf(" ")+1)
            $ping = Test-Connection $server -Quiet
            if($ping -eq "True") {
                Write-Host "Ping success..Server is up. Ping results are as below"
                $ping = Ping $server
                #$result = "Closing the case.`\nPing Success..Ping results are as below`\n"
                $result = "`\nPing Success..Ping results are as below`\n"
                #$logcontent = (Get-Date).ToString() + " Closing the case: "+ $Incident.number +"`r`nPing Success..Ping results are as below.`r`n"
                $logcontent = (Get-Date).ToString() + "`r`nPing Success..Ping results are as below.`r`n"
                Foreach ($pingline in $ping){
                        $result += $pingline + "`\n"
                        $logcontent += $pingline + "`r`n"
                }
                Add-Content $logfile $logcontent
                if($holdflag -eq 0){
                $result += "Closing the case.`\n"
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
            else {
                Write-Host "Ping Failed..Ping results are as below"
                $logcontent = (Get-Date).ToString() + " Ping Failed..For Incdent: " + $Incident.number +" Ping results are as below.`r`n"
                $ping = Ping $server
                $result = "Assigning to 2nd line team for further investigation.`\nPing Failed..Ping results are as below`\n"
                 $logcontent = (Get-Date).ToString() + " Assigning "+ $Incident.number +" to 2nd line team for further investigation.`r`nPing Failed..Ping results are as below.`r`n"
                Foreach ($pingline in $ping){
                    $result += $pingline + "`\n"
                    $logcontent += $pingline + "`r`n"
                }
                # Specify request body....Assignment group ID relevent
                $body = "{
                            `"work_notes`":`"$result`",
                            `"assignment_group`":`"XXXXXX`",
                            `"incident_state`":`"1`"
                            }"
                        Add-Content $logfile $logcontent
            } 
      
          
        
 # Send HTTP request
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body

# Print response
    $response.RawContent 
    ############################################################
