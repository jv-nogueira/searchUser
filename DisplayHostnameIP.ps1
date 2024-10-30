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

# Criação do Formulário
$form = New-Object Windows.Forms.Form
$form.Text = "Informações de Rede"
$form.Size = New-Object Drawing.Size(350,200)
$form.StartPosition = "CenterScreen"

# Obtém as informações de rede
$networkInfo = Get-NetworkInfo

# Criação do label para exibir o hostname
$labelHostname = New-Object Windows.Forms.Label
$labelHostname.Size = New-Object Drawing.Size(200,30)
$labelHostname.Location = New-Object Drawing.Point(25, 30)
$labelHostname.Text = "Hostname: " + $networkInfo.Hostname
$form.Controls.Add($labelHostname)

# Criação do botão para copiar o hostname
$btnCopyHostname = New-Object Windows.Forms.Button
$btnCopyHostname.Size = New-Object Drawing.Size(100,30)
$btnCopyHostname.Location = New-Object Drawing.Point(230, 30)
$btnCopyHostname.Text = "Copiar"
$btnCopyHostname.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($networkInfo.Hostname)
})
$form.Controls.Add($btnCopyHostname)

# Criação do label para exibir o IPv4
$labelIPv4 = New-Object Windows.Forms.Label
$labelIPv4.Size = New-Object Drawing.Size(200,30)
$labelIPv4.Location = New-Object Drawing.Point(25, 70)
$labelIPv4.Text = "IPv4: " + $networkInfo.IPv4
$form.Controls.Add($labelIPv4)

# Criação do botão para copiar o IPv4
$btnCopyIPv4 = New-Object Windows.Forms.Button
$btnCopyIPv4.Size = New-Object Drawing.Size(100,30)
$btnCopyIPv4.Location = New-Object Drawing.Point(230, 70)
$btnCopyIPv4.Text = "Copiar"
$btnCopyIPv4.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($networkInfo.IPv4)
})
$form.Controls.Add($btnCopyIPv4)

# Exibe o formulário
$form.ShowDialog()
