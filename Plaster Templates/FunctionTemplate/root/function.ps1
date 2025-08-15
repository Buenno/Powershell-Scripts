<%
"Function $PLASTER_PARAM_FunctionName {"
%>
<%
@"
  <#
    .SYNOPSIS
      Short description
    .DESCRIPTION
      Long description
    .PARAMETER XXX
      Describe the parameter
    .EXAMPLE
      Example of how to use this cmdlet
    .NOTES
      Insert any notes
    .LINK
      Insert links
  #>

    [CmdletBinding()]
    Param(
      [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
            )]
      [string] $ParameterName
    )

  BEGIN {}

  PROCESS {}
      
  END {}
}
"@
%>