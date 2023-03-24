<#
.DESCRIPTION
Script pour rechercher des comptes suspects avec des droits administrateurs sur les serveurs Windows dans l'AD.
#>


#Variables
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$Date= Get-Date -format yyyyMMdd
$FichierCsv ="$PSScriptRoot\ControleCompteAdmin-$Date.csv"
$FichierHtml ="$PSScriptRoot\ControleCompteAdmin-$Date.html"

if (((Test-Path $FichierCsv) -eq $false) -or ((Test-Path $FichierHtml) -eq $false)){ 
    New-Item $FichierCsv -Force | Out-Null
    New-Item $FichierHtml -Force | Out-Null
}
#J'ajoute les headers
("NomDuServeur;OperatingSystem;Status;AdresseIP;NomDuCompte;TypeDeCompte", (Get-Content -Path $FichierCsv)) | Set-Content $FichierCsv
#On recupere la liste des serveur dans l'AD
Get-ADComputer -Filter * -SearchBase  "OU=,OU=,OU=,DC=,DC=" -Property Name,Description,OperatingSystem | Select-Object -Property Name,Description,OperatingSystem | Sort-Object Name | Where-Object name -like "MonNommageDeServeur"  |

#Pour chaque serveur, je recupere l'adresse IP, le nom du serveur et l'OS
ForEach-Object { 
    $IPAddress =""
    $ServerName = $_.Name
    $ServerOS = $_.OperatingSystem

    #On ping pour verifier que le ServerName est en ligne
    $TestPing = Test-Connection $ServerName -Count 1 -ErrorAction SilentlyContinue
    if ($TestPing) {
        #On recupere l'adresse IP du ping dans la variable $IPAddress
        $IPAddress = ($TestPing.IPV4Address).IPAddressToString

        #Nom des groupes/users & Type de compte
        Get-WmiObject -Class Win32_GroupUser -ComputerName $ServerName -Filter "GroupComponent=""Win32_Group.Domain='$ServerName',Name='Administrateurs'""" | Select-Object PartComponent | ForEach-Object {`
            $nomcompte = (($_.partcomponent).split(",")[-1]).split("=")[-1] ;`
            $typecompte = ((($_.partcomponent).split(":")[-1]).split(",")[0]).split("_")[-1] ;`
            $resultat = -join($ServerName,";",$ServerOS,";","UP;$IPAddress",";",$nomcompte,";",$typecompte)
            Add-content $FichierCsv -value $Resultat -Encoding 'UTF8'
        }
    } else {    
        #Serveur Hors Ligne
        Add-content $FichierCsv -value "$ServerName; $ServerOS;DOWN;$IPAddress" -Encoding 'UTF8'
    }
}



##Generation du tableau HTML pour le mail (CSS/HTML)
$css = @"
    <style>
    h1, h5, th { text-align: center; font-family: Segoe UI; }
    table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
    th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
    td { font-size: 11px; padding: 5px 20px; color: #000; }
    tr { background: #b8d1f3; }
    tr:nth-child(even) { background: #dae5f4; }
    tr:nth-child(odd) { background: #b8d1f3; }
    </style>
"@
Import-Csv -Path $FichierCsv -Delimiter ";" <#-Header "HOSTNAME", "Operating System","Status","IP", "Nom User/Group","Type"#>| ConvertTo-Html -Head $css | Out-file $FichierHtml
#Configuration du mail
$SMTPServer = ""
$From = "" 
$TO = ""
$subject = ""
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$encoding = [System.text.encoding]::UTF8
$PJ="$FichierCsv","$FichierHtml"
$ServeurDown=Import-Csv $FichierCsv  -Delimiter ";"| Select-object NomDuServeur,OperatingSystem,Status | Where-Object -property Status -like "DOWN" | ConvertTo-Html -Head $css

 $MailBody =  "

        Ci-joint, le rapport hebdomadaire de controle des comptes administrateurs des serveurs Windows dans l'AD.<br>
        " + 

        "$(if (-not ([string]::IsNullOrEmpty($ServeurDown))){
            Write-Output "<br>ATTENTION<br>Les serveurs suivants sont injoignables:<br>"
            $ServeurDown
            }
        ) "+
        "<br>
        Cordialement."


#Envoi du mail
Send-MailMessage -To $TO -From $From -Subject $subject -Attachment $PJ -BodyAsHtml $MailBody -Credential (Get-Secret -vault MonVaultKeePass -name "MonEntreeKeePass") -SmtpServer $SMTPServer -UseSsl -Encoding $encoding
Remove-Item $FichierCsv 
Remove-Item $FichierHtml