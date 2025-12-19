<#
.SYNOPSIS
    Script de automação para executar e monitorar o hands-on do SDK Compatibility.

.DESCRIPTION
    Este script executa todo o ciclo de automação SDK → Mini-Apps:
    1. Verifica pré-requisitos
    2. Incrementa versão do SDK
    3. Cria tag e faz push
    4. Monitora workflows no GitHub
    5. Verifica criação de PRs
    6. Gera relatório final

.PARAMETER GitHubToken
    Personal Access Token do GitHub com permissões repo e write:packages

.PARAMETER VersionBump
    Tipo de incremento de versão: patch, minor, major (default: patch)

.PARAMETER SkipPush
    Se especificado, não faz push (útil para testes)

.PARAMETER WorkspacePath
    Caminho para o workspace com os repositórios clonados

.EXAMPLE
    .\run-handson.ps1 -GitHubToken "ghp_xxx" -VersionBump "patch"

.EXAMPLE
    .\run-handson.ps1 -GitHubToken $env:GITHUB_TOKEN -WorkspacePath "C:\poc"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubToken,

    [Parameter(Mandatory = $false)]
    [ValidateSet("patch", "minor", "major")]
    [string]$VersionBump = "patch",

    [Parameter(Mandatory = $false)]
    [switch]$SkipPush,

    [Parameter(Mandatory = $false)]
    [string]$WorkspacePath = $PWD
)

# ============================================
# CONFIGURAÇÕES
# ============================================
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$CONFIG = @{
    Owner              = "ricardo2009"
    SdkRepo            = "superapp-sdk-poc"
    Consumers          = @("miniapp-pix-poc", "miniapp-pagamentos-poc")
    Registry           = "npm.pkg.github.com"
    MaxWaitMinutes     = 10
    PollIntervalSeconds = 15
}

$COLORS = @{
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Info    = "Cyan"
    Header  = "Magenta"
}

# ============================================
# FUNÇÕES DE UTILIDADE
# ============================================

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "═" * 60 -ForegroundColor $COLORS.Header
    Write-Host " $Title" -ForegroundColor $COLORS.Header
    Write-Host "═" * 60 -ForegroundColor $COLORS.Header
}

function Write-Step {
    param([string]$Step, [string]$Description)
    Write-Host ""
    Write-Host "[$Step] " -ForegroundColor $COLORS.Info -NoNewline
    Write-Host $Description -ForegroundColor White
    Write-Host "-" * 50 -ForegroundColor DarkGray
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✅ $Message" -ForegroundColor $COLORS.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠️ $Message" -ForegroundColor $COLORS.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ❌ $Message" -ForegroundColor $COLORS.Error
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ️ $Message" -ForegroundColor $COLORS.Info
}

function Invoke-GitHubApi {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [hashtable]$Body = $null
    )
    
    $headers = @{
        "Authorization" = "token $GitHubToken"
        "Accept"        = "application/vnd.github.v3+json"
        "User-Agent"    = "SDK-Compatibility-Script"
    }
    
    $uri = "https://api.github.com$Endpoint"
    
    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = $headers
        ContentType = "application/json"
    }
    
    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }
    
    try {
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Error "Erro na API GitHub: $($_.Exception.Message)"
        return $null
    }
}

# ============================================
# FUNÇÕES DE VERIFICAÇÃO
# ============================================

function Test-Prerequisites {
    Write-Step "1/6" "Verificando pré-requisitos"
    
    $errors = @()
    
    # Verificar Git
    try {
        $gitVersion = git --version
        Write-Success "Git: $gitVersion"
    } catch {
        $errors += "Git não encontrado"
    }
    
    # Verificar Node
    try {
        $nodeVersion = node --version
        Write-Success "Node.js: $nodeVersion"
    } catch {
        $errors += "Node.js não encontrado"
    }
    
    # Verificar npm
    try {
        $npmVersion = npm --version
        Write-Success "npm: $npmVersion"
    } catch {
        $errors += "npm não encontrado"
    }
    
    # Verificar autenticação GitHub
    $user = Invoke-GitHubApi -Endpoint "/user"
    if ($user) {
        Write-Success "GitHub autenticado como: $($user.login)"
    } else {
        $errors += "Token GitHub inválido"
    }
    
    # Verificar diretórios
    $sdkPath = Join-Path $WorkspacePath $CONFIG.SdkRepo
    if (Test-Path $sdkPath) {
        Write-Success "SDK repo encontrado: $sdkPath"
    } else {
        $errors += "SDK repo não encontrado em $sdkPath"
    }
    
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Error "Pré-requisitos não atendidos:"
        $errors | ForEach-Object { Write-Error "  - $_" }
        return $false
    }
    
    return $true
}

# ============================================
# FUNÇÕES DE VERSIONAMENTO
# ============================================

function Update-SdkVersion {
    Write-Step "2/6" "Atualizando versão do SDK ($VersionBump)"
    
    $sdkPath = Join-Path $WorkspacePath $CONFIG.SdkRepo
    Push-Location $sdkPath
    
    try {
        # Garantir que estamos na main
        git checkout main 2>&1 | Out-Null
        git pull origin main 2>&1 | Out-Null
        Write-Info "Branch main atualizada"
        
        # Ler versão atual
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        $oldVersion = $packageJson.version
        Write-Info "Versão atual: $oldVersion"
        
        # Incrementar versão
        npm version $VersionBump --no-git-tag-version 2>&1 | Out-Null
        
        # Ler nova versão
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        $newVersion = $packageJson.version
        Write-Success "Nova versão: $newVersion"
        
        # Adicionar timestamp no código (para garantir alteração)
        $loggerPath = ".\src\logger\index.ts"
        if (Test-Path $loggerPath) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $content = Get-Content $loggerPath -Raw
            $newContent = "// HandsOn Update: $timestamp`n$content"
            Set-Content -Path $loggerPath -Value $newContent
            Write-Info "Código atualizado com timestamp"
        }
        
        # Commit
        git add . 2>&1 | Out-Null
        git commit -m "chore: release v$newVersion" 2>&1 | Out-Null
        Write-Success "Commit criado"
        
        return "v$newVersion"
    } finally {
        Pop-Location
    }
}

# ============================================
# FUNÇÕES DE RELEASE
# ============================================

function Push-SdkRelease {
    param([string]$Tag)
    
    Write-Step "3/6" "Criando tag e fazendo push"
    
    $sdkPath = Join-Path $WorkspacePath $CONFIG.SdkRepo
    Push-Location $sdkPath
    
    try {
        # Criar tag
        git tag -a $Tag -m "Release $Tag" 2>&1 | Out-Null
        Write-Success "Tag $Tag criada"
        
        if (-not $SkipPush) {
            # Push commit
            git push origin main 2>&1 | Out-Null
            Write-Success "Commit enviado para origin/main"
            
            # Push tag
            git push origin $Tag 2>&1 | Out-Null
            Write-Success "Tag $Tag enviada para origin"
            
            Write-Info "Workflow sdk-release.yml deve iniciar em segundos..."
        } else {
            Write-Warning "Push ignorado (modo SkipPush)"
        }
        
        return $true
    } catch {
        Write-Error "Erro no push: $($_.Exception.Message)"
        return $false
    } finally {
        Pop-Location
    }
}

# ============================================
# FUNÇÕES DE MONITORAMENTO
# ============================================

function Wait-WorkflowCompletion {
    param(
        [string]$Repo,
        [string]$WorkflowName = $null,
        [string]$TriggerType = "push"
    )
    
    $startTime = Get-Date
    $maxWait = New-TimeSpan -Minutes $CONFIG.MaxWaitMinutes
    $completed = $false
    $status = "unknown"
    
    Write-Info "Aguardando workflow em $Repo..."
    
    while (-not $completed) {
        $elapsed = (Get-Date) - $startTime
        if ($elapsed -gt $maxWait) {
            Write-Warning "Timeout aguardando workflow"
            return @{ Status = "timeout"; Elapsed = $elapsed }
        }
        
        # Buscar runs recentes
        $endpoint = "/repos/$($CONFIG.Owner)/$Repo/actions/runs?per_page=5"
        $runs = Invoke-GitHubApi -Endpoint $endpoint
        
        if ($runs -and $runs.workflow_runs.Count -gt 0) {
            $latestRun = $runs.workflow_runs[0]
            
            Write-Host "`r  ⏳ Status: $($latestRun.status) | Conclusão: $($latestRun.conclusion) | Tempo: $($elapsed.ToString('mm\:ss'))" -NoNewline
            
            if ($latestRun.status -eq "completed") {
                $completed = $true
                $status = $latestRun.conclusion
                Write-Host "" # Nova linha
                
                if ($status -eq "success") {
                    Write-Success "Workflow concluído com sucesso!"
                } else {
                    Write-Warning "Workflow concluído com status: $status"
                }
                
                return @{
                    Status    = $status
                    Elapsed   = $elapsed
                    RunId     = $latestRun.id
                    Url       = $latestRun.html_url
                }
            }
        }
        
        Start-Sleep -Seconds $CONFIG.PollIntervalSeconds
    }
}

function Get-OpenPullRequests {
    param([string]$Repo)
    
    $endpoint = "/repos/$($CONFIG.Owner)/$Repo/pulls?state=open"
    $prs = Invoke-GitHubApi -Endpoint $endpoint
    
    return $prs | Where-Object { $_.head.ref -like "sdk-update/*" }
}

# ============================================
# FUNÇÕES DE RELATÓRIO
# ============================================

function Show-FinalReport {
    param(
        [string]$Tag,
        [hashtable]$SdkWorkflow,
        [array]$ConsumerResults
    )
    
    Write-Header "RELATÓRIO FINAL"
    
    $totalTime = [TimeSpan]::Zero
    
    # SDK Release
    Write-Host ""
    Write-Host "📦 SDK Release" -ForegroundColor $COLORS.Header
    Write-Host "   Tag: $Tag"
    Write-Host "   Package: @$($CONFIG.Owner)/superapp-sdk-poc@$($Tag.TrimStart('v'))"
    Write-Host "   Status: $($SdkWorkflow.Status)"
    Write-Host "   Tempo: $($SdkWorkflow.Elapsed.ToString('mm\:ss'))"
    Write-Host "   URL: $($SdkWorkflow.Url)"
    $totalTime += $SdkWorkflow.Elapsed
    
    # Consumers
    Write-Host ""
    Write-Host "📱 Mini-Apps" -ForegroundColor $COLORS.Header
    
    foreach ($result in $ConsumerResults) {
        Write-Host ""
        Write-Host "   $($result.Repo):" -ForegroundColor $COLORS.Info
        Write-Host "     Workflow: $($result.WorkflowStatus)"
        Write-Host "     Tempo: $($result.Elapsed.ToString('mm\:ss'))"
        
        if ($result.PR) {
            Write-Host "     PR: #$($result.PR.number) - $($result.PR.title)"
            Write-Host "     URL: $($result.PR.html_url)"
        } else {
            Write-Host "     PR: Não encontrado" -ForegroundColor $COLORS.Warning
        }
        
        if ($result.Elapsed) {
            $totalTime += $result.Elapsed
        }
    }
    
    # Resumo
    Write-Host ""
    Write-Host "═" * 60 -ForegroundColor $COLORS.Header
    Write-Host ""
    Write-Host "⏱️  Tempo total: $($totalTime.ToString('mm\:ss'))" -ForegroundColor $COLORS.Info
    
    $successCount = ($ConsumerResults | Where-Object { $_.WorkflowStatus -eq "success" }).Count
    if ($SdkWorkflow.Status -eq "success" -and $successCount -eq $ConsumerResults.Count) {
        Write-Host "🎉 Automação concluída com SUCESSO!" -ForegroundColor $COLORS.Success
    } else {
        Write-Host "⚠️ Automação concluída com alguns problemas" -ForegroundColor $COLORS.Warning
    }
    
    Write-Host ""
}

# ============================================
# MAIN
# ============================================

function Main {
    $startTime = Get-Date
    
    Write-Header "SDK COMPATIBILITY AUTOMATION - HANDS-ON"
    Write-Host "Iniciado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
    Write-Host "Workspace: $WorkspacePath" -ForegroundColor DarkGray
    Write-Host "Version Bump: $VersionBump" -ForegroundColor DarkGray
    
    # Passo 1: Verificar pré-requisitos
    if (-not (Test-Prerequisites)) {
        Write-Error "Pré-requisitos não atendidos. Abortando."
        exit 1
    }
    
    # Passo 2: Atualizar versão
    $tag = Update-SdkVersion
    if (-not $tag) {
        Write-Error "Falha ao atualizar versão. Abortando."
        exit 1
    }
    
    # Passo 3: Push
    $pushResult = Push-SdkRelease -Tag $tag
    if (-not $pushResult -and -not $SkipPush) {
        Write-Error "Falha no push. Abortando."
        exit 1
    }
    
    if ($SkipPush) {
        Write-Warning "Modo SkipPush ativo. Encerrando sem monitoramento."
        return
    }
    
    # Passo 4: Monitorar SDK workflow
    Write-Step "4/6" "Monitorando workflow do SDK"
    $sdkWorkflow = Wait-WorkflowCompletion -Repo $CONFIG.SdkRepo
    
    if ($sdkWorkflow.Status -ne "success") {
        Write-Warning "Workflow do SDK não teve sucesso. Continuando mesmo assim..."
    }
    
    # Aguardar um pouco para o dispatch propagar
    Write-Info "Aguardando propagação do dispatch..."
    Start-Sleep -Seconds 10
    
    # Passo 5: Monitorar consumers
    Write-Step "5/6" "Monitorando workflows dos mini-apps"
    
    $consumerResults = @()
    foreach ($consumer in $CONFIG.Consumers) {
        Write-Host ""
        Write-Host "  📱 $consumer" -ForegroundColor $COLORS.Info
        
        $result = @{
            Repo           = $consumer
            WorkflowStatus = "unknown"
            Elapsed        = [TimeSpan]::Zero
            PR             = $null
        }
        
        $workflow = Wait-WorkflowCompletion -Repo $consumer
        $result.WorkflowStatus = $workflow.Status
        $result.Elapsed = $workflow.Elapsed
        
        # Buscar PR criado
        $prs = Get-OpenPullRequests -Repo $consumer
        if ($prs -and $prs.Count -gt 0) {
            $result.PR = $prs | Where-Object { $_.head.ref -like "*$tag*" } | Select-Object -First 1
            if (-not $result.PR) {
                $result.PR = $prs | Select-Object -First 1
            }
        }
        
        $consumerResults += $result
    }
    
    # Passo 6: Relatório final
    Show-FinalReport -Tag $tag -SdkWorkflow $sdkWorkflow -ConsumerResults $consumerResults
    
    # Abrir URLs no navegador
    Write-Step "EXTRA" "Abrindo resultados no navegador"
    
    if ($sdkWorkflow.Url) {
        Start-Process $sdkWorkflow.Url
    }
    
    foreach ($result in $consumerResults) {
        if ($result.PR) {
            Start-Process $result.PR.html_url
        }
    }
}

# Executar
Main
