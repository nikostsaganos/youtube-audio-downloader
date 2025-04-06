# YouTube Audio Downloader

A Ruby script that automatically downloads and organizes YouTube videos as MP3 files based on a YAML configuration file.

## Features

- **Smart Downloading**: Only downloads new videos, skips existing files
- **Folder Organization**: Organizes downloads into customizable folders
- **Progress Tracking**: Visual progress bar shows download status
- **Detailed Reporting**: Summarizes what needs to be downloaded
- **Flexible Configuration**: Configurable paths for both config file and output directory
- **Quiet Mode**: Option for minimal output during operation

## Requirements

- Ruby 2.6 or higher
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) command-line tool
- FFmpeg (for audio conversion)

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/youtube-audio-downloader.git
   cd youtube-audio-downloader
   ```

2. Install the required Ruby gems:
   ```
   gem install yaml fileutils
   ```

3. Install [yt-dlp](https://github.com/yt-dlp/yt-dlp#installation):
   ```
   # Using pip (Python package installer)
   pip install -U yt-dlp
   
   # Or on macOS with Homebrew
   brew install yt-dlp
   ```

4. Install FFmpeg:
   ```
   # On macOS
   brew install ffmpeg
   
   # On Ubuntu/Debian
   apt-get install ffmpeg
   
   # On Windows
   # Download from https://ffmpeg.org/download.html
   ```

5. Create your configuration file:
   ```
   # Copy the example configuration file
   cp config.example.yml config.yml
   
   # Edit the config.yml file with your favorite editor
   nano config.yml
   ```

## Usage

1. Make sure you've created a `config.yml` file by copying and modifying the example file:
   ```yaml
   # config.yml
   folder_name_1:
     - https://www.youtube.com/watch?v=video_id_1
     - https://www.youtube.com/watch?v=video_id_2
   folder_name_2:
     - https://www.youtube.com/watch?v=video_id_3
   ```

2. Run the script:
   ```
   ruby youtube_audio_downloader.rb
   ```

3. Command line options:
   ```
   ruby youtube_audio_downloader.rb --help
   
   Options:
     -c, --config PATH : Path to configuration YAML file (default: ./config.yml)
     -o, --output DIR  : Path to output music directory (default: ./music)
     -q, --quiet       : Run in quiet mode with minimal output (just progress bar)
     -h, --help        : Show this help message
   ```

### Custom Paths Example

```bash
# Use a different config file
ruby youtube_audio_downloader.rb --config ~/my_playlists.yml

# Save to a different music directory
ruby youtube_audio_downloader.rb --output /media/music

# Combine multiple options
ruby youtube_audio_downloader.rb --config ~/playlists/youtube.yml --output /media/external/music --quiet
```

## Example Configuration

The repository includes a sample configuration file (`config.example.yml`) that you can use as a starting point:

```yaml
# Copy from config.example.yml to config.yml and modify as needed
rock:
  - https://www.youtube.com/watch?v=dQw4w9WgXcQ
  - https://www.youtube.com/watch?v=ZyhrYis509A
ambient:
  - https://www.youtube.com/watch?v=5qap5aO4i9A
  - https://www.youtube.com/watch?v=DWcJFNfaw9c
study:
  - https://www.youtube.com/watch?v=jfKfPfyJRdk
```

This configuration will create three folders (`rock`, `ambient`, and `study`) inside the output directory and download the specified videos as MP3 files into their respective folders.

## Directory Structure

After running the script with the example configuration, your directory structure will look like:

```
output_directory/
├── rock/
│   ├── Rick Astley - Never Gonna Give You Up [dQw4w9WgXcQ].mp3
│   └── Aqua - Barbie Girl [ZyhrYis509A].mp3
├── ambient/
│   ├── lofi hip hop radio - beats to relax/study to [5qap5aO4i9A].mp3
│   └── lofi hip hop radio - beats to sleep/chill to [DWcJFNfaw9c].mp3
└── study/
    └── lofi hip hop radio 📚 - beats to relax/study to [jfKfPfyJRdk].mp3
```

## How It Works

1. The script reads the specified configuration file (`config.yml` by default)
2. It scans the output directory for existing files
3. It identifies which videos from your configuration need to be downloaded
4. It displays a summary of what will be downloaded
5. It downloads only new files with a progress indicator
6. Files are organized into folders as specified in your configuration

## Use Cases

- **Music Collections**: Organize your favorite YouTube music by genre
- **Podcasts**: Download podcast episodes for offline listening
- **Lectures**: Save educational content in organized categories
- **Playlists**: Convert your YouTube playlists to offline MP3 collections

## License

MIT License
