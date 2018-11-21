function Get-EXRGroupThreads {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [string]
        $MailboxName,
		
        [Parameter(Position = 1, Mandatory = $false)]
        [psobject]
        $AccessToken,
		
        [Parameter(Position = 2, Mandatory = $false)]
        [psobject]
        $Group,
		
        [Parameter(Position = 3, Mandatory = $false)]
        [DateTime]
        $lastDeliveredDateTime,
		
        [Parameter(Position = 4, Mandatory = $false)]
        [Int]
        $Top = 1000,

        [Parameter(Position = 5, Mandatory = $false)]
        [string]
        $ThreadURI,

        [Parameter(Position = 6, Mandatory = $false)]
        [switch]
        $TopOnly
    )
    Process {
        if ($AccessToken -eq $null) {
            $AccessToken = Get-ProfiledToken -MailboxName $MailboxName  
            if ($AccessToken -eq $null) {
                $AccessToken = Get-EXRAccessToken -MailboxName $MailboxName       
            }                 
        }
        if ([String]::IsNullOrEmpty($MailboxName)) {
            $MailboxName = $AccessToken.mailbox
        }  
        $HttpClient = Get-HTTPClient -MailboxName $MailboxName
        $EndPoint = Get-EndPoint -AccessToken $AccessToken -Segment "groups"        
        $RequestURL = $EndPoint + "('" + $Group.Id + "')/Threads?`$Top=$Top"
        if(![String]::IsNullOrEmpty($ThreadURI)){
            $RequestURL = $ThreadURI
        }
        do {
            $JSONOutput = Invoke-RestGet -RequestURL $RequestURL -HttpClient $HttpClient -AccessToken $AccessToken -MailboxName $MailboxName
            foreach ($Message in $JSONOutput.Value) {
                $ItemURI = $EndPoint + "('" + $Group.Id + "')/Threads" + "('" + $Message.Id + "')"
                add-Member -InputObject $Message -NotePropertyName ItemURI -NotePropertyValue $ItemURI
                if ($lastDeliveredDateTime) {
                    if (([DateTime]$Message.lastDeliveredDateTime) -gt $lastDeliveredDateTime) {
                        Write-Output $Message
                    }
                }
                else {
                    Write-Output $Message
                }
            }
            $RequestURL = $JSONOutput.'@odata.nextLink'
        }
        while (![String]::IsNullOrEmpty($RequestURL) -band (!$TopOnly.IsPresent))	
    }
}
