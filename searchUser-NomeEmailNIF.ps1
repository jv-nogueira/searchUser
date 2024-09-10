# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Lista de NIFs que deseja pesquisar
$userInfo = Read-Host "Digite o NIF, nome completo ou endereço de e-mail do usuário"   

# Função para executar o script
function ExecuteScript {
    param($property, $value)
    $Usuarios = Get-ADUser -Filter {$property -eq $value} -Properties Office, SamAccountName, DisplayName, EmailAddress, Title, telephoneNumber, Department, physicalDeliveryOfficeName, Name, Manager
    return $Usuarios
}

# Função para processar cada NIF na lista
function ProcessNIF {
    param($nif)
    $Usuarios = @()
    
    if ($nif -like "*@*") {
        Write-Output "Pesquisando por endereço de e-mail: $nif"
        $Usuarios = ExecuteScript -property "EmailAddress" -value $nif
    } elseif ($nif -match "\s") {
        Write-Output "Pesquisando por nome: $nif"
        $Usuarios = ExecuteScript -property "DisplayName" -value $nif
    } elseif ($nif -match "sn" -or $nif -match "ss") {
        Write-Output "Pesquisando pelo NIF: $nif"
        $Usuarios = ExecuteScript -property "SamAccountName" -value $nif
    } elseif ($nif -match "^\d+$") {
        $nifWithSN = "SN" + $nif
        Write-Output "Adicionado 'SN' ao número do NIF: $nifWithSN"
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithSN))

        $nifWithSS = "SS" + $nif
        Write-Output "Adicionado 'SS' ao número do NIF: $nifWithSS"
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithSS))

        $nifWithTC = "TC" + $nif
        Write-Output "Adicionado 'TC' ao número do NIF: $nifWithTC"
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithTC))
    } else {
        Write-Output "Formato de NIF não reconhecido: $nif"
        return @()
    }
    return $Usuarios
}

# Coletar todas as informações de usuários
$allUsers = @{}
foreach ($nif in $userInfo) {
    $users = ProcessNIF -nif $nif
    foreach ($user in $users) {
        if ($user -and $user.SamAccountName -and !$allUsers.ContainsKey($user.SamAccountName)) {
            $allUsers[$user.SamAccountName] = $user
        }
    }
}

# Verificar se algum usuário foi encontrado
if ($allUsers.Count -eq 0) {
    Write-Output "Nenhum usuário encontrado para os NIFs fornecidos."
    exit
}

# Exibir informações dos usuários
foreach ($Usuario in $allUsers.Values) {
    $nomeCompleto = if ($Usuario.DisplayName) { $Usuario.DisplayName } else { $Usuario.Name }
    $gerente = if ($Usuario.Manager -match "CN=([^,]+),") { $matches[1] } else { $Usuario.Manager }
    $output = @()
    
    $output += "NIF: $($Usuario.SamAccountName)"
    $output += "Nome completo: $nomeCompleto"
    
    if ($Usuario.Office -ne $Usuario.physicalDeliveryOfficeName) {
        if ($Usuario.Office) {
            $output += "Unidade: $($Usuario.Office)"
        }
        if ($Usuario.physicalDeliveryOfficeName) {
            $output += "Escritório: $($Usuario.physicalDeliveryOfficeName)"
        }
    } elseif ($Usuario.Office) {
        $output += "Unidade: $($Usuario.Office)"
    }
    
    if ($Usuario.Department) {
        $output += "Departamento: $($Usuario.Department)"
    }

    if ($gerente) {
        $output += "Superior imediato: $gerente"
    }
    
    if ($Usuario.Title) {
        $output += "Cargo: $($Usuario.Title)"
    }
    
    if ($Usuario.telephoneNumber) {
        $output += "Telefone: $($Usuario.telephoneNumber)"
    }
    
    if ($Usuario.EmailAddress) {
        $output += "E-mail: 
        $($Usuario.EmailAddress)"
    }
    
    Write-Output ""
    $output -join "`n"
    Write-Output ""
}

# Perguntar se deseja redefinir a senha para todos os usuários
$resetarSenha = Read-Host "Deseja resetar a senha de todos os usuários listados? Responda com S ou N"

if ($resetarSenha -eq "S") {
    foreach ($Usuario in $allUsers.Values) {
        if ($Usuario.SamAccountName) {
            $novaSenha = ConvertTo-SecureString -AsPlainText "Sesisenaisp@24" -Force
            Set-ADAccountPassword -Identity $Usuario.SamAccountName -NewPassword $novaSenha -Reset
            Set-ADUser -Identity $Usuario.SamAccountName -ChangePasswordAtLogon $true
            Write-Output "Senha redefinida com sucesso para o usuário: $($Usuario.DisplayName)"
        }
    }
} elseif ($resetarSenha -eq "N") {
    Write-Output "Operação cancelada."
} else {
    Write-Output "Resposta inválida. Operação cancelada."
}
