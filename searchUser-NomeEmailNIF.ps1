# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Substituir pelo nome de usuário completo que deseja pesquisar
$userInfo = "1079520"

# Função para executar o script
function ExecuteScript {
    param($property, $value)

    # Propriedades que vão ser filtradas
    $Usuarios = Get-ADUser -Filter {$property -eq $value} -Properties Office, SamAccountName, DisplayName, EmailAddress 

    # Verificar se o usuário foi encontrado
    if ($Usuarios) {
        foreach ($Usuario in $Usuarios) {
            Write-Output ""
            Write-Output @"
        NIF: $($Usuario.SamAccountName)  
        Nome completo: $($Usuario.DisplayName)
        Unidade: $($Usuario.Office)
        E-mail: $($Usuario.EmailAddress)
"@
        }
    } else {
        Write-Output "Usuário não encontrado para '$value'."
    }
}

# Verifica se $userInfo contém "@" para procurar somente por EmailAddress
if ($userInfo -like "*@*") {
    Write-Output "Pesquisando por endereço de e-mail."
    # Execute seu script aqui
    ExecuteScript -property "EmailAddress" -value $userInfo
}
# Verifica se $userInfo não contém números e nem "@" para procurar por SamAccountName
elseif ($userInfo -match "\s") {
    Write-Output "Pesquisando por nome."
    # Execute seu script aqui
    ExecuteScript -property "SamAccountName" -value $userInfo
}
# Pesquisar o NIF contem "SS" ou "SN"
elseif ($userInfo -match "sn" -or $userInfo -match "ss") {
    Write-Output "Pesquisando pelo NIF."
    # Execute seu script aqui
    ExecuteScript -property "SamAccountName" -value $userInfo
}
# Pesquisar o NIF se conter apenas números
elseif ($userInfo -match "^\d+$"){
# Adiciona "SN" ao número do NIF e executa o script
    $userInfoWithSN = "SN" + $userInfo
    Write-Output "Adicionado 'SN' ao número do NIF: $userInfoWithSN"
    # Execute seu script aqui usando $userInfoWithSN
    ExecuteScript -property "SamAccountName" -value $userInfoWithSN

    # Adiciona "SS" ao número do NIF e executa o script
    $userInfoWithSS = "SS" + $userInfo
    Write-Output "Adicionado 'SS' ao número do NIF: $userInfoWithSS"
    # Execute seu script aqui usando $userInfoWithSS
    ExecuteScript -property "SamAccountName" -value $userInfoWithSS
}else{
Write-Output "Nao encontrado."
}
