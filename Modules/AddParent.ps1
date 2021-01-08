param
(
    $Incident,
    $csvnum
)

$logfile = "C:\Users\A667141\eclipse-workspace\Test\Logs\txtlog.txt"

    Write-Host "Working On: " + $Incident.number
    $logcontent = (Get-Date).ToString() +  " Working On: " + $Incident.number + "`r`n"
    Add-Content $logfile $logcontent
    $SysId = $Incident.sys_id.ToString()
    
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


            
                $result = "`\nAdding Parent As qualified as multiple.`\n"
                #$logcontent = (Get-Date).ToString() + " Closing the case: "+ $Incident.number +"`r`nPing Success..Ping results are as below.`r`n"
                $logcontent = (Get-Date).ToString() + "`r`nAdding Parent As "+ $Incident.number +" qualified as multiple.`r`n"
                Add-Content $logfile $logcontent
                $pendingtimer = (Get-Date).AddDays(1)
                
                    # Specify request body
                    $body = "{
                            `"work_notes`":`"$result`",
                            `"incident_state`":`"4`",
                            `"u_on_hold_reasoning`":`"1`",
                            `"parent_incident`":`"$csvnum`",
                            `"u_pending_timer`":`"$pendingtimer`"
                            }"
          
        
 # Send HTTP request
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body

# Print response
    $response.RawContent 
    ############################################################
