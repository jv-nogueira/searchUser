# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Função para extrair o nome do grupo do DN
function Get-GroupNameFromDN {
    param (
        [string]$dn
    )
    return ($dn -split ',')[0] -replace '^CN=', ''
}

# Função para obter informações detalhadas do usuário
function Get-UserInfo {
    param (
        [string]$userIdentifier
    )
    $user = Get-ADUser -Filter { SamAccountName -eq $userIdentifier -or EmailAddress -eq $userIdentifier -or DisplayName -eq $userIdentifier } -Property SamAccountName, DisplayName, EmailAddress, Title, Department, Office, telephoneNumber, physicalDeliveryOfficeName, Manager
    return $user
}

# Função para obter grupos do usuário
function Get-UserGroups {
    param (
        [string]$userIdentifier
    )
    $user = Get-ADUser -Identity $userIdentifier -Property MemberOf
    return $user.MemberOf
}

# Função para exibir informações detalhadas do usuário e seus grupos
function Display-UserInfoAndGroups {
    param (
        [Microsoft.ActiveDirectory.Management.ADUser]$user
    )
    $nomeCompleto = if ($user.DisplayName) { $user.DisplayName } else { $user.Name }
    $gerente = if ($user.Manager -match "CN=([^,]+),") { $matches[1] } else { $user.Manager }
    $output = @()
    
    $output += "NIF: $($user.SamAccountName)"
    $output += "Nome completo: $nomeCompleto"
    
    if ($user.Office -ne $user.physicalDeliveryOfficeName) {
        if ($user.Office) {
            $output += "Unidade: $($user.Office)"
        }
        if ($user.physicalDeliveryOfficeName) {
            $output += "Escritório: $($user.physicalDeliveryOfficeName)"
        }
    } elseif ($user.Office) {
        $output += "Unidade: $($user.Office)"
    }
    
    if ($user.Department) {
        $output += "Departamento: $($user.Department)"
    }

    if ($gerente) {
        $output += "Superior imediato: $gerente"
    }
    
    if ($user.Title) {
        $output += "Cargo: $($user.Title)"
    }
    
    if ($user.telephoneNumber) {
        $output += "Telefone: $($user.telephoneNumber)"
    }
    
    if ($user.EmailAddress) {
        $output += "E-mail: $($user.EmailAddress)"
    }
    
    Write-Output ""
    $output -join "`n"
    Write-Output ""
    
    # Obter e imprimir os grupos do usuário
    $groups = Get-UserGroups -userIdentifier $user.SamAccountName
    Write-Output "Grupos do usuário ($($user.SamAccountName)):"
    if ($groups.Count -eq 0) {
        Write-Output "O usuário não pertence a nenhum grupo."
    } else {
        $groups | ForEach-Object { Write-Output (Get-GroupNameFromDN $_) }
    }
    Write-Output ""
}

# Perguntar pelo usuário de origem
$sourceUserInput = Read-Host "Digite o NIF, nome completo ou endereço de e-mail do usuário de origem"
$sourceUser = Get-UserInfo -userIdentifier $sourceUserInput
if ($sourceUser -eq $null) {
    Write-Host "Usuário de origem não encontrado. Operação cancelada."
    exit
}

# Exibir informações do usuário de origem e confirmar
Display-UserInfoAndGroups -user $sourceUser
$confirmSource = Read-Host "Esse é o usuário de origem para o espelhamento? Responda com S ou N"
if ($confirmSource -ne "S") {
    Write-Host "Operação cancelada."
    exit
}

# Perguntar pelo usuário de destino
$destinationUserInput = Read-Host "Digite o NIF, nome completo ou endereço de e-mail do usuário de destino"
$destinationUser = Get-UserInfo -userIdentifier $destinationUserInput
if ($destinationUser -eq $null) {
    Write-Host "Usuário de destino não encontrado. Operação cancelada."
    exit
}

# Exibir informações do usuário de destino e confirmar
Display-UserInfoAndGroups -user $destinationUser
$confirmDestination = Read-Host "Esse é o usuário de destino para o espelhamento? Responda com S ou N"
if ($confirmDestination -ne "S") {
    Write-Host "Operação cancelada."
    exit
}

# Confirmar espelhamento
$confirmMirror = Read-Host "Deseja espelhar os grupos do usuário de origem para o usuário de destino? Responda com S ou N"
if ($confirmMirror -ne "S") {
    Write-Host "Operação cancelada."
    exit
}

# Adicionar o usuário de destino aos grupos do usuário de origem
$sourceGroups = Get-UserGroups -userIdentifier $sourceUser.SamAccountName
foreach ($group in $sourceGroups) {
    Add-ADGroupMember -Identity $group -Members $destinationUser.SamAccountName
}

Write-Host "`nOs grupos do usuário $($sourceUser.SamAccountName) foram copiados para o usuário $($destinationUser.SamAccountName)."
