<#
.DESCRIPTION
Script pour extraire les membres d'une BAL a partir de l'AD
.EXAMPLE
Get-BalMembers.ps1 MonGroupeBal
Get-BalMembers.ps1 MonGroupeBal1, MonGroupeBal2
#>

param (
    [parameter(ValueFromPipeline = $true)]
    [string[]]$NomsBoitesPartagees
)

begin {}
process {       
    #Je fais une recherche dans l'AD pour recuperer les utilisateurs en se basant sur le nom de la BAL
    foreach ($NomBoitePartagee in $NomsBoitesPartagees){
        Write-Output "Les personnes suivantes sont membres de la BAL $NomBoitePartagee :"
        Write-output ""
        Get-ADUser -Filter * -SearchBase "OU=,OU=,OU,DC,DC=" -Properties name, msExchDelegateListLink | Where-Object {$_.name -eq $NomBoitePartagee} | Select-Object msExchDelegateListLink | ForEach-Object { $_. msExchDelegateListLink -replace '^CN=([^,]+),OU=.+$', '$1'  }
        Write-output ""
        Write-Output "*******************************"
    }
}