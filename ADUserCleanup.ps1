<#
.SYNOPSIS
    .
.DESCRIPTION
    Used to finde Users older than -x and move to disabled users OU and make inactive.
    Device where powershell script is run must have Active Directory Management installed
    Can be used in Test Run mode which will generate an output file of users found along
    with lastlogin date.
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
    #Credit
    #######################################################################################
# Credit https://stackoverflow.com/questions/33941460/check-if-ou-exists-before-creating-it
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
        Disable-ADAccount
        #Move Account to Target OU
        Move-ADObject -TargetPath "$Name,$Path"
    }

}