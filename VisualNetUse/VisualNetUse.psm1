function Get-SESUMAdUser {
    <#
.SYNOPSIS
Obtem um ou mais usuários do Active Directory do TRE-MA
.DESCRIPTION
O comando Get-SESUMAdUser obtem um objeto de usuário ou
executa uma busca por multiplos objetos de usuários.
.PARAMETER Titulo
Especifica o título de eleitor usuário em específico que
 se deseja obter inforamações.

O título deve conter 12 caracteres
.PARAMETER Nome
Especifica todo ou parte do nome do usuário que se deseja
obter informações
.PARAMETER Credencial
Especifica as credenciais da conta do usuário a serem usadas
para executar esta tarefa
.EXAMPLE
Get-SESUMAduser -Titulo 000000010191
Obtem o objeto de usuário do Active Directory que possui 
o título de eleitor 000000010191
.EXAMPLE
Get-SESUMAduser -Nome Maria
Obtem o objeto de usuário do Active Directory que possui
parte do nome "Maria"
.INPUTS
System.String
.OUTPUTS
Microsoft.ActiveDirectory.Management.ADUser
#>
    [cmdletBinding()]
    param([Parameter(Mandatory = $True,
            ValueFromPipeline = $true,
            ParameterSetName = 'titulo')]
        [ValidateLength(12, 12)]
        [ValidatePattern('^\d{12}$')]
        [string]$Titulo,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'nome')]
        [string]$Nome,

        [System.Management.Automation.PSCredential]$Credencial 
    )
    BEGIN {
        Write-Verbose "[BEGIN  ] : "
        if ($PSCmdlet.ParameterSetName -eq 'titulo') {
            $ids = $Titulo
        }
        else {
            $ids = $Nome
        }
        $params = @{'Server' = 'madc01.tre-ma.gov.br'
            'Credential'     = $Credencial
            'Properties'     = '*'
        }
    }
    PROCESS {
        foreach ($id in $ids) {
            if ($PSCmdlet.ParameterSetName -eq 'titulo') {
                $params += @{'Identity' = $id }
            }
            else {
                $params += @{'Filter' = "DisplayName -like '*$id*'" }
            }
            
            Write-Verbose "Consultando informações no Active Directory"
           
            Get-ADUser @params
        }
    }
    END {}
}
function Get-SESUMLotacaoInfo {
    <#
    .SYNOPSIS
    Obtem informações de lotação do usuário fornecido

    .DESCRIPTION
    Obtem informações de lotação do usuário fornecido
    Gera informações da Unidade de Lotação, o nome completo
    do usuário , o título de eleitor e a sigla da unidade de 
    lotação

    .PARAMETER InputObject
    Especifica o objeto de usuário do Active Directory

    .INPUTS
    Microsoft.ActiveDirectory.Management.ADUser

    .EXAMPLE
    Get-AdUser -Filter 'DisplayName -like "George*" | Get-SESUMLotacaoInfo
    Esse exemplo busca um usuário do Active Directory que é repassado para 
    obter as informações de lotação.
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [object[]]$ADUser
    )
    BEGIN { }
    PROCESS {
        foreach ($user in $ADUser) {
            $unidade = Get-UnidadeInfo -ou $user.DistinguishedName
            $props = @{'Nome' = $user.DisplayName
                'Titulo'      = $user.SamAccountName
                'Lotação'     = $unidade.UNIDADE
                'Sigla'       = $unidade.SIGLA
            }

            $obj = New-Object -TypeName psobject -Property $props
           # $obj.psobject.TypeNames.Insert(0, "SESUM.Usuario")
            Write-Output $obj
        }
    }
    END {}
}
function Get-UnidadeInfo {
    <#
.SYNOPSIS
Obtem informações acerca da unidade  do objeto do usuário requerente

.DESCRIPTION
Obtem informações acerca da unidade  do objeto do usuário requerente
As informações resultantes são o nome da secretaria e a sigla

.PARAMETER ou
Especifica a OU do objeto de usuário do active directory

.INPUTS
System.String

.EXAMPLE
Get-AdUser -Filter 'DisplayName -like "George*" | Select-Object -Property DistinguishedName
| Add-SiglaUnidade
#>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'OU')]
        [string]$ou,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'SIGLA')]
        [string]$Sigla
    )
    # CN=Nome do Usuári Completo,OU=SERVIDORES,OU=NOME_DA_SECRETARIA,OU=SECRETARIAS,OU=TRIBUNAL,DC=tre-ma,DC=gov,DC=br
    # Obter a primeira virgula depois do nome completo do usuário
    # Soma mais 4 caracteres que é para chegar no que tem em frente a OU=
    $unidades = Import-Csv -Path "$PSScriptRoot\unidades.csv" -Delimiter ';' -Encoding Default

    if ($PSCmdlet.ParameterSetName -eq 'OU') {
        foreach ($unidade in $unidades) {
            if ($ou -match $unidade.UNIDADE) {
                Write-Verbose "Houve um match"
                return $unidade
            }
        }
        Write-Verbose "Não houve match"
        $props = @{'UNIDADE' = 'OUTRO'
            'SIGLA'          = 'OUTRO'
        }
    }
    else {
        foreach ($unidade in $unidades) {
            if ($Sigla -match $unidade.SIGLA) {
                Write-Verbose "Houve um match"
                return $unidade
            }
        }
        Write-Verbose "Não houve match"
        $props = @{'UNIDADE' = 'OUTRO'
            'SIGLA'          = 'OUTRO'
        }

    }
    
    $obj = New-Object -TypeName psobject -Property $props
    Write-Output $obj
}

function New-SESUMDrive {
    <#
    .SYNOPSIS
    Criar uma pasta mapeada de rede corporativa do TRE-MA.

    .DESCRIPTION
    Criar uma pasta mapeada de rede corporativa do TRE-MA.
    A pasta de rede mapeada é obtida de acordo com as
    informações do  usuário que está requerendo o mapaemento

    .PARAMETER Usuario
    Especifica o usuário do qual a pasta de rede será
    montada de acordo.

    .PARAMETER Drive
    Especifica a letra do Drive que será mapeada a
    pasta de rede .

    .PARAMETER Fileserver
    Especifica o servidor de arquivos o qual será
    a origem do mapeamento de rede.

    .PARAMETER Credencial
    Especifica as credenciais da conta do usuário a serem usadas
para executar esta tarefa.

    .INPUTS
    TRE-MA.Usuario.

    .EXAMPLE
    Get-SESUMAduser -Titulo 029342881104 | Get-SESUMLotacaoInfo | New-SESUMDrive
    .EXAMPLE
    $mycred = Get-Credential
    New-SESUMDrive -Credencial $mycred -Sigla STI
    
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   ParameterSetName = "AD",
                   ValueFromPipeline = $true)]
        [object]$Usuario,

        [Parameter(Mandatory = $True,           
            ParameterSetName = "Normal")]
        [string]$Sigla,

        [string]$Drive = 'H',

        [string]$Fileserver = '\\10.11.1.128\' ,

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [PSCredential]$Credencial 

    )
    BEGIN {
        Write-Verbose "[BEGIN   ] $usuario"
        $props = @{'Drive' = $drive
                    "Usuário" = $Credencial.UserName.Remove(0,7)
                }
    }
    PROCESS {
        $params = @{'Name' = $Drive
            'Persist'      = $true
            'PSProvider'   = 'FileSystem'
            'Scope'        = 'Global'
            'Credential'   = $Credencial
        }
        if ($PSCmdlet.ParameterSetName -eq 'AD') {
            $userinfo = $Usuario
            $params += @{"Root" = "$Fileserver$($userinfo.Sigla)$" }
            $props += @{'Unidade' = $userinfo.Lotação }          
            
        }
        else {
            $unidade = Get-UnidadeInfo -Sigla $Sigla
            $params += @{"Root" = "$Fileserver$($unidade.SIGLA)$" }
            $props += @{'Unidade' = $unidade.UNIDADE }    
        }     
        
       
            
        $ret = New-PSDrive @params

        if ($ret.Used -gt 0) {
            $status = 'OK'
        }
        else {
            $status = 'Falha'
        }
        $props += @{'Status' = $status}   
                    
        $obj = New-Object -TypeName psobject -Property $props
        Write-Output $obj

    }
    END {}
}

   
    
    
