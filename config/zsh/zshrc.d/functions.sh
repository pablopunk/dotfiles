# vim:fileencoding=utf-8:ft=bash:foldmethod=marker
function rm {
  # if it contains -rf then execute command rm
  if [[ "$*" == *"-rf"* ]]; then
    command rm "$@"
    return
  fi
  going_to="/tmp/trash/$USER/$(date +%s%N)"
  mkdir -p "$going_to"
  mv -f "$@" "$going_to"
}
function gcm {
  git commit -m "$*"
}
function gcam {
  if [[ "$*" == *--amend* ]]; then
    git commit -m"$@"
  else
    git add -A
    git commit -m "$*"
  fi
}
function gcamm {
  git commit --amend --message "$*"
}
function powersave {
  # linux
  sudo cpufreq-set -g powersave && \
    sudo pm-powersave true
}
function power {
  sudo cpufreq-set -g performance && \
    sudo pm-powersave false
}

function gclone {
  git clone https://github.com/pablopunk/$1 && cd $1
}

function grebase {
  branch="$(git symbolic-ref --short HEAD)"
  git fetch upstream && \
    git rebase upstream/$branch
}

function greset_hard {
  branch="$(git symbolic-ref --short HEAD)"
  git fetch upstream && \
    git reset --hard upstream/$branch
}

function copy {
  [[ "$(uname)" == "Linux" ]] && xsel --clipboard --input
  [[ "$(uname)" == "Darwin" ]] && pbcopy
}

function weather {
  curl -s "wttr.in/${1-valencia}?format=1"
}

function add_spacer_to_dock {
  defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'
  killall Dock
}

function wait_for_docker {
  local docker_app=""
  declare -A app_paths=(
    ["orbstack"]="/Applications/OrbStack.app"
    ["podman"]="/Applications/Podman Desktop.app"
    ["docker"]="/Applications/Docker.app"
  )

  # Check for Docker apps *before* waiting
  for app in "orbstack" "podman" "docker"; do
    if [ -d "${app_paths[$app]}" ]; then
      docker_app="$app"
      break
    fi
  done

  # Open the app if found *before* waiting
  if [ -n "$docker_app" ]; then
    open "${app_paths[$docker_app]}"
    echo "Opening $docker_app"
  fi

  until docker info &> /dev/null; do
    echo "Waiting for docker to start..."
    sleep 1
  done

  if [[ "$docker_app" == "orbstack" ]]; then
    docker context use "orbstack"
  else
    docker context use "default"
  fi
}

function benchmark_neovim_plugins {
  python3 <(curl -sSL https://raw.githubusercontent.com/hyiltiz/vim-plugins-profile/master/vim-plugins-profile.py) nvim
}

function benchmark_neovim_startuptime {
  hyperfine "nvim --headless +qa" --warmup 5
}

function benchmark_disk {
  folder=$1
  if [ -z "$folder" ]; then
    echo "Usage: $0 <folder>"
    return 1
  fi
  tempfile="$folder/tempfile_delete_me"
  echo "Benchmarking disk speed in $PWD"
  echo
  echo "WRITING..."
  write_output=$(sudo dd if=/dev/zero of=$tempfile bs=120M count=1 2>&1)
  write_speed=$(echo "$write_output" | grep -o '[0-9]* bytes/sec' | awk '{print $1}')
  write_speed_human=$(echo "scale=2; $write_speed/1024/1024" | bc)
  echo "Write speed: ${write_speed_human} MB/s"
  echo
  echo "READING..."
  read_output=$(sudo dd if=$tempfile of=/dev/zero bs=8k 2>&1)
  read_speed=$(echo "$read_output" | grep -o '[0-9]* bytes/sec' | awk '{print $1}')
  read_speed_human=$(echo "scale=2; $read_speed/1024/1024" | bc)
  echo "Read speed: ${read_speed_human} MB/s"
  sudo rm -f $tempfile
}

function tilt_playwright {
  for service in \
    "signup-api" \
    "localstack" \
    "panel-core" \
    "graph-gateway" \
    "maze-api" \
    "maze-video-recording-api" \
    "maze-webapp" \
    "report-webapp" \
    "testing-webapp" \
    "signup-webapp" \
  ; do
    tilt enable "$service"
    tilt trigger "$service"
  done
}

function tilt {
  [[ "$#" -eq 1 && "$1" == "up" ]] && { wait_for_docker; command tilt up; return; }
  [[ "$#" -ge 2 && "$1" == "trigger" ]] && { shift; for arg in "$@"; do command tilt enable "$arg"; command tilt trigger "$arg"; done; return; }
  command tilt $@
}

function defaults_search {
  if [[ -z "$1" ]]; then
    echo "Usage: $0 <search>"
    return
  fi
  defaults domains | tr ', ' '\n' | grep -i $1
}

function wt {
  local delete_mode=false
  local force_mode=false
  local search_term=""
  local selected_worktree=""
  local selected_path=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -d)
        delete_mode=true
        shift
        ;;
      -f)
        force_mode=true
        shift
        ;;
      -df|-fd)
        delete_mode=true
        force_mode=true
        shift
        ;;
      *)
        search_term="$1"
        shift
        ;;
    esac
  done

  git_root="$(git rev-parse --show-toplevel 2> /dev/null)"
  if [[ -z "$git_root" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi
  repo_name="$(basename "$git_root")"
  worktree_base="$HOME/.worktrees/$repo_name"
  mkdir -p "$worktree_base"

  # Cache worktree list for efficiency
  local worktree_list
  worktree_list=$(git worktree list)
  local all_worktrees
  all_worktrees=$(echo "$worktree_list" | awk '{print $3}' | sed 's/\[//' | sed 's/\]//' | sed 's/^$/main/')

  if [[ "$delete_mode" == true ]]; then
    local list_of_worktrees
    list_of_worktrees=$(echo "$all_worktrees" | grep -v "^main$")
    selected_worktree="$(printf '%s\n' $list_of_worktrees | sort | uniq | fzf -q "$search_term" --height=10 --reverse)"
    if [[ -z "$selected_worktree" ]]; then
      echo "No worktree selected for deletion"
      return
    fi

    selected_path=$(echo "$worktree_list" | grep -E "\[$selected_worktree\]" | awk '{print $1}')

    # Attempt to delete worktree
    if [[ "$force_mode" == true ]]; then
      if git worktree remove --force "$selected_path"; then
        echo "Force deleted worktree: $selected_worktree"
      else
        echo "Error: Failed to delete worktree: $selected_worktree"
        return 1
      fi
    else
      if git worktree remove "$selected_path"; then
        echo "Deleted worktree: $selected_worktree"
      else
        echo "Error: Failed to delete worktree: $selected_worktree"
        echo "Use 'wt -f -d $selected_worktree' to force delete"
        return 1
      fi
    fi
    return
  fi

  # Regular mode - create/switch to worktree
  if [[ -n "$search_term" ]]; then
    if echo "$all_worktrees" | grep -q "^$search_term$"; then
      selected_worktree="$search_term"
    else
      selected_worktree="$search_term"
    fi
  else
    selected_worktree="$(printf '%s\n' $all_worktrees | sort | uniq | fzf --height=10 --reverse)"
  fi
  if [[ -z "$selected_worktree" ]]; then
    echo "No worktree selected"
    return
  fi

  if [[ "$selected_worktree" == "main" ]]; then
    selected_path=$(echo "$worktree_list" | awk '$3 == "[main]" {print $1}')
  else
    selected_path=$(echo "$worktree_list" | grep -E "\[$selected_worktree\]" | awk '{print $1}')
    if [[ -z "$selected_path" ]]; then
      # Create new worktree
      local worktree_dir="$worktree_base/$selected_worktree"
      if git show-ref --verify --quiet refs/heads/"$selected_worktree"; then
        git worktree add "$worktree_dir" "$selected_worktree"
      else
        git worktree add "$worktree_dir" -b "$selected_worktree"
      fi
      selected_path="$worktree_dir"
    fi
  fi
  cd "$selected_path"
}

function killp {
   local count=$(ps aux | grep "$@" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null | wc -l)
   echo "Killed $count process(es) for '$@'"
}
