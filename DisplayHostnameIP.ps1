# Carrega o assembly do Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Função para obter informações da rede
function Get-NetworkInfo {
    $hostname = $env:COMPUTERNAME
    # Obtém as informações de IP usando Get-NetIPConfiguration
    $netInfo = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -ne $null }
    $ipv4 = $netInfo.IPv4Address.IPAddress
    return [PSCustomObject]@{
        Hostname = $hostname
        IPv4 = $ipv4
    }
}

# Formulário
$form = New-Object Windows.Forms.Form
$form.Text = "Info do PC"
$form.Size = New-Object Drawing.Size(285,600)
$form.StartPosition = "CenterScreen"

# Informações de rede
$networkInfo = Get-NetworkInfo

$positionEsquerda = 25
$tamanhoBtn = 220, 40

# Criando o botão para exibir o hostname
$labelHostname = New-Object Windows.Forms.Button
$labelHostname.Size = New-Object Drawing.Size($tamanhoBtn)
$labelHostname.Location = New-Object Drawing.Point($positionEsquerda, 30)  # Posição X = 25 (esquerda)
$labelHostname.Text = "Hostname: " + $networkInfo.Hostname
$labelHostname.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft  # Alinha o texto à esquerda

# Criando um ToolTip para o botão
$toolTipHostname = New-Object Windows.Forms.ToolTip
$toolTipHostname.SetToolTip($labelHostname, "Copiar")

# Evento de clique para copiar o hostname
$labelHostname.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($networkInfo.Hostname)
})

$form.Controls.Add($labelHostname)

# Criando o botão para exibir o IPv4
$labelIPv4 = New-Object Windows.Forms.Button
$labelIPv4.Size = New-Object Drawing.Size($tamanhoBtn)
$labelIPv4.Location = New-Object Drawing.Point($positionEsquerda, 70)  # Posição X = 25 (esquerda)
$labelIPv4.Text = "IPv4: " + $networkInfo.IPv4
$labelIPv4.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft  # Alinha o texto à esquerda

# Criando um ToolTip para o botão
$toolTipIPv4 = New-Object Windows.Forms.ToolTip
$toolTipIPv4.SetToolTip($labelIPv4, "Copiar")

# Evento de clique para copiar o IPv4
$labelIPv4.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($networkInfo.IPv4)
})

$form.Controls.Add($labelIPv4)



# Criando o botão para exibir o SN (Serial Number)
$labelSN = New-Object Windows.Forms.Button
$labelSN.Size = New-Object Drawing.Size($tamanhoBtn)
$labelSN.Location = New-Object Drawing.Point($positionEsquerda, 110)  # Posição X = 25 (esquerda)
$labelSN.Text = "SN: " + (Get-ComputerInfo).BiosSeralNumber.Trim()
$labelSN.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft  # Alinha o texto à esquerda

# Criando um ToolTip para o botão
$toolTipSN = New-Object Windows.Forms.ToolTip
$toolTipSN.SetToolTip($labelSN, "Copiar")

# Evento de clique para copiar o SN
$labelSN.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ComputerInfo).BiosSeralNumber)
})

$form.Controls.Add($labelSN)


# Criando o botão para exibir a versão do Windows
$labelWinver = New-Object Windows.Forms.Button
$labelWinver.Size = New-Object Drawing.Size($tamanhoBtn)
$labelWinver.Location = New-Object Drawing.Point($positionEsquerda, 150)  # Posição X = 25 (esquerda)
$labelWinver.Text = "Versão do Windows: " + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
$labelWinver.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft  # Alinha o texto à esquerda

# Criando um ToolTip para o botão
$toolTipWinver = New-Object Windows.Forms.ToolTip
$toolTipWinver.SetToolTip($labelWinver, "Copiar")
$form.Controls.Add($labelWinver)

# Evento de clique para copiar a versão do Windows
$labelWinver.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion)
})

# Criando o botão para exibir o nome do sistema operacional
$labelOSName = New-Object Windows.Forms.Button
$labelOSName.Size = New-Object Drawing.Size($tamanhoBtn)
$labelOSName.Location = New-Object Drawing.Point($positionEsquerda, 190)  # Posição X = 50, Y = 30
$labelOSName.Text = "SO: " + (Get-ComputerInfo).OsName
$labelOSName.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

# Criando um ToolTip para o botão
$toolTipOSName = New-Object Windows.Forms.ToolTip
$toolTipOSName.SetToolTip($labelOSName, "Copiar")
$form.Controls.Add($labelOSName)

# Evento de clique para exibir o nome do sistema operacional
$labelOSName.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ComputerInfo).OsName)
})

$form.Controls.Add($labelOSName)


# Função para obter a memória física total
function Get-TotalMemory {
    $physicalMemoryTotal = (Get-ComputerInfo).OsTotalVisibleMemorySize
    $physicalMemoryTotalMB = [math]::round($physicalMemoryTotal / 1024, 2)  # KB para MB
    $physicalMemoryTotalGB = [math]::round($physicalMemoryTotalMB / 1024, 2)  # MB para GB
    return "$physicalMemoryTotalGB GB"
}

# Função para obter a memória física disponível
function Get-AvailableMemory {
    $physicalMemoryFree = (Get-ComputerInfo).OsFreePhysicalMemory
    $physicalMemoryFreeMB = [math]::round($physicalMemoryFree / 1024, 2)
    $physicalMemoryFreeGB = [math]::round($physicalMemoryFreeMB / 1024, 2)
    return "$physicalMemoryFreeGB GB"
}

# Função para obter o tamanho do HD
function Get-HDDSize {
    $diskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -First 1
    $sizeInGB = [math]::round($diskInfo.Size / 1GB, 2)  # Cálculo do tamanho em GB
    return "$sizeInGB GB"  # Adiciona " GB" à string após o cálculo
}

# Criando o botão para exibir o fabricante do sistema
$labelManufacturer = New-Object Windows.Forms.Button
$labelManufacturer.Size = New-Object Drawing.Size($tamanhoBtn)
$labelManufacturer.Location = New-Object Drawing.Point($positionEsquerda, 230)
$labelManufacturer.Text = "Fabricante: " + (Get-ComputerInfo).CsManufacturer
$labelManufacturer.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelManufacturer.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ComputerInfo).CsManufacturer)
})

# Criando um ToolTip para o botão
$toolTipFabricante = New-Object Windows.Forms.ToolTip
$toolTipFabricante.SetToolTip($labelManufacturer, "Copiar")
$form.Controls.Add($labelManufacturer)

# Criando o botão para exibir o modelo do sistema
$labelModel = New-Object Windows.Forms.Button
$labelModel.Size = New-Object Drawing.Size($tamanhoBtn)
$labelModel.Location = New-Object Drawing.Point($positionEsquerda, 270)
$labelModel.Text = "Modelo: " + (Get-ComputerInfo).CsModel
$labelModel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelModel.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ComputerInfo).CsModel)
})
# Criando um ToolTip para o botão
$toolTipModelo = New-Object Windows.Forms.ToolTip
$toolTipModelo.SetToolTip($labelModel, "Copiar")
$form.Controls.Add($labelModel)


# Criando o botão para exibir os processadores
$labelProcessors = New-Object Windows.Forms.Button
$labelProcessors.Size = New-Object Drawing.Size($tamanhoBtn)
$labelProcessors.Location = New-Object Drawing.Point($positionEsquerda, 310)
$labelProcessors.Text = "Processador: " + (Get-ComputerInfo).CsProcessors.Name
$labelProcessors.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelProcessors.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ComputerInfo).CsProcessors.Name)
})
# Criando um ToolTip para o botão
$toolTipProcessors = New-Object Windows.Forms.ToolTip
$toolTipProcessors.SetToolTip($labelProcessors, "Copiar")
$form.Controls.Add($labelProcessors)

# Criando o botão para exibir a memória física total
$labelTotalMemory = New-Object Windows.Forms.Button
$labelTotalMemory.Size = New-Object Drawing.Size($tamanhoBtn)
$labelTotalMemory.Location = New-Object Drawing.Point($positionEsquerda, 350)
$labelTotalMemory.Text = "Memória Total: " + (Get-TotalMemory)
$labelTotalMemory.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelTotalMemory.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-TotalMemory))
})
# Criando um ToolTip para o botão
$toolTipTotalMemory = New-Object Windows.Forms.ToolTip
$toolTipTotalMemory.SetToolTip($labelTotalMemory, "Copiar")
$form.Controls.Add($labelTotalMemory)

# Criando o botão para exibir a memória física disponível
$labelAvailableMemory = New-Object Windows.Forms.Button
$labelAvailableMemory.Size = New-Object Drawing.Size($tamanhoBtn)
$labelAvailableMemory.Location = New-Object Drawing.Point($positionEsquerda, 390)
$labelAvailableMemory.Text = "Memória Disponível: " + (Get-AvailableMemory)
$labelAvailableMemory.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelAvailableMemory.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-AvailableMemory))
})
# Criando um ToolTip para o botão
$toolTipAvailableMemory = New-Object Windows.Forms.ToolTip
$toolTipAvailableMemory.SetToolTip($labelAvailableMemory, "Copiar")
$form.Controls.Add($labelAvailableMemory)

# Criando o botão para exibir o domínio
$labelDomain = New-Object Windows.Forms.Button
$labelDomain.Size = New-Object Drawing.Size($tamanhoBtn)
$labelDomain.Location = New-Object Drawing.Point($positionEsquerda, 430)
$labelDomain.Text = "Domínio: " + (Get-Domain)
$labelDomain.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelDomain.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ComputerInfo).CsWorkgroup)
})
# Criando um ToolTip para o botão
$toolTipDomain = New-Object Windows.Forms.ToolTip
$toolTipDomain.SetToolTip($labelDomain, "Copiar")
$form.Controls.Add($labelDomain)

# Criando o botão para exibir o tamanho do HD
$labelHDDSize = New-Object Windows.Forms.Button
$labelHDDSize.Size = New-Object Drawing.Size($tamanhoBtn)
$labelHDDSize.Location = New-Object Drawing.Point($positionEsquerda, 470)
$labelHDDSize.Text = "Tamanho do HD: " + (Get-HDDSize)
$labelHDDSize.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$labelHDDSize.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-HDDSize))
})
# Criando um ToolTip para o botão
$toolTipHDDSize = New-Object Windows.Forms.ToolTip
$toolTipHDDSize.SetToolTip($labelHDDSize, "Copiar")
$form.Controls.Add($labelHDDSize)

# Criando o botão para copiar todas as informações
$labelAllCopy = New-Object Windows.Forms.Button
$labelAllCopy.Size = New-Object Drawing.Size(150,20)
$labelAllCopy.Location = New-Object Drawing.Point($positionEsquerda, 530)
$labelAllCopy.Text = "Copiar tudo"
$labelAllCopy.Add_Click({

    # Obtém as informações que você quer adicionar ao clipboard
    $networkInfo = Get-NetworkInfo
    $hostname = $networkInfo.Hostname
    $ipv4 = $networkInfo.IPv4
    $serialNumber = (Get-ComputerInfo).BiosSeralNumber.Trim()
    $winVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $osName = (Get-ComputerInfo).OsName
    $hddSize = Get-HDDSize
    $totalMemory = Get-TotalMemory
    $availableMemory = Get-AvailableMemory
    $manufacturer = (Get-ComputerInfo).CsManufacturer
    $model = (Get-ComputerInfo).CsModel
    $processors = (Get-ComputerInfo).CsProcessors.Name
    $workgroup = (Get-ComputerInfo).CsWorkgroup

    # Cria o conteúdo concatenado com quebras de linha
    $newClipboardContent = @"
Hostname: $hostname
IPv4: $ipv4
SN: $serialNumber
Versão do Windows: $winVersion
SO: $osName
Tamanho do HD: $hddSize
Memória Total: $totalMemory
Memória Disponível: $availableMemory
Fabricante: $manufacturer
Modelo: $model
Processador: $processors
Domínio/Grupo de Trabalho: $workgroup
"@

    # Define o conteúdo final no clipboard
    [System.Windows.Forms.Clipboard]::SetText($newClipboardContent)
})

# Criando um ToolTip para o botão
$toolTipAllCopy = New-Object Windows.Forms.ToolTip
$toolTipAllCopy.SetToolTip($labelAllCopy, "Copiar todas as informações acima")
$form.Controls.Add($labelAllCopy)



# Exibe o formulário
$form.ShowDialog()
