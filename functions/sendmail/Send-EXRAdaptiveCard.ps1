function Send-EXRAdaptiveCard
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[string]
		$MailboxName,
		
		[Parameter(Position = 1, Mandatory = $false)]
		[psobject]
		$AccessToken,
		
		
		[Parameter(Position = 4, Mandatory = $true)]
		[String]
		$Subject,
		
		[Parameter(Position = 5, Mandatory = $false)]
		[String]
		$Body,

		[Parameter(Position = 6, Mandatory = $false)]
		[String]
		$AdaptiveCard,
		
		[Parameter(Position = 7, Mandatory = $false)]
		[psobject]
		$From,
		
		[Parameter(Position = 8, Mandatory = $false)]
		[psobject]
		$Attachment,
		
		[Parameter(Position = 10, Mandatory = $false)]
		[psobject]
		$To,

		[Parameter(Position = 11, Mandatory = $false)]
		[psobject]
		$CC,
		
		[Parameter(Position = 12, Mandatory = $false)]
		[psobject]
		$BCC,
		
		[Parameter(Position = 16, Mandatory = $false)]
		[switch]
		$SaveToSentItems,
		
		[Parameter(Position = 17, Mandatory = $false)]
		[switch]
		$ShowRequest,
		
		[Parameter(Position = 18, Mandatory = $false)]
		[switch]
		$RequestReadRecipient,
		
		[Parameter(Position = 19, Mandatory = $false)]
		[switch]
		$RequestDeliveryRecipient,
		
		[Parameter(Position = 20, Mandatory = $false)]
		[psobject]
		$ReplyTo
	)
	Begin
	{
		
		if($AccessToken -eq $null)
        {
            $AccessToken = Get-ProfiledToken -MailboxName $MailboxName  
            if($AccessToken -eq $null){
                $AccessToken = Get-EXRAccessToken -MailboxName $MailboxName       
            }                 
        }
         if([String]::IsNullOrEmpty($MailboxName)){
            $MailboxName = $AccessToken.mailbox
        } 
		$SaveToSentFolder = "false"
		if ($SaveToSentItems.IsPresent)
		{
			$SaveToSentFolder = "true"
		}
		$Attachments = @()
		if(![String]::IsNullOrEmpty($Attachment)){
			$Attachments += (Resolve-Path $Attachment).Path
		}
		$ToRecipients = @()
		if(![String]::IsNullOrEmpty($To)){
			$ToRecipients += (New-EXREmailAddress -Address $To)
		}
		$CCRecipients = @()
		if(![String]::IsNullOrEmpty($CC)){
		   $CCRecipients += (New-EXREmailAddress -Address $CC)
		}
		$BCCRecipients = @()
		if(![String]::IsNullOrEmpty($BCC)){
		   $BCCRecipients += (New-EXREmailAddress -Address $BCC)
		}
		$SenderEmailAddress = ""
		if(![String]::IsNullOrEmpty($From)){
			$SenderEmailAddress = (New-EXREmailAddress -Address $From)
		}
		if([String]::IsNullOrEmpty($Body)){
			$Body = $Subject
		}
		$EmailBody = "<html>`r`n"
		$EmailBody += "<head>`r`n"
		$EmailBody += "<meta http-equiv=`"Content-Type`" content=`"text/html; charset=utf-8`">`r`n"
		$EmailBody += "<script type=`"application/adaptivecard+json`">`r`n"
		$EmailBody += $AdaptiveCard
		$EmailBody += "</script>`r`n</head>`r`n<body>" + $Body + "`r`n</body>`r`n</html>`r`n"
		$NewMessage = Get-MessageJSONFormat -Subject $Subject -Body $EmailBody.Replace("`"","\`"") -SenderEmailAddress $SenderEmailAddress -Attachments $Attachments -ReferanceAttachments $ReferanceAttachments -ToRecipients $ToRecipients -SentDate $SentDate -ExPropList $ExPropList -CcRecipients $CCRecipients -bccRecipients $BCCRecipients -StandardPropList $StandardPropList -SaveToSentItems $SaveToSentFolder -SendMail -ReplyTo $ReplyTo -RequestReadRecipient $RequestReadRecipient.IsPresent -RequestDeliveryRecipient $RequestDeliveryRecipient.IsPresent
		if ($ShowRequest.IsPresent)
		{
			write-host $NewMessage
		}
		$EndPoint = Get-EndPoint -AccessToken $AccessToken -Segment "users"
		$RequestURL = $EndPoint + "/" + $MailboxName + "/sendmail"
		$HttpClient = Get-HTTPClient -MailboxName $MailboxName
		return Invoke-RestPOST -RequestURL $RequestURL -HttpClient $HttpClient -AccessToken $AccessToken -MailboxName $MailboxName -Content $NewMessage
		
	}
}
