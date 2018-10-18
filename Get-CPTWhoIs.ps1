function Get-CPTWhoIs {
    [CmdLetBinding()]
    Param (
        [Parameter(ParameterSetName = 'Domain', Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$Domain,
        [Parameter(ParameterSetName = 'IP', Mandatory = $false, Position = 1)]
        [string]$IPv4
    )

    begin {

        $rand = Get-Random -Minimum 0 -Maximum ($Script:Whoapikeys.Count)

        $whoapi = 'https://api.whoapi.com'
        $apikey = $Script:Whoapikeys[$rand]

        $initUrl = "https://api.whoapi.com/?apikey=$apikey&r=whois&domain="
        $WebRequest = Invoke-WebRequest -UseBasicParsing -Uri $initUrl
        
        if ($WebRequest.StatusCode -ne '200') {
            Write-Information -MessageData "StatusCode: $($WebRequest.StatusCode)" -InformationAction Continue
            Write-Information -MessageData "apikey: $apikey" -InformationAction Continue
            break;
        } else {
            Write-Information -MessageData "StatusCode: $($WebRequest.StatusCode)" -InformationAction Continue
            Write-Information -MessageData "apikey: $apikey" -InformationAction Continue
        }

        function CallDomain ($whoapi,$apikey,$r,$Domain) {
            $url            = "$whoapi/?domain=$Domain&ip=$IPv4&r=$r&apikey=$apikey"
            $whoapiResponse = Invoke-RestMethod -Method Post -Uri "$url" -UseBasicParsing
            return $whoapiResponse
        }

        function CallIP ($whoapi, $apikey, $r, $IPv4) {
            $url            = "$whoapi/?domain=$Domain&ip=$IPv4&r=$r&apikey=$apikey"
            $whoapiResponse = Invoke-RestMethod -Method Post -Uri "$url" -UseBasicParsing
            return $whoapiResponse
        }
        
    }

    process {

        switch ($PSBoundParameters.Keys) {
            'Domain' {
                
                $rTypes = @(
                    'whois'
                    'geo'
                    'cert'
                    'blacklist'
                )
                
                foreach ($rType in $rTypes) {
                    $response = CallDomain -whoapi $whoapi -apikey $apikey -r $rType -Domain $Domain
                    if ($rType -eq 'whois') {
                        Write-Host "$($rType.ToUpper()): $($Domain.ToUpper())" -ForegroundColor Magenta
                        Write-Host "`tWhoIs_Server: $($response.whois_server)" -ForegroundColor Cyan
                        Write-Host "`tStatus_Description: $($response.status_desc)" -ForegroundColor Cyan
                        Write-Host "`tDate_Created: $($response.date_created)" -ForegroundColor Cyan
                        Write-Host "`tDate_Expires: $($response.Date_Expires)" -ForegroundColor Cyan
                        Write-Host "`tDate_Updated: $($response.Date_Updated)" -ForegroundColor Cyan
                        Write-Host "`tDomain_Status:" -ForegroundColor Cyan
                        Write-Host "$($response.Domain_Status | %{ Write-Host "`t`t$_" -ForegroundColor Cyan })" -ForegroundColor Cyan
                        Write-Host "`tNameservers:" -ForegroundColor Cyan
                        Write-Host "$($response.nameservers | %{ Write-Host "`t`t$_" -ForegroundColor Cyan })" -ForegroundColor Cyan
                        Write-Host "`tContacts:" -ForegroundColor Cyan
                        Write-Host "$($response.contacts | %{ Write-Host "`t`t$_" -ForegroundColor Cyan })" -ForegroundColor Cyan
                        #$response
                    }
                    if ($rType -eq 'geo'){
                        Write-Host "$($rType.ToUpper()): $($Domain.ToUpper())" -ForegroundColor Magenta
                        Write-Host "`tIP: $($response.ip)" -ForegroundColor Green
                        Write-Host "`tCountry: $($response.geo_country)" -ForegroundColor Green
                        Write-Host "`tCity: $($response.geo_city)" -ForegroundColor Green
                        Write-Host "`tLatitude: $($response.geo_latitude)" -ForegroundColor Green
                        Write-Host "`tLongitude: $($response.geo_longitude)" -ForegroundColor Green
                        #$response
                    }
                    if ($rType -eq 'cert'){
                        Write-Host "$($rType.ToUpper()): $($Domain.ToUpper())" -ForegroundColor Magenta
                        Write-Host "`tCategory: $($response.category)"
                        Write-Host "`tOrganization: $($response.organization)"
                        Write-Host "`tCity: $($response.city)"
                        Write-Host "`tState: $($response.state)"
                        Write-Host "`tCountry: $($response.country)"
                        Write-Host "`tIssuer: $($response.issuer)"
                        Write-Host "`tDate_Issued: $($response.date_issued)"
                        Write-Host "`tDate_Expires: $($response.date_expires)"
                        #$response
                    }
                    if ($rType -eq 'blacklist'){
                        Write-Host "$($rType.ToUpper()): $($Domain.ToUpper())" -ForegroundColor Magenta
                        Write-Host "`tIP: $($response.ip)" -ForegroundColor Red
                        Write-Host "`tBlacklisted: $($response.blacklisted)" -ForegroundColor Red
                        Write-Host "`tBlacklists:" -ForegroundColor Red
                        Write-Host "$($response.blacklists | %{ $_ | % { Write-Host "`t`tTracker: $($_.tracker)`t Blacklisted: $($_.blacklisted)" -ForegroundColor Red} })"
                        #$response
                    }
                }
                Write-Host "Req Avail: $($response.requests_available)"-ForegroundColor DarkYellow

            }

            'IPv4' {
                
                $rType = 'ipwhois'
                $response = CallIP -whoapi $whoapi -apikey $apikey -r $rType -IPv4 $IPv4
                Write-Host "$($rType.ToUpper()): $($IPv4.ToUpper())" -ForegroundColor Magenta
                $response
            }

            Default {
                Write-Warning -Message "You should really think about providing some kind of value - it would make this process much simpler!"
            }
        }

    }

    end {

    }

}
