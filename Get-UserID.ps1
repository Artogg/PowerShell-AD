param (
[parameter(ValueFromPipeline=$true)]
[string]$user)

begin {}
process {
    foreach($resultuser in $user) {
        
        try{
            
            $Resultat = (Get-ADUser  -SearchBase "OU=,OU=,OU=,DC=,DC=" -LDAPFilter "(SamAccountName=*$user*)" | Select Name,SamAccountName).name
        }
        catch{
            
            Write-Host " ** AD ERREUR ** : $line - $_.Exception.Message ** "  -ForegroundColor Red
        }

        if ( $null -eq $Resultat ){

            write-host -ForegroundColor Yellow "$user INEXISTANT"
        }
        else {
            
            write-host $Resultat
        }
    }
}