# Azan Audio Files

This directory should contain the Azan audio files in MP3 format.

## Required Files:

1. **azan_default.mp3** - Default Azan audio
2. **azan_makkah.mp3** - Makkah Azan audio
3. **azan_madinah.mp3** - Madinah Azan audio
4. **azan_egypt.mp3** - Egyptian Azan audio
5. **azan_turkey.mp3** - Turkish Azan audio

## Where to Get Azan Audio:

You can download Azan audio files from:
- Islamic audio websites
- YouTube (convert to MP3)
- Islamic apps with open-source audio
- Record from local mosque with permission

## File Requirements:

- Format: MP3
- Duration: 2-5 minutes recommended
- Quality: At least 128 kbps
- Size: Keep under 5MB per file for app performance

## Adding Custom Azans:

1. Place MP3 file in this directory
2. Update `pubspec.yaml` to include the new file
3. Add the file path to `PrayerAlarmProvider._availableAzans` list
4. Add the display name to the azan picker in `prayer_alarm_settings_page.dart`

## Note:

For testing purposes, you can use any MP3 audio file. The app will play whatever audio file is specified in the settings.
