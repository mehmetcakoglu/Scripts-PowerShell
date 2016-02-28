# usage example
# Move-Database -database "MyDatabase" -newPath "D:\SqlData";

function Move-Database
{
    param ($database, $newPath)

    $paths = Invoke-SqlCmd "SELECT master_files.physical_name as Path
        FROM sys.databases
        JOIN sys.master_files ON master_files.database_id = databases.database_id
        WHERE databases.name = '$database';";

    $paths = $paths | % { $_.Path };

    if (!$paths)
    {
        throw "Unknown database '$database'";
    }

    Write-Host "Setting $database to single-user mode...";
    Invoke-SqlCmd "ALTER DATABASE [$database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;";

    Write-Host "Detaching $database";
    Invoke-SqlCmd "EXEC sp_detach_db '$database';";

    if (!(test-path $newPath))
    {
        [void](mkdir $newPath);
    }

    $clauses = @();

    foreach ($oldFile in $paths)
    {
        $filename = [System.IO.Path]::GetFileName($oldFile);
        $newFile = [System.IO.Path]::Combine($newPath, $filename);

        $clauses += "(FILENAME = `"$newFile`")";

        Write-Host "Moving $oldFile to $newFile";
        mv $oldFile $newFile;
    }

    $clauses = $clauses -join ", ";

    Write-Host "Re-attaching $database";
    Invoke-SqlCmd "CREATE DATABASE [$database] ON $clauses FOR ATTACH;";
    Write-Host "All done!";
}