<#
.DESCRIPTION
Creation des groupes dans l'AD
.PARAMETER NomGroup
Le nom du groupe a creer, sans les suffixes/prefixes custom
.PARAMETER TypeGroup
Le type du groupe a creer, accepter "ct", "ls" ou "ctls" ou "lsct" (Controle Total, Lecture Seule ou les deux groupes)
.EXAMPLE
Set-GroupAD.ps1 mongroupe ct
Set-GroupeAD.ps1 -NomGroup mongroupe -TypeGroupe ctls
#>



param (
    [parameter()]
    [string[]]$NomGroupe,
    [parameter()]
    [String]$TypeGroup
)

begin {}

Process{
    Import-Module ActiveDirectory

    #Je teste si le nom du groupe est renseigne
    if($NomGroupe -eq ''){
        Write-Output "Le nom du groupe est vide."
        exit
    }


    #Je teste si le type de groupe est renseigne cad entre 2 et 4 caracteres, et de la forme ls ou ct
    if(($TypeGroup.length -ge 2) -and ($TypeGroup.length -le 4) -and ($TypeGroup.length -ne 3)){
        if ($TypeGroup -like "*ct*"){
            #Formate le nom du groupe en ajoutant les prefixes / suffixes pour les groupes locaux/globaux
            $GL = "le $nom_groupe et les suffixes/prefixes"
            $GG = "le $nom_groupe et les suffixes/prefixes"
            #Creer les groupes local/global
            New-ADGroup $GL -Path "OU=,OU=,OU=,DC=,DC=" -GroupCategory "Security" -GroupScope "DomainLocal" -description "Groupe Local $nom_groupe"
            New-ADGroup $GG -Path "OU=,OU=,OU=,DC=,DC=" -GroupCategory "Security" -GroupScope "Global" -description "Groupe Global $nom_groupe" 

            #Ajoute le groupe global en membre du groupe local
            Add-ADGroupMember -Identity $GL -Members $GG
        } elseif ($TypeGroup -like "*ls*"){
            #Formate le nom du groupe en ajoutant les prefixes / suffixes
            $GLLS = "le $nom_groupe et les suffixes/prefixes"
            $GGLS = "le $nom_groupe et les suffixes/prefixes"
            #Creer les groupes local/global pour la LS
            New-ADGroup $GLLS -Path "OU=,OU=,OU=,DC=,DC="-GroupCategory "Security" -GroupScope "DomainLocal" -description "Groupe Local $nom_groupe => LS"
            New-ADGroup $GGLS -Path "OU=,OU=,OU=,DC=,DC=" -GroupCategory "Security" -GroupScope "Global" -description "Groupe Global $nom_groupe => LS" 

            #Ajoute le groupe global en membre du groupe local
            Add-ADGroupMember -Identity $GLLS -Members $GGLS
        } else {
            Write-Output "Mauvaise syntaxe du type de groupe."
            Exit
        }
    } else {
        Write-Output "Verifier la syntaxe du type de groupe."
        Exit
    }
}





