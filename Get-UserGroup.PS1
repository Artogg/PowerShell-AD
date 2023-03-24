<#
.DESCRIPTION
Permet de rechercher les groupes auxquels appartient un utilisateur dans l'AD
.EXAMPLE
Get-UserGroup.ps1 MonUser
#>

param (
[parameter(ValueFromPipeline=$true)]
[string[]]$users)

begin {}

process {
	foreach($user in $users) {
		#Pour chaque utilisateur, je filtre l'AD sur les groupes auxquels il appartient
		#Je teste si l'objet existe dans l'AD, sinon je catch et passe a l'utilisateur suivant
		Try {
			$testad =$(Get-ADUser -Identity $user -ErrorAction SilentlyContinue)
			if ($testad -ne $false){
						#Je parse les groupes auxquels appartient l'objet
						Write-Output "***************************"
						Write-Output "L'utilisateur $user appartient aux groupes suivants:"
						(Get-ADUser -LDAPFilter "(SamAccountName=$user)" -Properties MemberOf).memberof | Get-ADGroup | Select-Object name
						Write-Output ""
			}
		} catch {
			Write-Output "***************************"
			Write-Output "L'utilisateur $user n'existe pas dans l'AD."
			Write-Output ""
		}
	}
}
