# AV1 Converter
A PS script for converting to AV1 codec format. Encodes every video in the folder and subfolder to AV1, then saves them in ./Converted/ with "filename.mp4" name. Photos are collected in the ./Pics/ folder.</br>
It's using the SVT-AV1 library (CPU encode only). The audio tracks will be converted to Opus format for further compression.

## Notes
There is 2 options inside the script.</br>
+ <i>targetQuality</i> modifies the available bitrate (1-63). Most of the time the default 50 value is ideal. Decrease the value if you want higher quality (might not increase quality, while increases filesize)</br>
+ <i>compressionLevel</i> determines the used algorithm for encoding (0-12). Lower values will significantly increase the encoding time, but can further reduce the filesize. Default value is 7</br>

Encoding will use all available CPU cores. This can't be reduced right now due to limitations in the SVT-AV1 encoding library. Use CPU affinities in task manager to reduce the maximum load.</br>

## Usage
1. Download the latest full ffmpeg package from https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-full.7z
2. Extract both ffmpeg.exe and ffprobe.exe
3. Place the script and extracted files to the root of your videos folder
4. Run the AV1_Encoder.ps1 powershell script by right click -> Run with Powershell or inside a terminal

It should look like this:

```
C:\Video\
   - Converted\
      - Cool videos\
         - converted_video1.mp4
         - ...
   - Pics\
      - screenshot.png
      - ...
   - Cool videos\
      - video_to_be_converted.mp4
      - ...
   - AV1_Encoder.ps1
   - ffmpeg.exe
   - ffprobe.exe
```
