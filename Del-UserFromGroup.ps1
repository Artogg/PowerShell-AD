<#
.DESCRIPTION
Enleve un utilisateur d'un groupe
.PARAMETER User
L'utilisateur a retirer du groupe
.PARAMETER Group
Le groupe auquel enlever l'utilisateur
.EXAMPLE
Del-UserFromGroup.ps1 toto mongroupe
Del-UserFromGroup.ps1 -User toto -Groupe mongroupe
#>

param(
    [parameter()]
    [string]$Group,
    [parameter()]
    [string]$Users
)

begin{}

process{
    #Variables
    $NomLogs = "logs-DelUserFromGroup.ps1"
    $Logs = "$PSScriptRoot\$NomLogs"
    $date = Get-Date -Format "HHmmss_ddMMyyyy"
    $Fichier = "$PSSCriptRoot\$Users"

#   #Je teste si le fichier qui liste les utilisateurs existe
    $TestFichier = (Test-Path -Path $Fichier)
    if ($TestFichier -eq $false){
        Write-Output "Le fichier $Fichier n'existe pas."
        exit
    }

#Je teste si le fichier est vide
    $TestVide = ((Get-Item $Fichier).Length)
    if ($TestVide -eq 0){
        Write-Output "Le fichier $Fichier est vide."
        exit
    }

    #le dossier logs doit exister, sinon le cree
    if (Test-Path -Path $Logs){
        Write-Output "Le dossier de logs $Logs existe."
    
    } else {
        Write-Output "Creation du dossier des logs $Logs."
          
        #Je redirige vers null pour ne pas avoir de sortie dans la console lors de la creation du dossier.
        New-Item -ItemType Directory -Path $Logs | Out-Null
    }
    
    foreach($User in Get-Content $Fichier) {
        #Je teste si les parametres ne sont pas vides 
        if (($User -ne '') -and ($Group -ne '')){
            #Je teste si l'utilisateur existe dans l'AD
            try {
                $TestADUser = (Get-ADUser -Identity $User)
                Write-Output "$date : L'utilisateur $User existe dans l'AD."   
            } catch {       
                Write-Output "$date : L'utilisateur $User n'existe pas dans l'AD."
                Write-Output "$date : L'utilisateur $User n'existe pas dans l'AD." | Out-file "$logs\$date.txt" -append
                continue
            #Exit
            }
            #Je teste si le groupe existe dans l'AD
            try {
                $TestADGroup = (Get-ADGroup -Identity $Group)   
            } catch {       
                Write-Output "$date : Le groupe $Group n'existe pas dans l'AD." 
            Exit
            }
            #Je test si l'utilisateur est bien membre du groupe
            try {
                $TestADUserInGroup = (Get-ADGroupMember -Identity $Group | Where-Object {$_.name -eq $User} )
                if ($TestADUserInGroup -ne $null){
                    Write-Output "$date : L'utilisateur $User est bien membre du groupe $Group." 
                } else {
                    Write-Output "$date : L'utilisateur $user ne fait pas partie du groupe $Group."
                    Write-Output "$date : L'utilisateur $user ne fait pas partie du groupe $Group." | Out-file "$logs\$date.txt" -append
                    Continue
                }
            } Catch {
                Write-Output "$date : L'utilisateur $user ne fait pas partie du groupe $Group."
                Continue
            }
            try {
                Remove-ADGroupMember -identity $Group -Members $User -confirm:$false
                Write-Output "$date : Retrait de l'utilisateur $User au groupe $Group"
                Write-Output "$date : Retrait de l'utilisateur $User au groupe $Group"  | Out-file "$logs\$date.txt" -append
            } catch {
                Write-Output "$date : Erreur au retrait de l'utilisateur $User au groupe $Group" 
                Write-Output "$date : Erreur au retrait de l'utilisateur $User au groupe $Group"  | Out-file "$Logs\$date.txt" -append
                continue
            }
        #Si le groupe ou l'user est vide, erreur de syntax mais on continue la boucle
        } else {
            Write-Output "Mauvaise Syntaxe.`n Syntaxe: Del-UserFromGroup.ps1 -User toto -Groupe mongroupe"
            exit
        }
    }
}