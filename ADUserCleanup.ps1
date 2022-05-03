<#
.SYNOPSIS
    .
.DESCRIPTION
    Used to find Users older than -x and move to disabled users OU and make inactive.
    Device where powershell script is run must have Active Directory Management installed
    Can be used in Test Run mode which will generate an output file of users.
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    Specifies a path to one or more locations. Unlike Path, the value of 
    LiteralPath is used exactly as it is typed. No characters are interpreted 
    as wildcards. If the path includes escape characters, enclose it in single
    quotation marks. Single quotation marks tell Windows PowerShell not to 
    interpret any characters as escape sequences.
.EXAMPLE
    C:\PS> ....
    <Description of example>
    .\ADUserCleanup.ps1
    .\ADUserCleanup.ps1 -Incactive x 
    .\ADUserCleanup.ps1 -Incactive 30
    .\ADUserCleanup.ps1 -Inactive -x -checkonly -Y
    
.NOTES
    Author: Richard Flowers
    5/3/22
    -Created Github
    -Created Dev Branch
    
    #Credit
     ## Credit https://stackoverflow.com/questions/33941460/check-if-ou-exists-before-creating-it
#>



param (

    #Number of Inactive Days
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [int]$InactiveDays,
    
    #Checkonly , ouputs to csv file
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [String]$Checkonly
 
)


function CreateOU ([string]$name, [string]$path, [string]$description) {
    $ouDN = "OU=$name,$path"

    # Check if the OU exists
    try {
        Get-ADOrganizationalUnit -Identity $ouDN | Out-Null
        Write-Verbose "OU '$ouDN' already exists."
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Verbose "Creating new OU '$ouDN'"
        New-ADOrganizationalUnit -Name $name -Path $path -Description $description
    }
}

# Stop if the AD module cannot be loaded
If (!(Get-module ActiveDirectory)) {
    Import-Module ActiveDirectory -ErrorAction Stop
}

#Days to check for Default 30 Days
if ($InactiveDays -eq '' -or $InactiveDays -eq $null) {
    $InactiveDays = 30
}
$Days = (Get-Date).Adddays( - ($InactiveDays))

#Check to see if review is necessary and outputs to script working directory as a csv file
if ($Checkonly[0] -match "[Y,y]" ) {
    #Export to file to review
    Get-ADUser -Filter { LastLogonTimeStamp -lt $Days -and enabled -eq $true }  -Properties LastLogonTimeStamp | select-object Name, @{Name = "Date"; Expression = { [DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('MM-dd-yyyy') } } | export-csv $pwd\LastLogOn_Users.csv -notypeinformation
}
Else {
    
    #Get Domain
    $Domain = (Get-ADForest -Current LocalComputer).Domains
    $Domainname = $domain.split(".")
    Foreach ($DC in $Domainname) { $path += "DC=$DC," }
    $Path = $Path.TrimEnd(',')
    $Name = "Disabled Users"

    #Creates OU if it doesn't already exists
    CreateOU -name "$Names" -path "$Path" -description "Disabled Inactive Users"

    #Get list of User who have not logged on in x Days
    $DisableUsers = Get-ADUser -Filter { LastLogonTimeStamp -lt $Days -and enabled -eq $true }  
    foreach ($UsertoDisable in $DisableUsers) {
        #Disable Active Directory Account
        Try {
            Disable-Account
        }
        Catch {
            Write-Output "$UsertoDisable is already disabled."
        }
        #Move Account to Target OU
        Try {
            Move-ADObject -TargetPath "$Name,$Path"
        }
        Catch {
            Write-host "$UsertoDisable is already in the correct OU" 
        }
    }

}
# SIG # Begin signature block
# MIImSQYJKoZIhvcNAQcCoIImOjCCJjYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJYwjbXZWY9NsOf8tlR3VX4oi
# jXSggh+GMIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0B
# AQwFADB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEh
# MB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAw
# MFoXDTI4MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5n
# IFJvb3QgUjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIE
# JHQu/xYjApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7
# fbu2ir29BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGr
# YbNzszwLDO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTH
# qi0Eq8Nq6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv
# 64IplXCN/7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2J
# mRCxrds+LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0P
# OM1nqFOI+rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXy
# bGWfv1VbHJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyhe
# Be6QTHrnxvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXyc
# uu7D1fkKdvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7id
# FT/+IAx1yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQY
# MBaAFKARCiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJw
# IDaRXBeF5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmlj
# YXRlU2VydmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3Sa
# mES4aUa1qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+
# BtlcY2fUQBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8
# ZsBRNraJAlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx
# 2jLsFeSmTD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyo
# XZ3JHFuu2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p
# 1FiAhORFe1rYMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG
# 9w0BAQwFADBWMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MS0wKwYDVQQDEyRTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYw
# HhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5WjBUMQswCQYDVQQGEwJHQjEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1Ymxp
# YyBDb2RlIFNpZ25pbmcgQ0EgUjM2MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAmyudU/o1P45gBkNqwM/1f/bIU1MYyM7TbH78WAeVF3llMwsRHgBGRmxD
# eEDIArCS2VCoVk4Y/8j6stIkmYV5Gej4NgNjVQ4BYoDjGMwdjioXan1hlaGFt4Wk
# 9vT0k2oWJMJjL9G//N523hAm4jF4UjrW2pvv9+hdPX8tbbAfI3v0VdJiJPFy/7Xw
# iunD7mBxNtecM6ytIdUlh08T2z7mJEXZD9OWcJkZk5wDuf2q52PN43jc4T9OkoXZ
# 0arWZVeffvMr/iiIROSCzKoDmWABDRzV/UiQ5vqsaeFaqQdzFf4ed8peNWh1OaZX
# nYvZQgWx/SXiJDRSAolRzZEZquE6cbcH747FHncs/Kzcn0Ccv2jrOW+LPmnOyB+t
# AfiWu01TPhCr9VrkxsHC5qFNxaThTG5j4/Kc+ODD2dX/fmBECELcvzUHf9shoFvr
# n35XGf2RPaNTO2uSZ6n9otv7jElspkfK9qEATHZcodp+R4q2OIypxR//YEb3fkDn
# 3UayWW9bAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBQy65Ka/zWWSC8oQEJwIDaR
# XBeF5jAdBgNVHQ4EFgQUDyrLIIcouOxvSK4rVKYpqhekzQwwDgYDVR0PAQH/BAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYD
# VR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEEATBLBgNVHR8ERDBCMECgPqA8hjpodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RS
# NDYuY3JsMHsGCCsGAQUFBwEBBG8wbTBGBggrBgEFBQcwAoY6aHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdSb290UjQ2LnA3YzAj
# BggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEM
# BQADggIBAAb/guF3YzZue6EVIJsT/wT+mHVEYcNWlXHRkT+FoetAQLHI1uBy/YXK
# ZDk8+Y1LoNqHrp22AKMGxQtgCivnDHFyAQ9GXTmlk7MjcgQbDCx6mn7yIawsppWk
# vfPkKaAQsiqaT9DnMWBHVNIabGqgQSGTrQWo43MOfsPynhbz2Hyxf5XWKZpRvr3d
# MapandPfYgoZ8iDL2OR3sYztgJrbG6VZ9DoTXFm1g0Rf97Aaen1l4c+w3DC+IkwF
# kvjFV3jS49ZSc4lShKK6BrPTJYs4NG1DGzmpToTnwoqZ8fAmi2XlZnuchC4NPSZa
# PATHvNIzt+z1PHo35D/f7j2pO1S8BCysQDHCbM5Mnomnq5aYcKCsdbh0czchOm8b
# kinLrYrKpii+Tk7pwL7TjRKLXkomm5D1Umds++pip8wH2cQpf93at3VDcOK4N7Ew
# oIJB0kak6pSzEu4I64U6gZs7tS/dGNSljf2OSSnRr7KWzq03zl8l75jy+hOds9TW
# SenLbjBQUGR96cFr6lEUfAIEHVC1L68Y1GGxx4/eRI82ut83axHMViw1+sVpbPxg
# 51Tbnio1lB93079WPFnYaOvfGAA0e0zcfF/M9gXr+korwQTh2Prqooq2bYNMvUoU
# KD85gnJ+t0smrWrb8dee2CvYZXD5laGtaAxOfy/VKNmwuWuAh9kcMIIGdTCCBN2g
# AwIBAgIQQ0AX+Og8iN2enSRqQ0GcWTANBgkqhkiG9w0BAQwFADBUMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2MB4XDTIyMDMwODAwMDAwMFoXDTIz
# MDMwODIzNTk1OVowVzELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRswGQYD
# VQQKDBJSaWNoYXJkIFcuIEZsb3dlcnMxGzAZBgNVBAMMElJpY2hhcmQgVy4gRmxv
# d2VyczCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJ6uuvgDUl0dNClr
# fgvw9atxnuDEPASL+RWfskqIbYNdOWJrxq7Vy8BIp/i06v+FQ2OqnQl9cpNM2/KL
# N9oZTZMd9jf6GECLLyO0CrMqsVsq+Hl3CM5C80wUQmFtxae37sGkfWSV+xDUTP/4
# ToQN7KM4Gp56aUvu5a1FpAW/YJaD22Fle1noe5vKAKTrf6CUhSLxayg8HPJBgJVR
# NH+4bVrJRHFe9AqqigdxDlUwn1/JisfEa1ppGkWiHp11y75IafQQogfjSdnENfW0
# sxuF3ki2OcwQcXyTZebMXmeZidxk10M3tL6ImOjKrxJ6zSqTFSNBp5JDAYELbnjl
# JtmGE9PN+UTVupeTBq+nwtAOKPXbESvqCeY8+Rh6LN2Fjq8h4lhniwW1p7Vexs8/
# y3MDgvYgX77ecPmC7yKK3Lw6iDcJ9Zx0WExfCCdD+iQoFlBivW1vDHYvP7ONKhp6
# EOJiT2Tl6OMLTGuQoW5PvnsZinLtLsjq4udqHp3/5IvTAW25QvfQ4Q2XpoqP/Fwf
# 1uIeEOvCxtxspaXjZ+9oOwS2vRPWTGEims88lB7DjrBDDyK+OpYsyWiemn8koN7w
# Sq36mra+ow7xgBhMJfK5dpUxy7vs1MGoGZWbmGHN2IJ/fTCgxDfPLFAzdfA7KYJK
# RH0I7mBmlN8U/L47n+BcsGenAJG9AgMBAAGjggG+MIIBujAfBgNVHSMEGDAWgBQP
# Kssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUX/o9HQCpOn2uSknKuBkoWqsc
# 8YMwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEoGA1UdIARDMEEwNQYMKwYBBAGyMQEC
# AQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeB
# DAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLnNlY3RpZ28uY29tL1Nl
# Y3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNybDB5BggrBgEFBQcBAQRtMGsw
# RAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1Ymxp
# Y0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5z
# ZWN0aWdvLmNvbTAgBgNVHREEGTAXgRVSRkxPV0VSUzIwMEBHTUFJTC5DT00wDQYJ
# KoZIhvcNAQEMBQADggGBAJei9gPO9ClsBACabMaoadW2BOFoCFxkrx0bT1Vb0LiL
# i2bBoHu0eAa3HMSf+JqN3RVAcA7vueiOdcj/fTf8+r6RkJX2tHdnB9LLWBfInlRU
# gQbmCfr02NCnthat7mO/faRMvCk/L8MFbbndadfO2REjc4Y1hytpmEqGE9Bakky4
# CH16LmFtL63QnhftDYk3izl3GEE71YZBV1CZXYQzBHAuD1qL/AHYeW5J+AGjRls8
# MknHuSPmMIEbB2jljg+UCHAXSzR34I+qx9EkuslMmKBudAo9YMh/fOFP4izpzUeH
# X8B83jTqUBOQxFm94eCdC/RIJjJ1d0Gv4km9VKYok3QpsO0bdFRUFZV19HgxlpR8
# s2B040gs73Fdwbk/bl1RPAPsuIlj5r4ZPBn95eEiejGn8WvtSdTWjJxXmxMbhsHH
# ZXp7h1GY0r8UTfYu26U8pjbVwZKG2QSOaT+neicgWOGtGU+Q6gbl6gamKch0iZP0
# I9fS6p+NCeRRu+3mu6l+GDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlsw
# DQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNl
# cnQgVHJ1c3RlZCBSb290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1
# OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9
# cklRVcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+d
# H54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+Qtxn
# jupRPfDWVtTnKC3r07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9d
# rMvohGS0UvJ2R/dhgxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02
# DVzV5huowWR0QKfAcsW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aP
# TnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De
# 4z6ic/rnH1pslPJSlRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPg
# v/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIs
# VzV5K6jzRWC8I41Y99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7
# W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTu
# zuldyF4wEr1GnrXTdrnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8E
# CDAGAQH/AgEAMB0GA1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSME
# GDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8
# MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAN
# BgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/
# GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBM
# Yh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4s
# nuCKrOX9jLxkJodskr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKj
# I/rAJ4JErpknG6skHibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HB
# anHZxhOACcS2n82HhyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVj
# mScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87
# eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttv
# FXseGYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc6
# 1RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2
# QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3W
# fPwwggbGMIIErqADAgECAhAKekqInsmZQpAGYzhNhpedMA0GCSqGSIb3DQEBCwUA
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0EwHhcNMjIwMzI5MDAwMDAwWhcNMzMwMzE0MjM1OTU5WjBMMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xJDAiBgNVBAMTG0RpZ2lDZXJ0
# IFRpbWVzdGFtcCAyMDIyIC0gMjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBALkqliOmXLxf1knwFYIY9DPuzFxs4+AlLtIx5DxArvurxON4XX5cNur1JY1D
# o4HrOGP5PIhp3jzSMFENMQe6Rm7po0tI6IlBfw2y1vmE8Zg+C78KhBJxbKFiJgHT
# zsNs/aw7ftwqHKm9MMYW2Nq867Lxg9GfzQnFuUFqRUIjQVr4YNNlLD5+Xr2Wp/D8
# sfT0KM9CeR87x5MHaGjlRDRSXw9Q3tRZLER0wDJHGVvimC6P0Mo//8ZnzzyTlU6E
# 6XYYmJkRFMUrDKAz200kheiClOEvA+5/hQLJhuHVGBS3BEXz4Di9or16cZjsFef9
# LuzSmwCKrB2NO4Bo/tBZmCbO4O2ufyguwp7gC0vICNEyu4P6IzzZ/9KMu/dDI9/n
# w1oFYn5wLOUrsj1j6siugSBrQ4nIfl+wGt0ZvZ90QQqvuY4J03ShL7BUdsGQT5Ts
# hmH/2xEvkgMwzjC3iw9dRLNDHSNQzZHXL537/M2xwafEDsTvQD4ZOgLUMalpoEn5
# deGb6GjkagyP6+SxIXuGZ1h+fx/oK+QUshbWgaHK2jCQa+5vdcCwNiayCDv/vb5/
# bBMY38ZtpHlJrYt/YYcFaPfUcONCleieu5tLsuK2QT3nr6caKMmtYbCgQRgZTu1H
# m2GV7T4LYVrqPnqYklHNP8lE54CLKUJy93my3YTqJ+7+fXprAgMBAAGjggGLMIIB
# hzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggr
# BgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0j
# BBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFI1kt4kh/lZYRIRh
# p+pvHDaP3a8NMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdD
# QS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBp
# bmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAA0tI3Sm0fX46kuZPwHk9gzkrxad
# 2bOMl4IpnENvAS2rOLVwEb+EGYs/XeWGT76TOt4qOVo5TtiEWaW8G5iq6Gzv0Uhp
# GThbz4k5HXBw2U7fIyJs1d/2WcuhwupMdsqh3KErlribVakaa33R9QIJT4LWpXOI
# xJiA3+5JlbezzMWn7g7h7x44ip/vEckxSli23zh8y/pc9+RTv24KfH7X3pjVKWWJ
# D6KcwGX0ASJlx+pedKZbNZJQfPQXpodkTz5GiRZjIGvL8nvQNeNKcEiptucdYL0E
# IhUlcAZyqUQ7aUcR0+7px6A+TxC5MDbk86ppCaiLfmSiZZQR+24y8fW7OK3NwJMR
# 1TJ4Sks3KkzzXNy2hcC7cDBVeNaY/lRtf3GpSBp43UZ3Lht6wDOK+EoojBKoc88t
# +dMj8p4Z4A2UKKDr2xpRoJWCjihrpM6ddt6pc6pIallDrl/q+A8GQp3fBmiW/iqg
# dFtjZt5rLLh4qk1wbfAs8QcVfjW05rUMopml1xVrNQ6F1uAszOAMJLh8UgsemXzv
# yMjFjFhpr6s94c/MfRWuFL+Kcd/Kl7HYR+ocheBFThIcFClYzG/Tf8u+wQ5KbyCc
# rtlzMlkI5y2SoRoR/jKYpl0rl+CL05zMbbUNrkdjOEcXW28T2moQbh9Jt0RbtAgK
# h1pZBHYRoad3AhMcMYIGLTCCBikCAQEwaDBUMQswCQYDVQQGEwJHQjEYMBYGA1UE
# ChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2Rl
# IFNpZ25pbmcgQ0EgUjM2AhBDQBf46DyI3Z6dJGpDQZxZMAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBTWcs6HgvlgOvtcuCXQr13QmPsSPDANBgkqhkiG9w0BAQEFAASCAgCJYpn4BzEE
# Teo/AFQmQ4wIlbndyM67Umfc1YbrESfJbZIxa41orSt5uNbBP9dgxJhzdRggl+bT
# n3bBYg6E4yVUwUpIJd5KFCgbHfMTG9KFBbkp8Nl3rUdH5bNiEJNx31uHAuN0Q3Fb
# RxCWldaUhaIdUc/j0SraA8No3LH2NGWm0MmreeCB3DVHt/ucgPGJWpVDV+K2QK7x
# kpW0jufmmfTsAdW2rttu1mcMGfP6eQ/+aMtSiPsKkq27rNupb1C0pHQg79itT9VG
# 9YpLgKrk/8XS3Ac9mcq85PNntH6EXM/bzFPbz/ysF2hcLJMl5W49L6S6gMsU/e1W
# 1b0Skr71RBBYAj6ur7RMTIezNHJJWpGvhyv15JPBf3G82vPsywW2jssqk6Rzdx9G
# jrbNIVu8BjUAwjsBEepV9z6QEMOHvSoPGGP++3kSC1H9hwCHjWRTZKvgrfbxBd3R
# XrNWkyCa/SPHyhVYAjhhHjuBUGG5h0xalbHCOyY/U17+nN5NUYYxpPOfJCWhxK+i
# f3l0GVMeUgTqt0X24woFS6T/mc4pRnaJ6H88K13ODVA5fUFxcRMs92tcnWP4LgVc
# 3w3tG9dGqCC3T5LZE+tHAsgFFH/BOLheLrSRZ1jn6IBb7p87YEbdQWJog1Mfl91w
# VycM6AU8ywuxkj5ud13fdkMT2mCwnoa+zKGCAyAwggMcBgkqhkiG9w0BCQYxggMN
# MIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBU
# aW1lU3RhbXBpbmcgQ0ECEAp6SoieyZlCkAZjOE2Gl50wDQYJYIZIAWUDBAIBBQCg
# aTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMjA1
# MDMxODQ4NTNaMC8GCSqGSIb3DQEJBDEiBCAycDQIXxCVM4qUPz695lZRpDytIKoL
# BuL/qNVp/QSNMTANBgkqhkiG9w0BAQEFAASCAgAoroePFWUwvYZDrRLCHca5GJMz
# NLqLos0uQhY62GRj3FK895yFI45oNPXCbpiIEIfSaTZ53T2xSsCHCstrDTAUEw5k
# 7nrK9IYHB13r42HrVLTj/p7uEu50wRKX90SrsbVJsp9BUN7VThRXML3L98Konnut
# LQss2cN0xOVw9T+E94OZlxE42HZDqIFOqanuxk8+l0qvUYibYW2t+L0vKu/P+NmQ
# EdOWUB4tnOuuTYdXrC0JVRTA8cFvUefPPn8qcVz3mHj92i4ccoPIKlWiQg2tFtPe
# SQ6PngbQ1IE+wFs/shbmOB2o2FoAsRkbMO9ZPL2JtPCfZSBCjRovRvDHrTSyFhkv
# NdWz9n1qY9H3bblEsKRLYFWhrQG6gLy4ukP3vlvBHaDO5BLhX3LiLsy+17AHwzPj
# xhmvi7Scpf4gc94XoE4z+hPF7/XylvTxNDI4ZNQGtHbA44CAM8UNPAYYSr3aT5bY
# 6jm6FOPvMAZSz9v21Jw6oB95F1nJVDhBN/tVX94uwB/gptwzxW5hEUa4f2sX9Guw
# 1rpIQvWmGChIHXsygH6+a/iKwVSFgqCp4i7ONoZdnDNBJWoaxre4dAHvk6Mxjp60
# 1WPpHQYLWY2ZfczjV0f4GCy/bd4o/p73gpmTVRak2A+MOttJ0KX8Xcx+Owl3OZJN
# xAQBCX3/aikxOMIJGg==
# SIG # End signature block
