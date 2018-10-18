<#
IMPORTANT SETUP FOR CSV AND XLSX INPUT FIELDS

XLSX DOUCMENTS MUST CONTAIN THESE HEADERS:
IPADDRESS, DOMAIN\URL, EMAILADDRESS, MD5HASH, SHA:256, SHA:1

CSV DOUCMENTS MUST CONTAIN THESE HEADERS:
IPADDRESS, DOMAIN\URL, EMAILADDRESS, MD5HASH, SHA:256, SHA:1

All other headers will be ignored for Suricata Rule generation.
IPv4 Address ranges can be interpreted by the function. IPv4 ranges must be placed within the XLSX/CSV file in this format:
192.168.1.0 - 192.168.4.255 -OR
192.168.1.0-192.168.4.255

IPv4 ranges can be solved on all 4 octets generating individual rules for each address within the given range.

Generation of rules will be saved in a Folder within the same path as the XLSX/CSV file.
#>

function New-CPTSuricataRule {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (!(Test-Path -Path $_)) {
                throw "PATH $_ COULD NOT BE FOUND"
            } else {
                $true
            }
        })]
        [string]$FilePath

    )

    Begin {

        $fileObject = Get-ChildItem -Path $FilePath

        switch ($fileObject.Extension) {
            '.csv'  {
                Write-Verbose -Message "IMPORT: $($FilePath | Split-Path -Leaf)"
                $csvObject = Import-Csv -Path $FilePath
            }

            '.xlsx' {
                Write-Verbose -Message "CONVERT: $($FilePath | Split-Path -Leaf)"
                $newCsvFilePath = Convert-ExcelToCsv -FilePath $FilePath
                Write-Verbose -Message "IMPORT: $($newCsvFilePath | Split-Path -Leaf)"
                $csvObject = Import-Csv -Path $newCsvFilePath
            }

            Default {
                Write-Warning -Message 'COULD NOT PROCESS CSV IMPORT'
                break
            }
        }
        
        #region Verify Headers
        # HEADERS FOR XLSX FILE MUST MATCH THESE HEADERS TO CREATE RULES
        Write-Verbose -Message "HEADER: Verification"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'IPADDRESS') {
            Write-Warning -Message "IPADDRESS Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: IPADDRESS Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'DOMAIN/URL') {
            Write-Warning -Message "DOMAIN/URL Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: DOMAIN/URL Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'EMAILADDRESS') {
            Write-Warning -Message "EMAILADDRESS Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: EMAILADDRESS Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'DATEOFTIPPER') {
            Write-Warning -Message "DATEOFTIPPER Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: DATEOFTIPPER Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'TIPPERNUMBER') {
            Write-Warning -Message "TIPPERNUMBER Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: TIPPERNUMBER Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'MD5Hash') {
            Write-Warning -Message "MD5Hash Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: MD5Hash Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'SHA:1') {
            Write-Warning -Message "SHA:1 Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: SHA:1 Pass"
        if (($csvObject | Get-Member -MemberType NoteProperty | Select-Object Name).Name -notcontains 'SHA:256') {
            Write-Warning -Message "SHA:256 Header does not exist in document"
            break
        }
        Write-Verbose -Message "HEADER: SHA:256 Pass"

        #endregion

        $rules           = @()
        $md5Hashes       = @()
        $sha256Hashes    = @()
        $sha1Hashes      = @()
        $SIDs            = @()
        $ipAddresses     = @{}
        $domainAddresses = @{}
        $emailAddress    = @{}

        Write-Verbose -Message "DATA: IPADDRESS Removing null values"
        $ipAddresses     = $csvObject | Where-Object { "$null" -ne $_.IPADDRESS } | Select-Object IPADDRESS,TIPPERNUMBER,DATEOFTIPPER
        Write-Verbose -Message "DATA: DOMAIN/URL Removing null values"
        $domainAddresses = $csvObject | Where-Object { "$null" -ne $_.'DOMAIN/URL' } | Select-Object 'DOMAIN/URL',TIPPERNUMBER,DATEOFTIPPER
        Write-Verbose -Message "DATA: EMAILADDRESS Removing null values"
        $emailAddresses  = $csvObject | Where-Object { "$null" -ne $_.EMAILADDRESS } | Select-Object EMAILADDRESS,TIPPERNUMBER,DATEOFTIPPER
        Write-Verbose -Message "DATA: MD5HASH Removing null values"
        $md5Hash         = $csvObject | Where-Object { "$null" -ne $_.MD5HASH } | Select-Object MD5HASH
        Write-Verbose -Message "DATA: SHA:256 Removing null values"
        $sha256Hash      = $csvObject | Where-Object { "$null" -ne $_.'SHA:256' } | Select-Object 'SHA:256'
        Write-Verbose -Message "DATA: SHA:1 Removing null values"
        $sha1Hash        = $csvObject | Where-Object { "$null" -ne $_.'SHA:1' } | Select-Object 'SHA:1'

    }

    Process {

        $pInc = 1
        $cInc = 1

        # IP ADDRESS RULE GENERATION
        # Used index enumeration for loop vs. foreach loop because appending IP values did not change the length of the loop
        for ($index = 0;$index -le $ipAddresses.Count;$index++) {
            if (($ipAddresses[$index].IPADDRESS -match ' - ') -or ($ipAddresses[$index].IPADDRESS -match '-')) {
                $startAddress = $ipAddresses[$index].IPADDRESS.Split('-').Trim()[0]
                $endAddress = $ipAddresses[$index].IPADDRESS.Split('-').Trim()[1]
                $ipAddressesFromRange = Get-IPrange -Start $startAddress -End $endAddress
                
                foreach ($ip in $ipAddressesFromRange) {
                    $ipAdd = @{
                        IPADDRESS = "$ip"
                        TIPPERNUMBER = "$($ipAddresses[$index].TIPPERNUMBER)"
                        DATEOFTIPPER = "$($ipAddresses[$index].DATEOFTIPPER)"
                    }
                    $ipAdd = New-Object -TypeName psObject -Property $ipAdd
                    $ipAddresses += $ipAdd
                }
                Write-Verbose "ADDED IP RANGE: $ipAddress // COUNT: $($ipAddressesFromRange.Count)"
            }
            Write-Progress -Id 1 -Activity 'SURICATA RULE GENERATION' -Status 'Generating rules'`
            -PercentComplete ($pInc / (($ipAddresses.Count) + ($domainAddresses.Count) + ($emailAddresses.Count) + ($md5Hash.Count) + ($sha256Hash.Count) + ($sha1Hash.Count)) * 100)

            Write-Progress -Id 2 -ParentId 1 -Activity 'IP ADDRESS RULE GENERATION' -Status "Generating IPv4:$($ipAddress.IPADDRESS) || TipperNumber:$($ipAddress.TIPPERNUMBER) || DateOfTipper:$($ipAddress.DATEOFTIPPER) || DateCreatedRule:$(Get-Date -Format dd-MMM-yy)"`
                -PercentComplete ($cInc / (($ipAddresses.Count)) * 100)

            if ($ipAddresses[$index].IPADDRESS -notmatch '-') {
                do {
                    Write-Verbose -Message "Generating SID"
                    $SID = Get-Random -Maximum 1999999 -Minimum 1000000
                } while ($SIDs -contains $SID)
                $rules += "alert ip $($ipAddresses[$index].IPADDRESS) any <> any any (msg: `"856 Malicious IP`"; sid:$SID; metadata: `"$($ipAddresses[$index].TIPPERNUMBER), $($ipAddresses[$index].DATEOFTIPPER), $(Get-Date -Format dd-MMM-yy)`";)"

                Write-Verbose -Message "RULE: $($ipAddresses[$index].IPADDRESS)"
                Write-Verbose -Message "SID:$SID Used for rule"
                $SIDs += $SID
            }

            $cInc++
            $pInc++
        }

        $cInc = 1
        # DOMAIN/URL ADDRESS RULE GENERATION
        foreach ($domainAddress in $domainAddresses) {
            Write-Progress -Id 1 -Activity 'SURICATA RULE GENERATION' -Status 'Generating rules'`
            -PercentComplete ($pInc / (($ipAddresses.Count) + ($domainAddresses.Count) + ($emailAddresses.Count) + ($md5Hash.Count) + ($sha256Hash.Count) + ($sha1Hash.Count)) * 100)

            Write-Progress -Id 3 -ParentId 2 -Activity 'DOMAIN/URL ADDRESS RULE GENERATION' -Status "Generating Domain/URL:$($domainAddress.'DOMAIN/URL') || TipperNumber:$($ipAddress.TIPPERNUMBER) || DateOfTipper:$($ipAddress.DATEOFTIPPER) || DateCreatedRule:$(Get-Date -Format dd-MMM-yy)"`
                -PercentComplete ($cInc / (($domainAddresses.Count)) * 100)

            do {
                Write-Verbose -Message "Generating SID"
                $SID = Get-Random -Maximum 1999999 -Minimum 1000000
            } while ($SIDs -contains $SID)
            $rules += "alert dns any any <> any any (msg: `"856 Malicious Domain`"; dns_query; content:`"$($domainAddress.'DOMAIN/URL')`"; nocase; sid:$SID; metadata: `"$($domainAddress.TIPPERNUMBER), $($domainAddress.DATEOFTIPPER), $(Get-Date -Format dd-MMM-yy)`";)"

            Write-Verbose -Message "RULE: $($domainAddress.'DOMAIN/URL')"
            Write-Verbose -Message "SID:$SID Used for rule"
            $SIDs += $SID

            $cInc++
            $pInc++
        }

        $cInc = 1
        # EMAIL ADDRESS RULE GERNATION
        foreach ($emailAddress in $emailAddresses) {
            Write-Progress -Id 1 -Activity 'SURICATA RULE GENERATION' -Status 'Generating rules'`
            -PercentComplete ($pInc / (($ipAddresses.Count) + ($domainAddresses.Count) + ($emailAddresses.Count) + ($md5Hash.Count) + ($sha256Hash.Count) + ($sha1Hash.Count)) * 100)

            Write-Progress -Id 4 -ParentId 3 -Activity 'EMAIL ADDRESS RULE GENERATION' -Status "Generating Domain/URL:$($emailAddress.EMAILADDRESS) || TipperNumber:$($emailAddress.TIPPERNUMBER) || DateOfTipper:$($emailAddress.DATEOFTIPPER) || DateCreatedRule:$(Get-Date -Format dd-MMM-yy)"`
                -PercentComplete ($cInc / (($emailAddresses.Count)) * 100)

            do {
                Write-Verbose -Message "Generating SID"
                $SID = Get-Random -Maximum 1999999 -Minimum 1000000
            } while ($SIDs -contains $SID)
            $rules += "alert ip any any <> any any (msg: `"856 Malicious email address`"; content:`"$($emailAddress.EMAILADDRESS)`"; nocase; sid:$SID; metadata: `"$($emailAddress.TIPPERNUMBER), $($emailAddress.DATEOFTIPPER), $(Get-Date -Format dd-MMM-yy)`";)"

            Write-Verbose -Message "$($emailAddress.EMAILADDRESS)"
            Write-Verbose -Message "SID:$SID Used for rule"
            $SIDs += $SID

            $cInc++
            $pInc++
        }

        $cInc = 1
        # MD5 HASH LIST GENERATION
        foreach ($md5 in $md5Hash) {
            Write-Progress -Id 1 -Activity 'SURICATA RULE GENERATION' -Status 'Generating rules'`
            -PercentComplete ($pInc / (($ipAddresses.Count) + ($domainAddresses.Count) + ($emailAddresses.Count) + ($md5Hash.Count) + ($sha256Hash.Count) + ($sha1Hash.Count)) * 100)

            Write-Progress -Id 2 -ParentId 1 -Activity 'MD5 RULE GENERATION' -Status "$md5"`
                -PercentComplete ($cInc / (($md5Hash.Count)) * 100)

            $md5Hashes += $md5.'MD5Hash'

            $cInc++
            $pInc++
        }

        $cInc = 1
        # SHA256 HASH LIST GENERATION
        foreach ($sha256 in $sha256Hash) {
            Write-Progress -Id 1 -Activity 'SURICATA RULE GENERATION' -Status 'Generating rules'`
            -PercentComplete ($pInc / (($ipAddresses.Count) + ($domainAddresses.Count) + ($emailAddresses.Count) + ($md5Hash.Count) + ($sha256Hash.Count) + ($sha1Hash.Count)) * 100)

            Write-Progress -Id 3 -ParentId 2 -Activity 'SHA256 RULE GENERATION' -Status "$sha256"`
                -PercentComplete ($cInc / (($sha256Hash.Count)) * 100)

            $sha256Hashes += $sha256.'SHA:256'

            $cInc++
            $pInc++
        }

        $cInc = 1
        # SHA1 HASH LIST GENERATION
        foreach ($sha1 in $sha1Hash) {
            Write-Progress -Id 1 -Activity 'SURICATA RULE GENERATION' -Status 'Generating rules'`
            -PercentComplete ($pInc / (($ipAddresses.Count) + ($domainAddresses.Count) + ($emailAddresses.Count) + ($md5Hash.Count) + ($sha256Hash.Count) + ($sha1Hash.Count)) * 100)

            Write-Progress -Id 4 -ParentId 3 -Activity 'SHA1 RULE GENERATION' -Status "$sha1"`
                -PercentComplete ($cInc / (($sha1Hash.Count)) * 100)

            $sha1Hashes += $sha1.'SHA:1'

            $cInc++
            $pInc++
        }

        do {
            Write-Verbose -Message "Generating SID"
            $SID = Get-Random -Maximum 1999999 -Minimum 1000000
        } while ($SIDs -contains $SID)
        # MD5 HASH RULE GENERATION
        $rules += "alert ip any any <> any any (msg: `"856 Malicious MD5 hash detected`"; filemd5:/etc/suricata/rules/malicious_hashes_md5; sid:$SID; metadata: `"$(Get-Date -Format dd-MMM-yy)`";)"
        Write-Verbose -Message "SID:$SID Used for rule"
        $SIDs += $SID
        do {
            Write-Verbose -Message "Generating SID"
            $SID = Get-Random -Maximum 1999999 -Minimum 1000000
        } while ($SIDs -contains $SID)
        # SHA254 RULE GENERATION
        $rules += "alert ip any any <> any any (msg: `"856 Malicious SHA256 hash detected`"; filesha256:/etc/suricata/rules/malicious_hashes_sha256; sid:$SID; metadata: `"$(Get-Date -Format dd-MMM-yy)`";)"
        Write-Verbose -Message "SID:$SID Used for rule"
        $SIDs += $SID
        do {
            Write-Verbose -Message "Generating SID"
            $SID = Get-Random -Maximum 1999999 -Minimum 1000000
        } while ($SIDs -contains $SID)
        # SHA1 RULE GENERATION
        $rules += "alert ip any any <> any any (msg: `"856 Malicious SHA1 hash detected`"; filesha1:/etc/suricata/rules/malicious_hashes_sha1; sid:$SID; metadata: `"$(Get-Date -Format dd-MMM-yy)`";)"
        Write-Verbose -Message "SID:$SID Used for rule"
        $SIDs += $SID

    }

    End {
        
        New-Item -Path "$($FilePath | Split-Path -Parent)" -Name "Suricata_Rules_$(Get-Date -Format dd-MMM-yy)" -ItemType Directory -Force -Confirm:$false

        $rules | Out-File -FilePath "$($FilePath | Split-Path -Parent)\Suricata_Rules_$(Get-Date -Format dd-MMM-yy)\local.rules" -Force -Confirm:$false
        $md5Hashes | Out-File -FilePath "$($FilePath | Split-Path -Parent)\Suricata_Rules_$(Get-Date -Format dd-MMM-yy)\malicious_hashes_md5" -Force -Confirm:$false
        $sha256Hashes | Out-File -FilePath "$($FilePath | Split-Path -Parent)\Suricata_Rules_$(Get-Date -Format dd-MMM-yy)\malicious_hashes_sha256" -Force -Confirm:$false
        $sha1Hashes | Out-File -FilePath "$($FilePath | Split-Path -Parent)\Suricata_Rules_$(Get-Date -Format dd-MMM-yy)\malicious_hashes_sha1" -Force -Confirm:$false
        Write-Verbose -Message "RULES CREATED = $($rules.Count)"
        Write-Verbose -Message "HASH CREATED = $(($md5Hashes.Count) + ($sha256Hashes.Count) + ($sha1Hashes.Count))"
    }

}

