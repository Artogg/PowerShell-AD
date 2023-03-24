<#
.DESCRIPTION
Permet de retrouver les membres d'un groupe de l'AD, et d'en faire l'export si demande
.PARAMETER Export
Demande de faire un export dans un fichier .csv dans le dossier courant
.PARAMETER Groupe
Le groupe a retrouver dans l'AD
.EXAMPLE
Get-Groupe -Groupe MonGroupe
Get-Groupe -Groupe MonGroupe -Export monfichier.csv
Get-Groupe MonGroupe monfichier.csv
#>

param(
    [parameter(Mandatory=$true)]
    [String]$Groupe,
    [parameter()]
    [String]$Export
    )

begin {}

process{


    #Je check si le parametre d'export est utilise (un parametre string n'est jamais null, donc je teste s'il y a au moins un caractere)
    if ($Export -ne ''){
        if($(Test-Path $Export) -eq $true){
            Write-Output "`nImpossible de creer le fichier d'exportation, un fichier avec ce nom existe deja."
            Exit
        }
        #Je renomme le fichier pour ajouter l'extension si elle n'y est pas
        if($Export -notlike "*.csv"){
            $Export = "$Export.csv"
        }

        #J'exporte ma commande et je retire la premiere ligne inutile
        Get-ADGroupMember -Identity $Groupe | Get-ADUser -Property DisplayName | Select-Object Name,DisplayName | Export-Csv $Export
        (Get-Content $Export | Select-Object -Skip 1) | Set-Content $Export
    } else {
            #Je recherche dans le groupe, le nom de chaque utilisateur
            Get-ADGroupMember -Identity $Groupe | Get-ADUser -Property DisplayName | Select-Object Name,DisplayName
    }
} 