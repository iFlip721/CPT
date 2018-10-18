function Get-CPTDomainReport {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [String] $FilePath,
        [Parameter(ParameterSetName = 'Domain', Mandatory = $false)]
        $Domain
    )

    begin {
        $OutputDrive = 'C:'
        $OutputLocation = 'TEMP-856'
        $OutputFullPath = Join-Path -Path $OutputDrive -ChildPath $OutputLocation
        $domains = Get-Content -Path $FilePath
        $inc = 1
        $ProgressCounter = 0
    }

    process {
        
        foreach ($domain in $domains){
            if ($domain) {
                Write-Progress -Id 1 -Activity "domain: $domain : API: $($Script:VTKeyArray[$inc - 1])" `
                 -Status "Progress: $ProgressCounter out of $($domains.count) Percent Complete: $($ProgressCounter/$domains.count*100 | % {$_.ToString("#.##")}) %" `
                 -PercentComplete ($ProgressCounter/$domains.count*100)
                $VTReport = Get-VTReport -uri $domain -VTApiKey $Script:VTKeyArray[$inc - 1] -Verbose

                if ($null -eq $VTReport.response_code) {
                    do {
                        Write-Host "Pumping the breaks on those API requests for a few seconds..." -ForegroundColor Yellow
                        Start-Sleep -Seconds 10
                        $inc++
                        if ($inc -gt $Script:VTKeyArray.Count) {
                            $inc = 1
                        }
                        $VTReport = Get-VTReport -uri $domain -VTApiKey $Script:VTKeyArray[$inc - 1] -Verbose
                        Write-Progress -Id 1 -Activity "domain: $domain : API: $($Script:VTKeyArray[$inc - 1])" `
                        -Status "Progress: $ProgressCounter out of $($domains.count) Percent Complete: $($ProgressCounter/$domains.count*100 | % {$_.ToString("#.##")}) %" `
                        -PercentComplete ($ProgressCounter/$domains.count*100)
                    } while ($null -eq $VTReport.response_code)
                }

                Write-Progress -Id 2 -ParentId 1 -Activity "Response Code : $($VTReport.response_code)" -Status "Verbose Msg : $($VTReport.verbose_msg)"

                if ($VTReport.response_code -gt 0){
                    if (!(Test-Path -Path $OutputFullPath)){
                        New-Item -Path "$OutputDrive\" -Name "$OutputLocation" -ItemType Directory
                    }
                    $VTReport | Export-Csv -Path "$OutputFullPath\Domain-ResponseCode1-$(Get-Date -UFormat %Y-%m-%d).csv" -Append -NoClobber -NoTypeInformation -Force
                }
                else{
                    if (!(Test-Path -Path $OutputFullPath)){
                        New-Item -Path "$OutputDrive\" -Name "$OutputLocation" -ItemType Directory
                    }
                    $VTReport | Export-Csv -Path "$OutputFullPath\Domain-ResponseCode0-$(Get-Date -UFormat %Y-%m-%d).csv" -Append -NoClobber -NoTypeInformation -Force
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
