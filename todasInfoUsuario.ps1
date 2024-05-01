# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Substitua "pesquisar aqui" pelo endereço de e-mail ou nome do usuário que deseja pesquisar
$userInfo = "rubia.dias@sesisp.org.br"

# Substituir por “EmailAddress” ou “Name”
$Usuario = Get-ADUser -Filter {EmailAddress -eq $userInfo} -Properties *

# Verificar se o usuário foi encontrado
if ($Usuario) {
    Write-Output $Usuario
} else {
    Write-Output "Usuário não encontrado."
}
