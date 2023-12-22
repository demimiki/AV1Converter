# Encodes every video in this folder and subfolder to AV1, then saves them in ./Converted/ with <filename>.mp4 name
# Conversion can be cancelled by pressing 'Ctrl-C' or cancel only the current conversion by pressing 'q'
# Outputed filesize depends on the input filesize, but on some cases it can save up to 90% in size (while using NVENC or h.264 encoding)
# targetQuality modifies the available bitrate (1-63). Most of the time the default 50 value is ideal. Decrease the value if you want higher quality (might not increase quality, while increases filesize)
# compressionLevel determines the used algorithm for encoding (0-12). Lower values will significantly increase the encoding time, but can further reduce the filesize. Default value is 7
# Note: encoding will use all available CPU cores. This can't be reduced right now due to limitations in the SVT-AV1 encoding library. Use CPU affinities in task manager to reduce the maximum load

#****************OPTIONS****************#

$targetQuality = 50
$compressionLevel = 7

#***************************************#



$listOfVideoFiles = (Get-ChildItem -Path ./ -Recurse -Include *.mp4, *.mkv | Select-Object -ExpandProperty FullName) -notlike '*Converted*'
$listOfPhotoFiles = (Get-ChildItem -Path ./ -Recurse -Include *.jpg, *.jpeg, *.png | Select-Object -ExpandProperty FullName) -notlike '*Pics*'

Out-File -FilePath ./listOfConvertedFiles.txt

$i=0
$codecTypeArray = ,0 * $listOfVideoFiles.Count

Write-Host `nFinding mp4 video files and photos

foreach ($videoPath in $listOfVideoFiles){
    $codecTypeArray[$i] = @(.\ffprobe `
		-v error `
		-select_streams v:0 -show_entries stream=codec_name `
		-of default=noprint_wrappers=1:nokey=1 `
		$videoPath)
    $i++
}

$non_av1_fileCount=0
foreach ($item in $codecTypeArray){
    if ($item -ne 'av1'){
        $non_av1_fileCount++
    }
}

Write-Host `nFound $non_av1_fileCount video files to convert

$i=0
$c=0
foreach ($item in $codecTypeArray){
    if ($item -eq 'av1'){
        #av1 encoded video detected, skipping
		$i++
        continue
    }
	$fullpath=((Get-Item $listOfVideoFiles[$i]).DirectoryName)
	$modified_output=$fullpath -replace [regex]::Escape($pwd.ToString()),""
	$outputPath = $pwd.ToString()+`
		'\Converted'+`
		$modified_output
	
	$outputFile = $outputPath+'\'+`
		(((Get-Item $listOfVideoFiles[$i]).Basename)+".mp4")
	
	if(-not (Test-Path $outputPath)){
		New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
	}
	
	Write-Host "`nWorking on: $outputFile`n"
	
    .\ffmpeg.exe -i $listOfVideoFiles[$i] -v quiet -stats -c:a libopus -b:a 96k -c:v libsvtav1 -preset $compressionLevel -crf $targetQuality $outputFile
	
	Add-Content ./listOfConvertedFiles.txt $outputFile
	$c++
	Write-Host "`n$c/$non_av1_fileCount file converted 🕑" -ForegroundColor DarkGreen
    $i++
}
if ($non_av1_fileCount){
	Write-Host `nFiles converted to AV1 👌
}

$c=0
foreach ($item in $listOfPhotoFiles){
	$fullpath=((Get-Item $item).DirectoryName)
	$modified_output=$fullpath -replace [regex]::Escape($pwd.ToString()),""
	$outputPath = $pwd.ToString()+`
		'\Pics'+`
		$modified_output
	
	if(-not (Test-Path $outputPath)){
		New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
	}
	
	$outputPath=$outputPath+'\'+`
		(Get-Item $item).Name
	
	Move-Item -Path $item -Destination $outputPath
	$c++
}

if ($c){
	Write-Host `n$c photos moved to Pics folder 👌
}else{
	Write-Host `nNo photo found!
}

Get-ChildItem -Path .\ -Recurse -Force -Directory | 
    Sort-Object -Property FullName -Descending |
    Where-Object { $($_ | Get-ChildItem -Force | Select-Object -First 1).Count -eq 0 } |
    Remove-Item

Write-Host `nRemoved empty folders`n

pause
