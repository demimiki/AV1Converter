# Encodes every video in this folder and subfolder to AV1, then saves them in ./Converted/ with <filename>.mp4 name
# Conversion can be cancelled by pressing 'Ctrl-C' or cancel only the current conversion by pressing 'q'
# Outputed filesize depends on the input filesize, but on some cases it can save up to 90% in size (while using NVENC or h.264 encoding)
# targetQuality modifies the available bitrate (1-63). Most of the time the default 48 value should be fine. Decrease the value if you want higher quality (might not increase quality, while increases filesize)
# compressionLevel determines the used algorithm for encoding (0-12). Lower values will significantly increase the encoding time, but can further reduce the filesize. Default value is 6
# Note: encoding will use all available CPU cores. This can't be reduced right now due to limitations in the SVT-AV1 encoding library. Use CPU affinities in task manager to reduce the maximum load

# Changelog
#
# Now checks if ffmpeg and ffprobe are installed instead of exiting. If they're present in the directory (or sub-directory) it'll still use those files

#****************OPTIONS****************#

$targetQuality = 48
$compressionLevel = 6
$saveConvertedFilenames = $False

#***************************************#



$listOfVideoFiles = (Get-ChildItem -Path ./ -Recurse -Include *.mp4, *.mkv | Select-Object -ExpandProperty FullName) -notlike '*Converted*'
$listOfPhotoFiles = (Get-ChildItem -Path ./ -Recurse -Include *.jpg, *.jpeg, *.png | Select-Object -ExpandProperty FullName) -notlike '*Pics*'

if ($saveConvertedFilenames){
	Out-File -FilePath ./listOfConvertedFiles.txt
}

#Check if ffmpeg present in directory, sub-directory or it's installed
$ffmpeg = (Split-Path -Parent $pwd) + "\ffmpeg.exe"
if ((Test-Path $ffmpeg -PathType Leaf) -ne $True){
	$ffmpeg = [String]($pwd) + "\ffmpeg.exe"
	if ((Test-Path $ffmpeg -PathType Leaf) -ne $True){
		if (Get-Command ffmpeg -ErrorAction SilentlyContinue){
			$ffmpeg="ffmpeg"
		}else{
			Write-Host "No ffmpeg found, exiting..."
			pause
			Stop-Process -ID $PID -Force
		}
	}
}

#Check if ffprobe present in directory, sub-directory or it's installed
$ffprobe = (Split-Path -Parent $pwd) + "\ffprobe.exe"
if ((Test-Path $ffprobe -PathType Leaf) -ne $True){
	$ffprobe = [String]($pwd) + "\ffprobe.exe"
	if ((Test-Path $ffprobe -PathType Leaf) -ne $True){
		if (Get-Command ffprobe -ErrorAction SilentlyContinue){
			$ffprobe="ffprobe"
		}else{
			Write-Host "No ffprobe found, exiting..."
			pause
			Stop-Process -ID $PID -Force
		}
	}
}

#Search for codec format and length
$i=0
$codecTypeArray = ,0 * $listOfVideoFiles.Count
$lengthArray = ,0 * $listOfVideoFiles.Count

Write-Host `nFinding mp4 video files and photos

foreach ($videoPath in $listOfVideoFiles){
	$videoPath = '"' + $videoPath + '"'
    $codecTypeArray[$i] = @(Invoke-Expression ($ffprobe + `
		" -v error " + `
		"-select_streams v:0 -show_entries stream=codec_name " + `
		"-of default=noprint_wrappers=1:nokey=1 " + `
		$videoPath))
	$lengthArray[$i] = @(Invoke-Expression ($ffprobe + `
		" -v error " + `
		"-select_streams v:0 -show_entries format=duration " + `
		"-of default=noprint_wrappers=1:nokey=1 " + `
		$videoPath))
    $i++
}

#Count how many of the videos are not AV1 encoded
$non_av1_fileCount=0
foreach ($item in $codecTypeArray){
    if ($item -ne 'av1'){
        $non_av1_fileCount++
    }
}

Write-Host `nFound $non_av1_fileCount video files to convert

#Check videofile list, if non-AV1, then corvert it
$index=0
$count=0
foreach ($item in $codecTypeArray){
    if ($item -eq 'av1'){
        #av1 encoded video detected, skipping
		$index++
        continue
    }
	$fullpath=((Get-Item $listOfVideoFiles[$index]).DirectoryName)
	$modified_output=$fullpath -replace [regex]::Escape($pwd.ToString()),""
	$outputPath = $pwd.ToString()+`
		'\Converted'+`
		$modified_output
	
	$outputFile = $outputPath+'\'+`
		(((Get-Item $listOfVideoFiles[$index]).Basename)+".mp4")
	
	if(-not (Test-Path $outputPath)){
		New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
	}
	
	$durationArray = $lengthArray[$index]
	[int]$duration = $durationArray[0]
	$second = $duration % 60
	$duration = $duration - $second
	[int]$minute = ($duration / 60) % 60
	$duration = $duration - ($minute * 60)
	[int]$hour = $duration / 3600
	if ($hour -le 9){
		$length = "0" + [string]$hour
	}else{
		$length = [string]$hour
	}
	if ($minute -le 9){
		$length += ":0" + [string]$minute
	}else{
		$length += ":" + [string]$minute
	}
	if ($second -le 9){
		$length += ":0" + [string]$second
	}else{
		$length += ":" + [string]$second
	}
	
	$out = ((Get-Item $listOfVideoFiles[$index]).Basename) + ".mp4"
	Write-Host "`nWorking on ($length): $out`n"
	#Set progress bar sequence format to show progress
	Write-Host -NoNewline ([char]27 + "]9;4;1;" + [int](($count/$non_av1_fileCount)*100+1) + [char]7)
	$inPath = $listOfVideoFiles[$index]
	$inPath = '"' + $inPath + '"'
	$outputFile = '"' + $outputFile + '"'
    Start-Process -FilePath $ffmpeg -ArgumentList "-v quiet", "-stats", "-i $inPath", "-c:a libopus", "-b:a 96k", "-c:v libsvtav1", "-preset $compressionLevel", "-crf $targetQuality", $outputFile -Wait -NoNewWindow
	
	if ($saveConvertedFilenames){
		#Output what file been processed
		Add-Content ./listOfConvertedFiles.txt $outputFile
	}
	$count++
	Write-Host "`n$count/$non_av1_fileCount file converted 🕑" -ForegroundColor DarkGreen
    $index++
}
if ($non_av1_fileCount){
	Write-Host `nFiles converted to AV1 👌
}

#Move photos
$count=0
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
	$count++
}

#Number of photos moved
if ($count){
	Write-Host `n$count photos moved to Pics folder 👌
}else{
	Write-Host `nNo photo found!
}

#Set progress bar sequence format to show that the conversion is done
Write-Host -NoNewline ([char]27 + "]9;4;4;100" + [char]7)

#Clean up empty folders
Get-ChildItem -Path .\ -Recurse -Force -Directory | 
    Sort-Object -Property FullName -Descending |
    Where-Object { $($_ | Get-ChildItem -Force | Select-Object -First 1).Count -eq 0 } |
    Remove-Item

Write-Host `nRemoved empty folders`n

pause
#Set progress bar sequence format back to default state
Write-Host -NoNewline ([char]27 + "]9;4;0;0" + [char]7)
