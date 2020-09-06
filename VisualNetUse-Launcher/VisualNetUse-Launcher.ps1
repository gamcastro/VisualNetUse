
<#PSScriptInfo

.VERSION 0.0.1

.GUID aebea8a3-a4fc-475d-bf39-6d2ecbe7d426

.AUTHOR George Castro

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Launcher do VisualNetUse 

#> 
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$Sigla
)

# Instalar os módulos do VisualNetUse
Install-Module -Name VisualNetUse -Repository SESUMRepositorio -Scope CurrentUser
                 
Import-Module VisualNetUse -ErrorAction Stop

$mapeamento = Get-PSDrive -Name H -ErrorAction SilentlyContinue
if ($mapeamento -and ($mapeamento.used -gt 0)) {
    Write-Host "Mapeamento $Sigla já montado !"
    return
}

$rede = Test-NetConnection -ComputerName 10.11.1.128
if ($rede.PingSucceeded) {       
    $titulo = 'Recebendo credenciais'
    $mensagem = 'Por favor, digite seu titulo (tre-ma\titulo) e senha (igual a do email)'
    $myCredential = $host.UI.PromptForCredential($titulo,$mensagem,'','')
    $retorno = New-SESUMDrive -Sigla $Sigla -Credencial $myCredential
}




