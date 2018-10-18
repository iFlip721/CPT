function Get-CPTIpReport {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String] $FilePath
    )

    begin {
        $OutputDrive = 'C:'
        $OutputLocation = 'TEMP-856'
        $OutputFullPath = Join-Path -Path $OutputDrive -ChildPath $OutputLocation
        $Ips = get-content -Path $FilePath
        $inc = 1
        $ProgressCounter = 0
    }

    process {
        
        foreach ($Ip in $Ips){
            if ($Ip) {
                Write-Progress -Id 1 -Activity "Ip: $Ip : API: $($Script:VTKeyArray[$inc - 1])" `
                 -Status "Progress: $ProgressCounter out of $($Ips.count) Percent Complete: $($ProgressCounter/$Ips.count*100 | % {$_.ToString("#.##")}) %" `
                 -PercentComplete ($ProgressCounter/$Ips.count*100)
                $VTReport = Get-VTReport -ip $Ip -VTApiKey $Script:VTKeyArray[$inc - 1] -Verbose

                if ($null -eq $VTReport.response_code) {
                    do {
                        Write-Host "Pumping the breaks on those API requests for a few seconds..." -ForegroundColor Yellow
                        Start-Sleep -Seconds 10
                        $inc++
                        if ($inc -gt $Script:VTKeyArray.Count) {
                            $inc = 1
                        }
                        $VTReport = Get-VTReport -ip $Ip -VTApiKey $Script:VTKeyArray[$inc - 1] -Verbose
                        Write-Progress -Id 1 -Activity "Ip: $Ip : API: $($Script:VTKeyArray[$inc - 1])" `
                        -Status "Progress: $ProgressCounter out of $($Ips.count) Percent Complete: $($ProgressCounter/$Ips.count*100 | % {$_.ToString("#.##")}) %" `
                        -PercentComplete ($ProgressCounter/$Ips.count*100)
                    } while ($null -eq $VTReport.response_code)
                }

                Write-Progress -Id 2 -ParentId 1 -Activity "Response Code : $($VTReport.response_code)" -Status "Verbose Msg : $($VTReport.verbose_msg)"

                if ($VTReport.response_code -gt 0){
                    if (!(Test-Path -Path $OutputFullPath)){
                        New-Item -Path "$OutputDrive\" -Name "$OutputLocation" -ItemType Directory
                    }
                    $VTReport | export-csv -Path "$OutputFullPath\IP-ResponseCode1-$(get-date -UFormat %Y-%m-%d).csv" -Append -NoClobber -NoTypeInformation -Force
                }
                else{
                    if (!(Test-Path -Path $OutputFullPath)){
                        New-Item -Path "$OutputDrive\" -Name "$OutputLocation" -ItemType Directory
                    }
                    $VTReport | export-csv -Path "$OutputFullPath\IP-ResponseCode0-$(get-date -UFormat %Y-%m-%d).csv" -Append -NoClobber -NoTypeInformation -Force
                }
                $ProgressCounter++
                $inc++
                if ($inc -gt $Script:VTKeyArray.Count) {
                    $inc = 1
                }
            }

        }



    }

    end {
    
        Write-Host "Reports can be found @ $OutputFullPath" -ForegroundColor Yellow
    
    }

}

