#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export FOLDERS_COLOR="${FOLDERS_COLOR:-"plasma"}"
export ICON_PACK_THEME="${ICON_PACK_THEME:-"Gruvbox-Plus-Dark"}"

# Browse icons directories in this order:
# - $XDG_DATA_HOME/icons (defaults to $HOME/.local/share/icons)
# - $HOME/.icons (for backwards compatibility)
# - $XDG_DATA_DIRS/icons (defaults to /usr/local/share/icons:/usr/share/icons)
icon_pack_path() {
  if [[ -d "${XDG_DATA_HOME:-"${HOME}/.local/share"}/icons/${ICON_PACK_THEME}" ]]; then
    echo "${XDG_DATA_HOME:-"${HOME}/.local/share"}/icons/${ICON_PACK_THEME}"
    return 0
  elif [[ -d "${HOME}/.icons/${ICON_PACK_THEME}" ]]; then
    echo "${HOME}/.icons/${ICON_PACK_THEME}"
    return 0
  else
    data_dirs=$(echo "${XDG_DATA_DIRS:-"/usr/local/share:/usr/share"}" | tr ":" "\n")
    for path in $data_dirs; do
      if [[ -d "${path%%/}/icons/${ICON_PACK_THEME}" ]]; then
        echo "${path%%/}/icons/${ICON_PACK_THEME}"
        return 0
      fi
    done
  fi
  return 1
}

if [[ ! -d "$(icon_pack_path)" ]]; then
  echo "Icon pack path not found. Abort."
  exit 1
fi

scalable_places_directory="$(icon_pack_path)/places/scalable"

if [[ ! -d "${scalable_places_directory}" ]]; then
  echo "Folder icons not found. Abort."
  exit 1
fi

colors="black blue citron firebrick gold green grey highland jade lavender lime olive orange pistachio plasma pumpkin purple red rust sapphire tomato violet white yellow"

current_color() {
  readlink "${scalable_places_directory}/folder.svg" | cut --delimiter "-" --fields 2 | cut --delimiter "." --fields 1
}

help="Folders color chooser

Icon pack path: $(icon_pack_path)

Current color: $(current_color)

Usage: ${0##*/} [-c | --color] FOLDERS_COLOR [-h | --help] [-l | --list]

Environment:
  FOLDERS_COLOR     color to change to (default: plasma)
  ICON_PACK_THEME   name of the Gruvbox Plus icon pack (default: Gruvbox-Plus-Dark)

Options:
  -c, --color=FOLDERS_COLOR   set the new folders color (default: plasma)
  -h, --help                  show this help
  -l, --list                  list available colors"

old_folders_color="$(current_color)"

# options
while [[ "$#" -gt 0 && "$1" =~ ^- && ! "$1" == "--" ]]; do case "$1" in
  -c | --color )
    shift; FOLDERS_COLOR="$1"
    ;;
  -h | --help )
    echo -e "${help}"
    exit
    ;;
  -l | --list )
    echo "Available colors are:"
    echo "${colors}"
    exit
    ;;
esac; shift; done

if [[ "$#" -gt 0 ]]; then
  case "$1" in
    "--")
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
fi

if [[ "${FOLDERS_COLOR}" == "$(current_color)" ]]; then
  echo "No changes. It's already ${FOLDERS_COLOR}."
  exit
fi

if [[ -f "${scalable_places_directory}/folder-${FOLDERS_COLOR}.svg" ]]; then
  pushd "${scalable_places_directory}" 1>/dev/null
  for i in $(realpath "*-${FOLDERS_COLOR}*.svg"); do
    filename="${i##*/}"

    case "${filename}" in
      "bookmarks-${FOLDERS_COLOR}.svg")
        ln -sfn "${filename}" "folder-bookmark.svg"
        ;;

      *)
        ln -sfn "${filename}" "${filename/-${FOLDERS_COLOR}/}"
        ;;
    esac
  done
  popd 1>/dev/null

  echo "Changed from ${old_folders_color} to ${FOLDERS_COLOR}."
else
  echo "Invalid color: ${FOLDERS_COLOR}"
  echo "Please peak one of:"
  echo "${colors}"
  exit 1
fi
