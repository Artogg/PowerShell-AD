<# 
.SYNOPSIS
Ajoute les utilisateurs inscrits dans un fichier a des groupes de l'AD indique. Utilise les objets de l'AD (utiliser les ID des objets). A utiliser dans le dossier des scripts.
.PARAMETER Groupe
Le groupe de l'AD auquel ajouter les utilisateurs.
.PARAMETER Fichier
Fichier contenant les utilisateurs a ajouter au groupe. Un Id d'objet correspondant par ligne.
.EXAMPLE 
Monchemin\Add-GroupAD.ps1  -Groupe MonGroupe -Fichier MonFichier
#>
#Le fichier des utilisateurs a passer en parametre

param(
        [Parameter(Mandatory=$true)]
        [String]$Groupe,
        [Parameter(Mandatory=$true)]
        [String]$Fichier
)


#Variables
$NomLogs = "logs-Add-GroupeAD"
$Logs = "$PSScriptRoot\$NomLogs"
$date = Get-Date -Format "HHmmss_ddMMyyyy"
$Fichier = "$PSScriptRoot\$Fichier"



#Je teste si le fichier qui liste les utilisateurs existe
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

Write-Output "Generation des logs." 
Write-Output "$date : Debut de l'ajout au groupe $Groupe de l'AD." | Out-file "$Logs\$date.txt" 

#Je teste si le groupe existe; s'il existe, pas d'erreur (je redirige la sortie vers null); si erreur, je catch.
try { 
    Get-ADGroup -Identity $Groupe | Out-Null
    Write-Output "Le groupe $Groupe existe dans l'AD." | Out-file "$Logs\$date.txt"
} catch {
    Write-Output "Le groupe $Groupe n'existe pas dans l'AD." | Out-file "$Logs\$date.txt" 
    exit
}

#Je parse mon fichier utilisateurs pour recuperer les id users
foreach($name in Get-Content $Fichier) {
    try {
        Add-ADGroupMember -Identity $Groupe -Members $name -Confirm:$false
        Write-Output "$date AD OK : $name AJOUT AU GROUPE :  $Groupe"  | Out-file "$logs\$date.txt" -append
    } catch {
        Write-Output "$date AD ERREUR : $name AJOUT AU GROUPE :$Groupe"  | Out-file "$Logs\$date.txt" -append
    }
}
