# AV1 Converter
A PS script for converting to AV1 codec format. Encodes every video in the folder and subfolder to AV1, then saves them in ./Converted/ with "filename.mp4" name. Photos are collected in the ./Pics/ folder.</br>
It's using the SVT-AV1 library (CPU encode only). The audio tracks will be converted to Opus format for further compression.

## Notes
There is 2 options inside the script.</br>
+ <i>targetQuality</i> modifies the available bitrate (1-63). Most of the time the default 48 value is ideal. Decrease the value if you want higher quality (might not increase quality, while increases filesize)</br>
+ <i>compressionLevel</i> determines the used algorithm for encoding (0-13). Lower values will significantly increase the encoding time, but can further reduce the filesize. Default value is 6</br>

Encoding will use all available CPU cores. This can't be reduced right now due to limitations in the SVT-AV1 encoding library. Use CPU affinities in task manager to reduce the maximum load.</br>

## Speed and quality
On an AMD Ryzen 5 5600X the speed is usually around 8-10 FPS, but that heavily depends on the scene.</br>
While using Nvidia's recorder with settings at 1440p, 120 FPS and 150 Mbps bitrate, the output is usually around 90 Mbps. After converting this with AV1 the result bitrate is 10 Mbps, while the perceivable quality degradation is negligible. Measurements made with SVT-AV1 v1.8.0.

## Usage
Using the pre-installed method:
1. Install ffmpeg with <code>winget install ffmpeg</code>
2. Place the script to the root of your videos folder
3. Run the AV1_Encoder.ps1 powershell script by right click -> Run with Powershell or inside a terminal

Using the manual download method:
1. Download the latest full ffmpeg package from https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-full.7z</br>
   <i>or build your own ffmpeg for slightly faster file format detection (only the --enable-libsvtav1 and --enable-libopus flags are needed)</i>
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
   - ffmpeg.exe (optional)
   - ffprobe.exe (optional)
```
