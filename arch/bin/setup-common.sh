#!/usr/bin/env bash
function install_file() {
  local file_name="$1"
  local src_dir="$2"
  local dst_dir="$3"
  local src="$src_dir/$file_name"
  local dst="$dst_dir/$file_name"
  mkdir -p "$dst_dir"
  if [ -e "$dst" ]; then
    if ! diff "$src" "$dst" &>/dev/null; then
      mv "$dst" "$dst".BAK
      ln -s "$src" "$dst_dir"/
    fi
  elif [ -L "$dst" ]; then
    mv "$dst" "$dst".BAK
    ln -s "$src" "$dst_dir"/
  else
    ln -s "$src" "$dst_dir"/
  fi
}
function replace_file() {
  local file_name="$1"
  local src_dir="$2"
  local dst_dir="$3"
  local src="$src_dir/$file_name"
  local dst="$dst_dir/$file_name"
  if [ -e "$dst" ]; then
    if ! diff "$src" "$dst" &>/dev/null; then
      mv "$dst" "$dst".BAK
      cp "$src" "$dst_dir"/
    fi
  elif [ -L "$dst" ]; then
    mv "$dst" "$dst".BAK
    cp "$src" "$dst_dir"/
  else
    cp "$src" "$dst_dir"/
  fi
}
