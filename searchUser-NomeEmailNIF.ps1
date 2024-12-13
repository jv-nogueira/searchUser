# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Criar a função de interface GUI
function Create-GUI {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    # Janela principal (form)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Pesquisa de Usuários AD"
    $form.Size = New-Object System.Drawing.Size(360,500) #340 de largura total
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false  # Desabilitar o botão de maximizar
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    # TextBox para entrada de NIF, Email ou Nome Completo
    $textBoxNIF = New-Object System.Windows.Forms.TextBox
    $textBoxNIF.Location = New-Object System.Drawing.Point(20,20) # 20p depois da borda
    $textBoxNIF.Size = New-Object System.Drawing.Size(310,20) # 300p de largura
    $textBoxNIF.Text = "Digite o NIF, Email ou Nome Completo e dê Enter"
    $form.Controls.Add($textBoxNIF)


        # Label para perguntar sobre copiar o painel
        $labelResetSenha = New-Object System.Windows.Forms.Label
        $labelResetSenha.Location = New-Object System.Drawing.Point(20,50)
        $labelResetSenha.Size = New-Object System.Drawing.Size(210,15)
        $labelResetSenha.Text = "Copiar o e-mail do usuário no painel?"
        $form.Controls.Add($labelResetSenha)

    # Botão para copiar os resultados
    $buttonCopiar = New-Object System.Windows.Forms.Button
    $buttonCopiar.Location = New-Object System.Drawing.Point(235,45)
    $buttonCopiar.Size = New-Object System.Drawing.Size(75,20) # largura / altura
    $buttonCopiar.Text = "Copiar"
    $form.Controls.Add($buttonCopiar)

        # Painel para exibir os resultados
    $panelResultados = New-Object System.Windows.Forms.TextBox
    $panelResultados.Location = New-Object System.Drawing.Point(20,70)
    $panelResultados.Size = New-Object System.Drawing.Size(310,300)  # Ajustado até o botão de copiar
    $panelResultados.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

    $panelResultados.ReadOnly = $true         # Tornar a caixa de texto somente leitura, mas ainda copiável
    $panelResultados.Multiline = $true        # Permite múltiplas linhas
    $form.Controls.Add($panelResultados)

        # TextBox para permitir a entrada da nova senha
        $textBoxResetSenha = New-Object System.Windows.Forms.TextBox
        $textBoxResetSenha.Location = New-Object System.Drawing.Point(20,380)
        $textBoxResetSenha.Size = New-Object System.Drawing.Size(210,20)
        $textBoxResetSenha.Text = "Sesisenaisp@24" # Valor padrão
        $form.Controls.Add($textBoxResetSenha)

    # Botão para redefinir a senha
    $buttonReset = New-Object System.Windows.Forms.Button
    $buttonReset.Location = New-Object System.Drawing.Point(235,380)
    $buttonReset.Size = New-Object System.Drawing.Size(75,20)
    $buttonReset.Text = "Reset"
    $form.Controls.Add($buttonReset)


# Função para exibir os resultados no painel (como TextBox de múltiplas linhas)
function ExibirResultados {
    $panelResultados.Clear()
    $global:EmailAtual = ""  # Limpar o valor do e-mail global antes de cada nova pesquisa
    $userInfo = $textBoxNIF.Text
    $global:Usuarios = ProcessNIF -nif $userInfo

    if ($global:Usuarios.Count -eq 0) {
        $panelResultados.Text = "Nenhum usuário encontrado."
    } else {
        $infoUsuarios = @()
        foreach ($Usuario in $global:Usuarios) {
            if ($Usuario.EmailAddress) {
                $global:EmailAtual = $Usuario.EmailAddress  # Definir o e-mail global se encontrado
            }

            $infoUsuario = @()

            if ($Usuario.SamAccountName) {
                $infoUsuario += "NIF: $($Usuario.SamAccountName)"
            }
            if ($Usuario.DisplayName) {
                $infoUsuario += "Nome completo: $($Usuario.DisplayName)"
            }
            if ($Usuario.Office) {
                $infoUsuario += "Unidade: $($Usuario.Office)"
            }
            if ($Usuario.physicalDeliveryOfficeName) {
                $infoUsuario += "Escritório: $($Usuario.physicalDeliveryOfficeName)"
            }
            if ($Usuario.Department) {
                $infoUsuario += "Departamento: $($Usuario.Department)"
            }
            if ($Usuario.Manager -match "CN=([^,]+),") {
                $infoUsuario += "Superior imediato: $($matches[1])"
            }
            if ($Usuario.Title) {
                $infoUsuario += "Cargo: $($Usuario.Title)"
            }
            if ($Usuario.telephoneNumber) {
                $infoUsuario += "Telefone: $($Usuario.telephoneNumber)"
            }
            if ($Usuario.EmailAddress) {
                $infoUsuario += "E-mail: $($Usuario.EmailAddress)"
            }

            if ($infoUsuario.Count -gt 0) {
                $infoUsuarios += ($infoUsuario -join "`r`n")
            }
        }
        # Exibir todos os resultados na TextBox
        $panelResultados.Text = $infoUsuarios -join "`r`n`r`n"  # Adicionar espaço entre os usuários
    }
}


# Evento para capturar o pressionamento da tecla "Enter" e remover espaços em branco do início e do final da textBox
$textBoxNIF.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $trimmedText = $textBoxNIF.Text.Trim()
        $textBoxNIF.Text = $trimmedText
    }
})



# Adicionar evento de pressionar Enter na TextBox para pesquisar
$textBoxNIF.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        ExibirResultados
        $e.SuppressKeyPress = $true  # Evita o som do "bip" ao pressionar Enter
    }
})

# Adiciona um evento de clique ao painel de resultados
$panelResultados.Add_Click({
    # Se for o primeiro clique, seleciona todo o texto
    if (-not $panelResultados.Tag) {
        $panelResultados.SelectAll()
        # Define a propriedade 'Tag' para marcar que o painel já foi clicado
        $panelResultados.Tag = $true
    }
});
# Adiciona um evento que remove a tag quando o painel é desfoca ao clicar na textBoxNIF
$textBoxNIF.Add_Click({
    # Define a propriedade 'Tag' para marcar que o painel não foi clicado
    $panelResultados.Tag = $false 
});

# Função para redefinir a senha com mensagem de confirmação
$buttonReset.Add_Click({
    if (![string]::IsNullOrEmpty($panelResultados.Text)) {
        foreach ($Usuario in $Usuarios) {
            $resetarSenha = [System.Windows.Forms.MessageBox]::Show("Deseja resetar a senha do(a) $($Usuario.DisplayName)?", "Confirmação", [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($resetarSenha -eq [System.Windows.Forms.DialogResult]::Yes) {
                if ($Usuario.SamAccountName) {
                    # A nova senha será baseada no valor da TextBox
                    $novaSenha = ConvertTo-SecureString -AsPlainText $textBoxResetSenha.Text -Force
                    Set-ADAccountPassword -Identity $Usuario.SamAccountName -NewPassword $novaSenha -Reset
                    Set-ADUser -Identity $Usuario.SamAccountName -ChangePasswordAtLogon $true
                    [System.Windows.Forms.MessageBox]::Show("Senha redefinida para: $($textBoxResetSenha.Text)")
                }
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Nenhuma informação no painel para resetar.", "Aviso")
    }
})

# Função para copiar o e-mail contido no painel de resultados
$buttonCopiar.Add_Click({
    if (![string]::IsNullOrEmpty($global:EmailAtual)) {
        [System.Windows.Forms.Clipboard]::SetText($global:EmailAtual)  # Copiar o e-mail global
    } else {
        [System.Windows.Forms.MessageBox]::Show("Nenhum e-mail encontrado para copiar.", "Aviso")
    }
})




    # Exibir a janela
    $form.ShowDialog()
}

# Função ProcessNIF adaptada para uso na interface GUI
function ProcessNIF {
    param($nif)
    $Usuarios = @()

    if ($nif -like "*@*") {
        $Usuarios = ExecuteScript -property "EmailAddress" -value $nif
    } elseif ($nif -match "\s") {
        $Usuarios = ExecuteScript -property "DisplayName" -value $nif
    } elseif ($nif -match "sn" -or $nif -match "ss" -or $nif -match "tc") {
        $Usuarios = ExecuteScript -property "SamAccountName" -value $nif
    } elseif ($nif -match "^\d+$") {
        $nifWithSN = "SN" + $nif
        $nifWithSS = "SS" + $nif
        $nifWithTC = "TC" + $nif
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithSN))
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithSS))
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithTC))
    } else {
        return @()
    }
    return $Usuarios
}

# Função para executar o script
function ExecuteScript {
    param($property, $value)
    $Usuarios = Get-ADUser -Filter {$property -eq $value} -Properties DisplayName, EmailAddress, SamAccountName, Office, Department, Title, telephoneNumber, Manager, physicalDeliveryOfficeName
    return $Usuarios
}

# Iniciar a GUI
Create-GUI
