<#
.DESCRIPTION
Script pour rechercher les informations reseaux liees a un ou des PMF (DHCP, DNS, MAC) via son nom de machine.
.PARAMETER poste
Le nom de la/les machines / poste.
On peut lister les machines en les separants par une virgule (SANS ESPACE)
.PARAMETER Export
Si on veut exporter sous format csv
.EXAMPLE
Get-pmf poste1
Get-pmf poste1,poste12
Get-pmf poste1 -Export monfichier
Get-pmf poste1 monfichier
#>

#On accepte en parametre du script un array de noms de machines
param (
    [parameter(ValueFromPipeline = $true)]
    [string[]]$postes,
    [parameter()]
    [String]$Export
)

begin {

}


process {
    $Boucle = 0
    $ServerDhcp

    #Je teste si le fichier a la bonne extension
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

    #Je teste si la machine existe dans l'AD
    foreach ($poste in $postes) {
        try {
            $TestAD = Get-ADComputer $poste
        }
        #Si n'existe pas, je catch l'erreur
        catch {
            $AD_Result =  "AD ERREUR: $_.Exception.Message " 
            Write-Host -ForegroundColor red $AD_Result
        }

        #Pour chaque machine, j'interroge le serveur DHCP et je recupere les infos que je stocke dans un tableau
        #J'exclues les Ip phones
        (Get-DhcpServerv4Scope -ComputerName ServerDhcp).ScopeID | Where-Object { $_.IPAddressToString -notlike "RangeIpPhone" } | ForEach-Object {
            Get-DhcpServerv4Lease -ComputerName ServerDhcp -ScopeId $_ | Where-Object { $_.hostname -match $oste } } | ForEach-Object {
                $InfoDhcp = [PSCustomObject] @{
                    "Scope DHCP"= $_.ScopeId
                    "Adresse IP"= $_.ipaddress
                    "DNS"= $_.hostname
                    "Adresse Mac"= $_.clientid
                    "Status"= $_.addressstate
                    
                }
                #Le meme objet mais je rajoute la cle du commentaire
                if($ExportValide -eq "oui"){
                    $InfoDhcpExport = [PSCustomObject] @{
                        "Scope DHCP"= $_.ScopeId
                        "Adresse IP"= $_.ipaddress
                        "DNS"= $_.hostname
                        "Adresse Mac"= $_.clientid
                        "Status"= $_.addressstate                       
                        "Commentaire"=""
                    }
                }

            
            
            #Je teste en fonction de l'IP pour savoir ou se trouve le poste
            #Je teste si on peut pinguer la machine
            #Write-Output "Test du ping vers $poste"
            if (Test-Connection $_.ipaddress -Count 3 -Quiet) {
       
                    Write-Output "********************************************"
                    Write-Host -ForegroundColor Cyan "Poste $($_.hostname) "
                    $InfoDhcp   
                    $LastUser = (Get-WmiObject -Class win32_computersystem -ComputerName $_.hostname).UserName
                    Write-Host -ForegroundColor Yellow "Last User Logged :  $LastUser"
                    #Si j'exporte, alors j'ajoute le commentaire a mon objet
                    if($ExportValide -eq "oui"){
                        $InfoDhcpExport."Commentaire" = "MonCommentaire / Faire une boucle avec une exception"
                    }
                    Write-Output "********************************************`n"
                    

           }
            #Si la machine ne ping pas, elle est eteinte (ou injoignable via le reseau)
            } else {
                Write-Output "********************************************"
                Write-Host -ForegroundColor Red "poste $($_.hostname) INJOIGNABLE"
                if($ExportValide -eq "oui"){
                    $InfoDhcpExport."Commentaire" = "poste eteint ou injoignable"
                }
                $InfoDhcp
                Write-Output "********************************************`n"
            }
            #Si j'exporte, pour la premiere boucle je cree le fichier csv et j'utilise les champs comme nom de colonnes
            if($Export -ne ''){
                if ($Boucle -eq 0){
                    $InfoDhcpExport | Export-Csv -NoTypeInformation -path $Export
                    $Boucle = 1
                } else {
                    #pour les autres boucles, j'ajoute au fichier csv
                    $InfoDhcpExport | Export-csv -Append -NoTypeInformation -path $Export
                }

            }
         }
    }
}

 