#!/bin/bash
#
# PowerStatus10k segment.
# This segment displays the current CMus status.

TAG_LIST=(tag status file artist album tracknumber title date duration)

# Utilities

# Check if the given word is a known tag.
#
# Arguments:
#   $1 - word
#
# Returns:
#   true  - if word is a known tag
#   false - else
#
function checkTag {
  # Iterate over all known tags to compare.
  for (( i=0; i<${#TAG_LIST[@]}; i++ )) ; do
    if [[ "$1" = ${TAG_LIST[i]} ]] ; then
      echo true
      return
    fi
  done

  # No tag has fit.
  echo false
}

# Get the value of a tag.
# Filter the content between the tags key and the next tag key.
# In the end the content get trimmed.
#
# Arguments:
#   $1 - status string of CMus
#   $2 - tag to get
#
# Returns:
#   string as value of the tag (possibly empty)
#
function getTag {
  tag=""

  # Get where the tags value starts.
  eval "start=\$(echo \"$input\" | grep -o -P '(?<=$2).*')"

  if [[ -n "$start" ]] ; then
    IFS=' ' read -ra words <<< "$start"
    # Add every word until next tag.
    index=0
    finished=false

    while [[ "$finished" != true ]] ; do
      word=${words[index]}
      finished=$(checkTag "$word") # Check if this word is the next tag key.
      [[ -z "$word" ]] && finished=true # If it is the last word.
      [[ "$finished" = false ]] && tag="${tag} ${word}" # Add word to the tag if part of it.
      index=$((index + 1)) # Go to next word.
    done
  fi 

  # Trim whitespaces.
  tag=$(sed -e 's/[[:space:]]*$//' <<<${tag})

  echo "${tag}"
}

# Define a format string to show the current status.
# The status depends on the first word of the CMus  string.
# Use the icons and colors to display the status.
#
# Arguments:
#   $1 - CMus status
#
# Returns:
#   format string for the status
#
function getStatusFormatString {
  # Get the status tag.
  status=$(getTag "$1" "status")

  # Build the format string with the prefix to change the font color.
  formatString="%{F"

  # Choose the correct color and icon depending on the status.
  if [[ "$status" = "playing" ]] ; then
    formatString="${formatString}${CMUS_COLOR_PLAY}}${CMUS_ICON_PLAY}"

  elif [[ "$status" = "paused" ]] ; then
    formatString="${formatString}${CMUS_COLOR_PAUSE}}${CMUS_ICON_PAUSE}"

  else
    formatString="${formatString}${CMUS_COLOR_STOP}}${CMUS_ICON_STOP}"
  fi


  # Finalize the format string and return.
  formatString="${formatString}%{F-}"
  echo "${formatString}"
}


# Interface

# Implement the interface function for the initial subscription state.
#
function initState_cmus {
  # One time get actively the state of the player.
  # Do not use '-Q' cause it throw an error if CMus is not running.
  status=$(cmus-remote -C status)

  # Check if CMus is running.
  if [[ -n "$status" ]] ; then
    # Use default formatting function as for subscription.
    { format_cmus "${status}"; }

  else
    # Only show the icon.
    formatString="${CMUS_ICON_BASE}"
    STATE="${formatString}"
  fi
}

# Implement the interface function to format the current state of the subscription.
#
function format_cmus {
  # Replace quotation marks, cause they lead to problems.
  input=$(echo $1 | sed -e 's/\"/\\\"/g')

  # Get all interesting tags.
  status=$(getStatusFormatString "$input")
  artist=$(getTag "$input" "artist")
  title=$(getTag "$input" "title")
  file=$(getTag "$input" "file")

  # The basic format string.
  formatString="${CMUS_ICON_BASE} ${status}"

  # Use the artist and titel per default.
  if [[ -n "$artist" ]] ; then
    artistAbbr=$(abbreviate "$artist" "cmus")
    titleAbbr=$(abbreviate "$title" "cmus")
    formatString="${formatString} ${artistAbbr} - ${titleAbbr}"
    # Use the file name if no artist is defined.

  elif  [[ -n "$file" ]] ; then
    fileName=$(basename "$file")
    name="${fileName%.*}"
    nameAbbr=$(abbreviate "$name" "cmus")
    formatString="${formatString} ${nameAbbr} ${CMUS_ICON_FILE}"
  fi

  STATE="${formatString}"
}
