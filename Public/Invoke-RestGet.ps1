function Invoke-RestGet
{
        param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$RequestURL,
        [Parameter(Position=1, Mandatory=$true)] [String]$MailboxName,
        [Parameter(Position=2, Mandatory=$true)] [System.Net.Http.HttpClient]$HttpClient,
        [Parameter(Position=3, Mandatory=$true)] [psobject]$AccessToken,
        [Parameter(Position=4, Mandatory=$false)] [switch]$NoJSON
    )  
 	Begin
		 {
             #Check for expired Token
             $minTime = new-object DateTime(1970, 1, 1, 0, 0, 0, 0,[System.DateTimeKind]::Utc);
             $expiry =  $minTime.AddSeconds($AccessToken.expires_on)
             if($expiry -le [DateTime]::Now.ToUniversalTime()){
                if([bool]($AccessToken.PSobject.Properties.name -match "refresh_token")){
                    write-host "Refresh Token"
                    $AccessToken = Invoke-RefreshAccessToken -MailboxName $MailboxName -AccessToken $AccessToken          
                    Set-Variable -Name "AccessToken" -Value $AccessToken -Scope Script -Visibility Public
                }
                else{
                    throw "App Token has expired"
                }

             }
             $HttpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", (Get-TokenFromSecureString -SecureToken $AccessToken.access_token));
             $HttpClient.DefaultRequestHeaders.Add("Prefer", ("outlook.timezone=`"" + [TimeZoneInfo]::Local.Id + "`"")) 
             $ClientResult = $HttpClient.GetAsync($RequestURL)
             Write-Output $ClientResult.Result
             if($ClientResult.Result.StatusCode -ne [System.Net.HttpStatusCode]::OK){
                 if($ClientResult.Result.StatusCode -ne [System.Net.HttpStatusCode]::Created){
                     write-Host ($ClientResult.Result)
                 }
                 if($ClientResult.Result.Content -ne $null){
                    Write-Host ($ClientResult.Result.Content.ReadAsStringAsync().Result); 
                 }                  
             }             
             if (!$ClientResult.Result.IsSuccessStatusCode)
             {
                    Write-Host ("Error making REST Get " + $ClientResult.Result.StatusCode + " : " + $ClientResult.Result.ReasonPhrase)
                    Write-Host ("RequestURL : " + $RequestURL)                
             }
            else
             {
               if($NoJSON){
                    return  $ClientResult.Result.Content  
               }
               else{
                    $JsonObject = ExpandPayload($ClientResult.Result.Content.ReadAsStringAsync().Result) 
                    #$JsonObject = ConvertFrom-Json -InputObject  $ClientResult.Result.Content.ReadAsStringAsync().Result
                   if([String]::IsNullOrEmpty($ClientResult)){
                        write-host "No Value returned"
                   }
                   else{
                        return $JsonObject
                   }

               }  

             }
  
         }    
}