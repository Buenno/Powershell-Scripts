Function Copy-DeviceCollectionMembership {
  <#
    .SYNOPSIS
      Copies collection membership of a SCCM device.
    .DESCRIPTION
      Copies collection membership of a SCCM device. Useful for replicating membership to new/replacement devices, or mimicing configuration.
    .PARAMETER Name
      Source computer name to copy collection membership from.
    .PARAMETER Target
      Target computer name to copy collection membership to.
    .PARAMETER Purge
      Removes source computer from all collections once copied to target computer.
    .EXAMPLE
      Copy-CollectionMembership -Name "Device001" -Target "New002" -Purge
    .EXAMPLE
      Get-CMDevice -Name "Device001" | Copy-CollectionMembership -Target "New002"
  #>

    [CmdletBinding()]
    Param(
      [Parameter(
        Mandatory = False,
        ValueFromPipeline = True,
        ValueFromPipelineByPropertyName = True,
        Position = 0
        )]
      [string] $Name
    )

  BEGIN {}

  PROCESS {}
      
  END {}
}
