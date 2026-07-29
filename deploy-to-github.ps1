# GitHub Pages 部署脚本
# 使用方法：
# 1. 确保已安装 GitHub CLI (gh)
# 2. 运行: .\deploy-to-github.ps1

param(
    [string]$RepoName = "timer-app",
    [string]$GitHubUsername = ""
)

Write-Host "=== 快速计时器 - GitHub Pages 部署脚本 ===" -ForegroundColor Green
Write-Host ""

# 检查 gh 是否安装
try {
    $ghVersion = gh --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✓ GitHub CLI 已安装" -ForegroundColor Green
} catch {
    Write-Host "✗ GitHub CLI (gh) 未安装" -ForegroundColor Red
    Write-Host "正在安装 GitHub CLI..." -ForegroundColor Yellow
    
    # 使用 winget 安装
    try {
        winget install --id GitHub.cli -e
        Write-Host "✓ GitHub CLI 安装完成，请重启终端后重新运行此脚本" -ForegroundColor Green
        exit
    } catch {
        Write-Host "✗ 自动安装失败，请手动安装:" -ForegroundColor Red
        Write-Host "   1. 访问 https://cli.github.com/" -ForegroundColor Cyan
        Write-Host "   2. 下载并安装 GitHub CLI" -ForegroundColor Cyan
        Write-Host "   3. 重新运行此脚本" -ForegroundColor Cyan
        exit
    }
}

# 检查是否已登录
try {
    $authStatus = gh auth status 2>&1
    if ($authStatus -match "not logged") { throw }
    Write-Host "✓ 已登录 GitHub" -ForegroundColor Green
} catch {
    Write-Host "需要登录 GitHub..." -ForegroundColor Yellow
    gh auth login
}

# 获取用户名（如果未提供）
if (-not $GitHubUsername) {
    try {
        $GitHubUsername = gh api user -q '.login'
        Write-Host "✓ 获取到用户名: $GitHubUsername" -ForegroundColor Green
    } catch {
        Write-Host "✗ 无法获取用户名，请手动输入:" -ForegroundColor Red
        $GitHubUsername = Read-Host "GitHub用户名"
    }
}

# 检查仓库是否已存在
try {
    $repoExists = gh repo view "$GitHubUsername/$RepoName" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 仓库 $RepoName 已存在" -ForegroundColor Green
    } else {
        throw
    }
} catch {
    Write-Host "创建新仓库: $RepoName ..." -ForegroundColor Yellow
    gh repo create $RepoName --public --source=. --remote=origin --push
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 仓库创建成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 仓库创建失败" -ForegroundColor Red
        exit
    }
}

# 推送代码
Write-Host "推送代码到 GitHub..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin "https://github.com/$GitHubUsername/$RepoName.git"
git branch -M main

try {
    git push -u origin main
    Write-Host "✓ 代码推送成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 推送失败，尝试强制推送..." -ForegroundColor Yellow
    git push -u origin main --force
}

# 启用 GitHub Pages
Write-Host "启用 GitHub Pages..." -ForegroundColor Yellow
try {
    gh api -X POST "repos/$GitHubUsername/$RepoName/pages" -f source='{"branch":"main","path":"/"}' 2>$null
    Write-Host "✓ GitHub Pages 已启用" -ForegroundColor Green
} catch {
    Write-Host "⚠ 请手动启用 GitHub Pages:" -ForegroundColor Yellow
    Write-Host "   1. 访问 https://github.com/$GitHubUsername/$RepoName/settings/pages" -ForegroundColor Cyan
    Write-Host "   2. Source 选择 'Deploy from a branch'" -ForegroundColor Cyan
    Write-Host "   3. Branch 选择 'main'，文件夹选择 '/' (root)" -ForegroundColor Cyan
    Write-Host "   4. 点击 Save" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== 部署完成！===" -ForegroundColor Green
Write-Host ""
Write-Host "仓库地址: https://github.com/$GitHubUsername/$RepoName" -ForegroundColor Cyan
Write-Host "网站地址: https://$GitHubUsername.github.io/$RepoName" -ForegroundColor Cyan
Write-Host ""
Write-Host "注意：GitHub Pages 部署可能需要 1-5 分钟生效" -ForegroundColor Yellow
Write-Host ""
Read-Host "按 Enter 键退出"
