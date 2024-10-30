# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Solicitar o SamAccountName do usuário para pesquisa
$SamAccountName = Read-Host "Digite o NIF do usuário"

# Função para executar a pesquisa no Active Directory pelo SamAccountName
function ExecuteScript {
    param($value)
    $Usuarios = Get-ADUser -Filter {SamAccountName -eq $value} -Properties Office, SamAccountName, DisplayName, EmailAddress, Title, telephoneNumber, Department, physicalDeliveryOfficeName, Manager, msExchHideFromAddressLists, proxyAddresses, extensionAttribute1
    return $Usuarios
}

# Executar a pesquisa
$Usuarios = ExecuteScript -value $SamAccountName

# Verificar se o usuário foi encontrado
if ($Usuarios -eq $null) {
    Write-Output "Nenhum usuário encontrado com o SamAccountName: $SamAccountName"
    exit
}

# Exibir informações dos usuários encontrados
foreach ($Usuario in $Usuarios) {
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
        $output += "E-mail: $($Usuario.EmailAddress)"
        $output += ""  # Adicionar linha em branco após o e-mail
    } else {
        $output += "E-mail: Não definido"
        $output += ""  # Adicionar linha em branco após "E-mail: Não definido"
    }

    # Adicionar informações dos atributos adicionais
    $output += "msExchHideFromAddressLists: $(
        if ($Usuario.msExchHideFromAddressLists) { $Usuario.msExchHideFromAddressLists } else { 'Não definido' }
    )"
    $output += "proxyAddresses: $(
        if ($Usuario.proxyAddresses) { $Usuario.proxyAddresses -join ', ' } else { 'Não definido' }
    )"
    $output += "extensionAttribute1: $(
        if ($Usuario.extensionAttribute1) { $Usuario.extensionAttribute1 } else { 'Não definido' }
    )"
    
    Write-Output ""
    $output -join "`n"
    Write-Output ""
}

# Perguntar pelo endereço de e-mail para proxyAddress
$proxyEmail = Read-Host "Digite o endereço de e-mail para proxyAddress (SMTP)"

# Modificar atributos de todos os usuários encontrados
foreach ($Usuario in $Usuarios) {
    try {
        Set-ADUser -Identity $Usuario -Replace @{msExchHideFromAddressLists=$true; extensionAttribute1="Office365"}
        Set-ADUser -Identity $Usuario -Add @{proxyAddresses="SMTP:$proxyEmail"}
        Write-Output "Modificações realizadas com sucesso para o usuário: $($Usuario.DisplayName)"
    } catch {
        Write-Output "Erro ao modificar o usuário $($Usuario.DisplayName): $_"
    }
}
