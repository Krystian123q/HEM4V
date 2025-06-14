Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-InputBox {
    param(
        [string]$Message,
        [string]$Title
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(400,165)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false
    $form.Topmost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,20)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Size = New-Object System.Drawing.Size(360,20)
    $textBox.Location = New-Object System.Drawing.Point(10,50)
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(220,85)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Anuluj"
    $cancelButton.Location = New-Object System.Drawing.Point(300,85)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $form.ShowDialog() | Out-Null
    if ($form.DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    } else {
        return $null
    }
}

# ------------------------------------------
# GUI Initialization
# ------------------------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Hem4V – Starter projektów GitHub"
$form.Size = New-Object System.Drawing.Size(650,470)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Logo Label
$logoLabel = New-Object System.Windows.Forms.Label
$logoLabel.Text = @"
 _   _                 _   _   _  ___ 
| | | | ___  _ __ ___ | | | | / |/ _ \
| |_| |/ _ \| '_ ` _ \| |_| || | | | |
|  _  | (_) | | | | | |  _  || | |_| |
|_| |_|\___/|_| |_| |_|_| |_||_|\___/
"@
$logoLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$logoLabel.Location = New-Object System.Drawing.Point(10,5)
$logoLabel.Size = New-Object System.Drawing.Size(630,60)
$form.Controls.Add($logoLabel)

# Log TextBox (multiline, scrollable)
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = 'Vertical'
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas",9)
$logBox.Location = New-Object System.Drawing.Point(10,70)
$logBox.Size = New-Object System.Drawing.Size(610,320)
$form.Controls.Add($logBox)

# Input Label
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "Podaj link do repozytorium GitHub:"
$inputLabel.Location = New-Object System.Drawing.Point(10,400)
$inputLabel.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($inputLabel)

# Input TextBox
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(180,398)
$inputBox.Size = New-Object System.Drawing.Size(340,22)
$form.Controls.Add($inputBox)

# Start Button
$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "Start"
$startBtn.Location = New-Object System.Drawing.Point(535,395)
$startBtn.Size = New-Object System.Drawing.Size(85,28)
$form.Controls.Add($startBtn)

# Helper: write to log
function Add-Log {
    param([string]$text)
    $logBox.AppendText("$text`r`n")
    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Helper: Show error box
function Show-Error {
    param([string]$msg)
    [System.Windows.Forms.MessageBox]::Show($msg, "Błąd", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

# Helper: Download file
function Download-File {
    param($url, $dest)
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $dest)
        return $true
    } catch {
        return $false
    }
}

# Helper: Run process
function Run-Proc {
    param(
        [string]$exe,
        [string]$args,
        [string]$cwd = ''
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $args
    if ($cwd -ne '') { $psi.WorkingDirectory = $cwd }
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{ExitCode=$proc.ExitCode; StdOut=$stdout; StdErr=$stderr}
}

# Main logic
$startBtn.Add_Click({
    $startBtn.Enabled = $false
    $repoUrl = $inputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        Show-Error "Podaj link do repozytorium GitHub!"
        $startBtn.Enabled = $true
        return
    }
    $logBox.Clear()
    Add-Log "🔎 Sprawdzanie repozytorium: $repoUrl"
    $mainFolder = "$env:USERPROFILE\Hem4V"
    Add-Log "📁 Używany folder: $mainFolder"

    if (-not (Test-Path $mainFolder)) {
        try {
            New-Item -ItemType Directory -Path $mainFolder -Force | Out-Null
            Add-Log "✔️ Utworzono folder: $mainFolder"
        } catch {
            Show-Error "Nie można utworzyć folderu $mainFolder. Sprawdź uprawnienia!"
            $startBtn.Enabled = $true
            return
        }
    } else {
        Add-Log "✔️ Folder już istnieje: $mainFolder"
    }

    # GIT CHECK
    $gitPath = ''
    try {
        $gitPath = (Get-Command git -ErrorAction Stop).Source
    } catch {
        Add-Log "⚠️ Nie znaleziono GIT-a. Rozpoczynam pobieranie i instalację..."
        $gitInstaller = "$env:TEMP\Git-Setup.exe"
        $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.45.2-64-bit.exe"
        if (-not (Download-File $gitUrl $gitInstaller)) {
            Show-Error "Nie udało się pobrać instalatora Git."
            $startBtn.Enabled = $true
            return
        }
        Add-Log "⬇️ Pobieranie Git zakończone. Instalacja w toku..."
        $proc = Run-Proc -exe $gitInstaller -args "/VERYSILENT /NORESTART"
        if ($proc.ExitCode -ne 0) {
            Show-Error "Instalacja Git nie powiodła się! Uruchom skrypt jako administrator."
            $startBtn.Enabled = $true
            return
        }
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
        # Nowy PATH
        $env:Path += ";C:\Program Files\Git\cmd"
        try {
            $gitPath = (Get-Command git -ErrorAction Stop).Source
        } catch {
            Show-Error "Pomimo instalacji Git nie został odnaleziony. Uruchom ponownie komputer."
            $startBtn.Enabled = $true
            return
        }
        Add-Log "✔️ Git zainstalowany!"
    }
    Add-Log "Używany Git: $gitPath"

    # Klonowanie repo
    # Wyciągnięcie NAZWY projektu
    $repoName = $repoUrl.TrimEnd('/').Split('/')[-1] -replace '\.git$',''
    $projectPath = Join-Path $mainFolder $repoName

    if (Test-Path $projectPath) {
        Add-Log "🧹 Usuwanie starego folderu projektu: $projectPath"
        try {
            Remove-Item -Recurse -Force $projectPath
        } catch {
            Show-Error "Nie można usunąć starego folderu projektu! Sprawdź uprawnienia."
            $startBtn.Enabled = $true
            return
        }
    }
    Add-Log "🔗 Klonowanie repozytorium..."
    $clone = Run-Proc -exe $gitPath -args "clone --depth 1 `"$repoUrl`"" -cwd $mainFolder
    if ($clone.ExitCode -ne 0) {
        Add-Log "❌ Błąd podczas klonowania repozytorium:"
        Add-Log $clone.StdErr
        Show-Error "Nie udało się sklonować repozytorium. Sprawdź link lub dostęp do internetu."
        $startBtn.Enabled = $true
        return
    }
    Add-Log $clone.StdOut
    Add-Log "✔️ Repozytorium pobrane do: $projectPath"

    # DETEKCJA TECHNLOGII
    Add-Log "🔍 Wykrywanie typu projektu..."
    $type = ''
    $mainScript = $null

    if (Test-Path (Join-Path $projectPath 'requirements.txt')) {
        $type = 'python'
        Add-Log "🟢 Wykryto projekt Python (requirements.txt)"
        # Sprawdź python
        $pythonCmd = ''
        try {
            $pythonCmd = (Get-Command python -ErrorAction Stop).Source
        } catch {
            Add-Log "❌ Nie znaleziono Pythona! Zainstaluj Python 3 aby uruchomić projekt."
            Show-Error "Nie znaleziono Pythona w systemie. Zainstaluj Python 3 i spróbuj ponownie."
            $startBtn.Enabled = $true
            return
        }
        # Sprawdź pip
        $pipOK = $false
        try {
            $pipVer = Run-Proc -exe "pip" -args "--version"
            if ($pipVer.ExitCode -eq 0) { $pipOK = $true }
        } catch {}
        if (-not $pipOK) {
            Add-Log "❌ Nie znaleziono pip! Zainstaluj pip aby uruchomić projekt."
            Show-Error "Nie znaleziono pip w systemie. Zainstaluj pip i spróbuj ponownie."
            $startBtn.Enabled = $true
            return
        }
        # Instaluj wymagania
        Add-Log "📦 Instalacja zależności (pip install -r requirements.txt)..."
        $pipRes = Run-Proc -exe "pip" -args "install -r requirements.txt" -cwd $projectPath
        Add-Log $pipRes.StdOut
        if ($pipRes.ExitCode -ne 0) {
            Add-Log "❌ Błąd podczas instalacji zależności:"
            Add-Log $pipRes.StdErr
            Show-Error "Nie udało się zainstalować zależności pip."
            $startBtn.Enabled = $true
            return
        }
        # Poszukaj main.py
        if (Test-Path (Join-Path $projectPath 'main.py')) {
            $mainScript = 'main.py'
        } else {
            # Szukaj innego .py
            $pyFiles = Get-ChildItem -Path $projectPath -Filter *.py
            if ($pyFiles.Count -ge 1) {
                $mainScript = $pyFiles[0].Name
                Add-Log "ℹ️ Nie znaleziono main.py. Uruchamiam: $($mainScript)"
            } else {
                Add-Log "❌ Nie znaleziono pliku .py do uruchomienia."
                Show-Error "Nie znaleziono pliku .py do uruchomienia."
                $startBtn.Enabled = $true
                return
            }
        }
        Add-Log "🚀 Uruchamianie skryptu: $mainScript"
        Start-Job -ScriptBlock {
            param($py, $script, $cwd)
            Start-Process -FilePath $py -ArgumentList $script -WorkingDirectory $cwd
        } -ArgumentList $pythonCmd, $mainScript, $projectPath | Out-Null
        Add-Log "✅ Projekt Python został uruchomiony w osobnym oknie."
    }
    elseif (Test-Path (Join-Path $projectPath 'package.json')) {
        $type = 'node'
        Add-Log "🟢 Wykryto projekt Node.js (package.json)"
        # Sprawdz npm
        $npmOK = $false
        try {
            $npmVer = Run-Proc -exe "npm" -args "--version"
            if ($npmVer.ExitCode -eq 0) { $npmOK = $true }
        } catch {}
        if (-not $npmOK) {
            Add-Log "❌ Nie znaleziono Node.js (npm)! Zainstaluj Node.js aby uruchomić projekt."
            Show-Error "Nie znaleziono Node.js (npm) w systemie. Zainstaluj Node.js i spróbuj ponownie."
            $startBtn.Enabled = $true
            return
        }
        # Instaluj zależności
        Add-Log "📦 Instalacja zależności (npm install)..."
        $npmRes = Run-Proc -exe "npm" -args "install" -cwd $projectPath
        Add-Log $npmRes.StdOut
        if ($npmRes.ExitCode -ne 0) {
            Add-Log "❌ Błąd podczas instalacji zależności:"
            Add-Log $npmRes.StdErr
            Show-Error "Nie udało się zainstalować zależności npm."
            $startBtn.Enabled = $true
            return
        }
        # Start
        Add-Log "🚀 Uruchamianie projektu: npm start"
        Start-Job -ScriptBlock {
            param($cwd)
            Start-Process -FilePath "npm" -ArgumentList "start" -WorkingDirectory $cwd
        } -ArgumentList $projectPath | Out-Null
        Add-Log "✅ Projekt Node.js został uruchomiony w osobnym oknie."
    }
    else {
        Add-Log "🔴 Nie rozpoznano typu projektu!"
        Add-Log "W folderze nie znaleziono 'requirements.txt' ani 'package.json'."
        Show-Error "Nie rozpoznano typu projektu – obsługiwane są tylko Python (requirements.txt) i Node.js (package.json)."
    }
    $startBtn.Enabled = $true
})

$form.Add_Shown({ $inputBox.Focus() })
[void]$form.ShowDialog()