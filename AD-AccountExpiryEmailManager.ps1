$EmailFrom = "Reporting Service <reporting.service@yourcompany.com>"
$EmailTo = "it.reports@yourcompany.com"
$EmailSubject = "Domain Account Expiration Report"
$SMTPServer = "smtp.yourcompany.com"

$OU = "OU=USERS,DC=yourdomain,DC=com"
$daysToExpiry = 14

# Report for users with manager
Get-ADUser -Filter 'enabled -eq $true' -SearchBase "$OU" -Properties directReports,EmailAddress | ForEach {
    If ($_.directReports) {
        $emailBody = "<head><style>table, th, td {border: 1px solid #999999;border-collapse: collapse;} th, td {padding: 9px;}</style></head>"
        $emailBody += "Dear " + $_.Name + ",<br><br>"
        $emailBody += "The below accounts in your team have expired or are about to expire in " + $daysToExpiry + " days:<br><br>"
        $emailBody += "<table><tr><th>Account Name</th><th>Expiration Date</th></tr>"
        $managerEmailAddress = $_.EmailAddress
        $_.directReports | ForEach {
            $userDetails = Get-ADUser $_ -Properties AccountExpirationDate,Enabled
            If ( $userDetails.AccountExpirationDate -And $userDetails.Enabled) {
                If ( $userDetails.AccountExpirationDate -lt (Get-Date).AddDays($daysToExpiry) ) {
                    $sendEmail = $true
                    $emailBody += "<tr><td>" + $userDetails.SamAccountName + "</td><td>" + $userDetails.AccountExpirationDate.ToString('g', [CultureInfo]'en-GB') + "</td></tr>"
                }
            }
        }
    }
    If ($sendEmail) {
         $emailBody += "</table><br>This is an automated report.<br>If you wish to extend or disable the above accounts, please contact IT by replying to this email or calling 0123 456 7890.<br><br>"
         $emailBody += "<small>Report generated on " + (Get-Date -Format "dd/MM/yyyy HH:mm") + " by IT</small><br>"
         Send-MailMessage -From $EmailFrom -To $managerEmailAddress -Subject $EmailSubject -Body $body -BodyAsHtml -SmtpServer $SMTPServer
#         Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $emailBody -BodyAsHtml -SmtpServer $SMTPServer
    }
    $sendEmail = $false
}

# Report for users with no manager info
$emailBodyNM = "<head><style>table, th, td {border: 1px solid #999999;border-collapse: collapse;} th, td {padding: 8px;}</style></head>"
$emailBodyNM += "Dear IT Reports,<br><br>"
$emailBodyNM += "The below accounts have expired or are about to expire in " + $daysToExpiry + " days:<br><br>"
$emailBodyNM += "<table><tr><th>Account Name</th><th>Expiration Date</th></tr>"

Get-ADUser -Filter 'enabled -eq $true' -SearchBase "$OU" -Properties AccountExpirationDate,Manager | ForEach {
    If ( !$_.Manager ) {
        If ( $_.AccountExpirationDate ) {
            If ($_.AccountExpirationDate -lt (Get-Date).AddDays($daysToExpiry) ) {
                $sendEmailNM = $true
                $emailBodyNM += "<tr><td>" + $_.SamAccountName + "</td><td>" + $_.AccountExpirationDate.ToString('g', [CultureInfo]'en-GB') + "</td></tr>"
            }
        }
    }
}
If ($sendEmailNM) {
         $emailBodyNM += "</table><br>This is an automated report for accounts without the manager info.<br>"
         $emailBodyNM += "<small>Report generated on " + (Get-Date -Format "dd/MM/yyyy HH:mm") + " from " + $env:computername + " by IT</small><br>"
         Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $emailBodyNM -BodyAsHtml -SmtpServer $SMTPServer
         $sendEmailNM = $false
}