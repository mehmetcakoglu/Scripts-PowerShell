function showSelection ($selection)
{
    # $selection = Get-ChildItem "C:\users\public\AccountPictures" -Directory
    Write-Host "hayvans" $selection.Count 
    
    If($selection.Count -gt 1){
        $title = "Selection Prompt"
        $message = "Please select"
        
        # Build the choices menu
        $choices = @()
        For($index = 0; $index -lt $selection.Count; $index++){
        #write-host "asdf " $selection[$index]
        
            $choices += `
                New-Object System.Management.Automation.Host.ChoiceDescription `
                $selection[$index], ($selection[$index])
        
        }

        $options = [System.Management.Automation.Host.ChoiceDescription[]]$choices
        

        $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

        $selection = $selection[$result]
    }

    return $selection
}

$c = @{1="Evet";0="Hayır"}
showselection $c 








$title = "Delete Files"
$message = "Do you want to delete the remaining files in the folder?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Deletes all the files in the folder."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retains all the files in the folder."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"You selected Yes."}
        1 {"You selected No."}
    }