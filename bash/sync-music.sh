#!/usr/bin/env bash


# This script is designed to sync Cmus playlists,
# along with the music files that those playlists rely on,
# to an android phone using MTP.

# Cmus playlists are plain text files that contain the absolute
# path to the music file, using this with any other type of
# playlist will almost certainly cause the script to fail.

# This script will also re-encode all flac files down to 320kbps
# using ffmpeg to save space, cause that's what I wanted it to do. 
# Although this process can be skipped, the script will ask 
# whether to re-encode or not when it reaches that stage.

set -o nounset

# Variables used in the script
cmuspl="$HOME/.config/cmus/playlists/"
musicdir="$HOME/Music/Music/"
phonemus=(/run/user/1000/gvfs/*/"Internal shared storage"/Music/)
phonepl=(/run/user/1000/gvfs/*/"Internal shared storage"/BlackPlayer/Playlists/)
temp=$( mktemp -d -t tmp.XXXX )
templog=$( mktemp -d -t tmp.XXXX )
# Null variables
catcmuspl=0
file=0
filter=0
filtercmus=0
filterphone=0
findmusic=0
findstatus=0
findtemp=0

# Cleans up any temp folders/files if the script is interrupted or exited
cleanup(){
    if [[ -d "$temp" ]] || [[ -d "$templog" ]]; then
        printf '%s\n' "Cleaning up left over files..."
        rm -rf "$temp" 2>/dev/null
        rm -rf "$templog" 2>/dev/null
        printf '%s\n' "Clean up process done."
    fi
}
trap cleanup EXIT

# Check if phone is mounted
if [[ -d "${phonemus[*]}" ]]; then
    printf '%s\n' "Phone is mounted."
else
    printf '%s\n' "Phone not mounted - internal phone storage not accessible. Ensure that your phone is connected and set to allow MTP USB connection."
    exit 1
fi

# Check Cmus playlist directory, exit script if none found
printf '%s\n' "Checking Cmus playlist directory..."
if (shopt -s nullglob dotglob; file=("${cmuspl:?}/"*); ((! ${#file[@]}))); then
    printf '%s\n' "Cmus playlist directory is empty, this script will fail if there are no playlists to inspect."
    exit 1
else
    # Else if playlists are found, recreate them on phone
    printf %s\\n "Cmus playlists found, recreating on phone..."
    if for playlist in "${cmuspl:?}/"*; do playlistname=$( cut -d'/' -f8 <<< "$playlist")
        cut -d'/' -f5- < "$playlist" | sed "s|^|/|; s|.flac||g; s|.mp3||g" > "${phonepl[*]}/$playlistname"; done; then
        printf %s\\n "Playlists have successfully been synced to phone."
    else
        printf %s\\n "Failed to sync playlists to phone."
        exit 1
    fi
fi

# Check phone music directory, if empty sync all music
if (shopt -s nullglob dotglob; file=("${phonemus[*]}/"*); ((! ${#file[@]}))); then
    cat "${cmuspl:?}/"* > "$templog/temp_music.log"
    printf '%s\n' "Attempting to copy music to temp directory."
    if awk -F'/' '{ print $6,$7,$8 }' OFS='/' "$templog/temp_music.log" | rsync -vhr --files-from - "$musicdir" "$temp"; then
        printf '%s\n' "All files copied successfully."
    else
        printf '%s\n' "Failed to copy files, terminating script."
        exit 1
    fi
else
    # Else find differences between computer and phone
    printf '%s\n' "Checking phone music directory for differences..."
    catcmuspl=$( cat "${cmuspl:?}/"* )
    cut -d'/' -f5- <<< "$catcmuspl" | sed 's/\.flac//g; s/\.mp3//g' > "$templog/sedcmus.log"
    findmusic=$( find "${phonemus[*]}" -type f ) 
    cut -d'/' -f8- <<< "$findmusic" | sed 's/\.flac//g; s/\.mp3//g' > "$templog/sedphone.log"
    filter=$( comm -3 <(sort "$templog/sedcmus.log") <(sort "$templog/sedphone.log") )
    case "$filter" in
        *"Music"*) printf '%s\n' "Checking for un-used music on phone..."
            filterphone=$( comm -13 <(sort "$templog/sedcmus.log") <(sort "$templog/sedphone.log") )
            case "$filterphone" in
                *"Music"*) printf '%s\n' "Un-used files found on phone."
                    # Ask for confirmation to delete differences off phone
                    while true; do
                        read -rp "Do you want to remove all music from your phone that is not being used by the new playlists (Y/n)? " yn
                        case $yn in
                            [Yy]*|'') printf '%s\n' "Yes."
                                printf '%s\n' "Attemping to remove music not actively being used by playlists..."
                                sed "s|Music/|${phonemus[*]}|; s|$|.flac|" <<< "$filterphone" > "$templog/rmphone.log"
                                sed "s|Music/|${phonemus[*]}|; s|$|.mp3|" <<< "$filterphone" >> "$templog/rmphone.log"
                                if while read -r; do rm -r "$REPLY" 2>/dev/null; done < <(cat "$templog/rmphone.log" 2>/dev/null); then
                                    find "${phonemus[*]}" -empty -type d -delete
                                    printf '%s\n' "Un-wanted music successfully removed from phone."
                                else
                                    cut -d'/' -f2- <<< "$filterphone" > "$templog/rmfilter.log"
                                    cut -d'/' -f9- <<< "$findmusic" | sed 's/\.flac//g; s/\.mp3//g' > "$templog/sedrm.log"
                                    cmp -s <(sort "$templog/rmfilter.log") <(sort "$templog/sedrm.log")
                                    case $? in
                                        0) printf '%s\n' "Un-wanted music successfully removed from phone."
                                            ;;
                                        1) printf '%s\n' "Failed to remove Un-wanted music, terminating script."
                                            exit 1
                                            ;;
                                        *) printf '%s\n' "Encountered an error around line 161."
                                            exit 1
                                    esac
                                fi
                                break
                                ;;
                            [Nn]*) printf '%s\n' "No."
                                break
                                ;;
                            *) printf '%s\n' "Please answer yes or no."
                        esac
                    done
                    ;;
                *) printf '%s\n' "No un-used files found on phone."
            esac
            # Sync any new music files not already found on phone
            filtercmus=$( comm -23 <(sort "$templog/sedcmus.log") <(sort "$templog/sedphone.log") )
            case "$filtercmus" in
                *"Music"*) printf '%s\n' "New files found, syncing to phone..."
                    sed "s|Music/||1; s|$|.flac|" <<< "$filtercmus" > "$templog/temp_music.log"
                    sed "s|Music/||1; s|$|.mp3|" <<< "$filtercmus" >> "$templog/temp_music.log"
                    if rsync -vhr --files-from="$templog/temp_music.log" "$musicdir" "$temp" 2>/dev/null; then
                        printf '%s\n' "All files copied successfully."
                    else
                        cut -d'/' -f2- <<< "$filtercmus" > "$templog/filtercmus.log"
                        findtemp=$( find "$temp" -type f )
                        cut -d'/' -f4- <<< "$findtemp" | sed 's/\.flac//g; s/\.mp3//g' > "$templog/sedtemp.log"
                        cmp -s <(sort "$templog/filtercmus.log") <(sort "$templog/sedtemp.log")
                        case $? in
                            0) printf '%s\n' "All files copied successfully."
                                ;;
                            1) printf '%s\n' "Differences found in after transfer check, failed to sync all files. Terminating script."
                                exit 1
                                ;;
                            *) printf '%s\n' "Encountered an error around line 195."
                                exit 1
                        esac
                    fi
                    ;;
                *) printf '%s\n' "Script encountered an error while attempting to sync new files."
                    exit 1
            esac
            ;;
            # If no differences between computer and phone are found ask to exit script
            *) printf '%s\n' "No differences were found, terminating script."
            exit 0
    esac
fi

# Allow user to decide if they want to re-encode flac files
while true; do
    read -rp "Would you like to re-encode all flac files to 320kbps MP3 (Y/n)? " yn
    case $yn in
        [Yy]*|'') printf '%s\n' "Yes."
            # Re-encode temp directory music files with ffmpeg
            printf '%s\n' "Attempting to re-encode flac files to save space..."
            findstatus=$( find "$temp" -name "*.flac" 2>&1 )
            case "$findstatus" in
                *.flac) 
                    if find "$temp" -name "*.flac" -exec sh -c 'ffmpeg -v quiet -stats -i "$1" -acodec libmp3lame -ab 320k -y "${1%.*}.mp3"' sh {} \; 1>/dev/null 2>&1; then
                        printf '%s\n' "Flac files have been successfully re-encoded."
                        printf '%s\n' "Attempting to remove un-wanted flac files from temp directory..."
                        # Remove flac files from temp music directory
                        if find "$temp" -name "*.flac" -exec rm {} \; 2>&1; then
                            printf '%s\n' "Un-wanted flac files removed successfully from temp directory."
                        else
                            printf '%s\n' "Failed to remove un-wanted files from temp directory, terminating script."
                            exit 1
                        fi
                    else
                        printf '%s\n' "Failed to re-encode flac files, terminating script."
                        exit 1
                    fi
                    break
                    ;;
                *) printf '%s\n' "No flac files detected, skipping re-encode process."
                    break
            esac
            ;;
            # Skips re-encode process if user answers no
            [Nn]*) printf '%s\n' "No."
            printf '%s\n' "Skipping re-encode process."
            break
            ;;
        *) printf '%s\n' "Please answer yes or no."
    esac
done

# Rsync temp directory to phone music directory, delete music temp directory once complete
printf '%s\n' "Attempting to copy music files to phone..."
if rsync -vhr --ignore-existing "$temp/" "${phonemus[*]}/" 2>&1; then
    printf '%s\n' "Music files have successfully been copied to your phone, you may now disconnect your phone."
else
    printf '%s\n' "Failed to copy music files to the phone, terminating script."
    exit 1
fi


