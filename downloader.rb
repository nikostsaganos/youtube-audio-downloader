#!/usr/bin/env ruby
# frozen_string_literal: true

# YouTubeAudioDownloader
#
# A Ruby script that downloads YouTube videos as MP3 files based on a YAML configuration file.
#
# Usage:
#   ruby youtube_audio_downloader.rb [options]
#
# Options:
#   --config, -c PATH : Path to configuration YAML file (default: ./config.yml)
#   --output, -o DIR  : Path to output music directory (default: ./music)
#   --quiet, -q       : Run in quiet mode with minimal output (just progress bar)
#   --help, -h        : Show this help message

require 'yaml'
require 'fileutils'
require 'uri'
require 'cgi'
require 'optparse'

class YouTubeAudioDownloader
  DEFAULT_CONFIG_PATH = File.join(__dir__, 'config.yml')
  DEFAULT_MUSIC_DIR = File.join(__dir__, 'music')
  PROGRESS_WIDTH = 50

  attr_reader :config, :download_queue, :options

  def initialize(options = {})
    @options = {
      verbose: true,
      config_path: DEFAULT_CONFIG_PATH,
      music_dir: DEFAULT_MUSIC_DIR
    }.merge(options)
    
    @config = load_config
    @download_queue = nil
    ensure_music_directories
  end

  def run
    queue_info = build_download_queue
    @download_queue = queue_info[:queue]
    
    display_summary(queue_info) if options[:verbose]
    process_download_queue
  end

  private

  def load_config
    output "📄 Using config file: #{options[:config_path]}", :info if options[:verbose]
    YAML.load_file(options[:config_path])
  rescue Errno::ENOENT
    output "❌ Config file not found: #{options[:config_path]}", :error
    exit(1)
  rescue => e
    output "❌ Error loading config: #{e.message}", :error
    exit(1)
  end

  def ensure_music_directories
    output "📂 Using music directory: #{options[:music_dir]}", :info if options[:verbose]
    FileUtils.mkdir_p(options[:music_dir])
    
    @config.keys.each do |folder_name|
      FileUtils.mkdir_p(File.join(options[:music_dir], folder_name))
    end
  end

  def build_download_queue
    queue = []
    existing_count = 0
    invalid_count = 0

    output "🔍 Scanning for existing files...", :info if options[:verbose]

    @config.each do |folder_name, urls|
      target_dir = File.join(options[:music_dir], folder_name)

      urls.each do |url|
        video_id = extract_video_id(url)
        
        if video_id.nil?
          invalid_count += 1
          output "⚠️  Invalid URL: #{url}", :warning if options[:verbose]
          next
        end
        
        if file_exists?(video_id, target_dir)
          existing_count += 1
        else
          queue << {
            url: url,
            folder: folder_name,
            video_id: video_id,
            target_dir: target_dir
          }
        end
      end
    end

    {
      queue: queue,
      existing_count: existing_count,
      invalid_count: invalid_count,
      total_count: total_url_count
    }
  end

  def total_url_count
    @config.values.flatten.size
  end

  def extract_video_id(url)
    uri = URI.parse(url)
    return nil unless uri.host&.include?('youtu')
    
    CGI.parse(uri.query.to_s)['v']&.first || uri.path.split('/').last
  rescue URI::InvalidURIError
    nil
  end

  def file_exists?(video_id, directory)
    Dir.glob(File.join(directory, '*.mp3')).any? { |f| f.include?(video_id) }
  end

  def display_summary(download_info)
    queue = download_info[:queue]
    output "\n📊 Download Summary:", :info
    output "  • Total URLs in config: #{download_info[:total_count]}", :info
    output "  • Already downloaded: #{download_info[:existing_count]}", :info
    output "  • Invalid URLs: #{download_info[:invalid_count]}", :info if download_info[:invalid_count] > 0
    output "  • New files to download: #{queue.size}", :info
    
    # Group downloads by folder for a better overview
    if queue.any?
      grouped = queue.group_by { |item| item[:folder] }
      grouped.each do |folder, items|
        output "    - #{folder}: #{items.size} files", :info
      end
    end
  end

  def process_download_queue
    if download_queue.empty?
      output "\n✅ Nothing to download. All valid files already exist.", :success
      return
    end
    
    output "\n🚀 Starting download of #{download_queue.size} new files...", :info if options[:verbose]
    
    download_queue.each_with_index do |item, index|
      progress = index + 1
      
      update_progress_bar(progress, download_queue.size, item[:video_id])
      download_result = download_file(item)
      
      if options[:verbose] && !download_result
        output "  ❌ Failed to download: #{item[:video_id]}", :error
      end
    end
    
    output "\n\n✅ Download complete! Downloaded #{download_queue.size} new files.", :success
  end

  def update_progress_bar(current, total, current_item = nil)
    percent = (current.to_f / total * 100).round
    completed_width = (PROGRESS_WIDTH * current / total.to_f).round
    remaining_width = PROGRESS_WIDTH - completed_width
    
    bar = "#{current}/#{total} [" + "█" * completed_width + " " * remaining_width + "] #{percent}%"
    bar += " | Current: #{current_item}" if current_item && options[:verbose]
    
    print "\r#{bar}"
    $stdout.flush
  end

  def download_file(item)
    url = item[:url]
    video_id = item[:video_id]
    target_dir = item[:target_dir]
    
    output "\n  ↓ Downloading: #{item[:folder]}/#{video_id}", :info if options[:verbose]
    
    output_template = File.join(target_dir, "%(title)s [#{video_id}].%(ext)s")
    
    cmd = [
      'yt-dlp',
      '-x',
      '--audio-format', 'mp3',
      '-o', output_template,
    ]
    
    # Add quiet flag if not in verbose mode
    cmd << '--quiet' unless options[:verbose]
    cmd << url
    
    success = system(*cmd)
    return success
  rescue => e
    output "  🔥 Error: #{e.message}", :error if options[:verbose]
    false
  end

  def output(message, level = :info)
    return unless options[:verbose]
    
    # Define colors for different message types
    colors = {
      info: "\e[0m",      # Default
      success: "\e[32m",  # Green
      warning: "\e[33m",  # Yellow
      error: "\e[31m"     # Red
    }
    
    puts "#{colors[level]}#{message}\e[0m"
  end
end

# Parse command line arguments
if __FILE__ == $PROGRAM_NAME
  options = { verbose: true }
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{File.basename(__FILE__)} [options]"
    
    opts.on("-c", "--config PATH", "Path to configuration YAML file (default: ./config.yml)") do |path|
      options[:config_path] = path
    end
    
    opts.on("-o", "--output DIR", "Path to output music directory (default: ./music)") do |dir|
      options[:music_dir] = dir
    end
    
    opts.on("-q", "--quiet", "Run in quiet mode (show only progress bar)") do
      options[:verbose] = false
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end
  
  begin
    parser.parse!
  rescue OptionParser::InvalidOption => e
    puts "❌ #{e.message}"
    puts parser
    exit(1)
  end
  
  YouTubeAudioDownloader.new(options).run
end