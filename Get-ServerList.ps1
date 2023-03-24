<#
.DESCRIPTION
Script pour rechercher la liste des serveurs enregistres dans l'AD
.EXAMPLE
Get-ServerList.ps1
.PARAMETER Export
Permet d'exporter la liste
.EXAMPLE
Get-ServerList.ps1 -Export monfichier
#>

param (
    [parameter()]
    [String]$Export
)

begin{}

process{
    #On filtre sur l'OU des Serveurs dans l'AD
    Get-ADComputer -Filter * -SearchBase  "OU=,OU=,OU=,DC=,DC=" -Property Name,Description,OperatingSystem,IPv4Address,DNSHostName | Select -Property Name,Description,OperatingSystem,IPv4Address,DNSHostName | Sort-Object Name | Format-Table -AutoSize
    
    #Je teste si on exporte et si l'extension du fichier est bonne
    if ($Export -ne ''){
        if($Export -notlike "*.csv"){
            $Export = "$Export.csv"
        }
        #Je teste si le fichier existe deja, auquel cas je n'ecris pas
        if($(Test-Path $Export) -eq $true){
            Write-Output "`nImpossible de creer le fichier d'exportation, un fichier avec ce nom existe deja."
            $ExportValide="non"
        } else {
            $ExportValide="oui"
        }
        } else {
            $ExportValide="non"
    }
    #Si on exporte, j'exporte le resultat de la commande
    if ($ExportValide -eq "oui"){
        Get-ADComputer -Filter * -SearchBase  "OU=,OU=,OU=,DC=,DC=" -Property Name,Description,OperatingSystem,IPv4Address,DNSHostName | Select -Property Name,Description,OperatingSystem,IPv4Address,DNSHostName | Sort-Object Name | Export-Csv -Path $Export -NoClobber -NoTypeInformation -Delimiter ";"
    }
}




