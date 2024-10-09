#!/usr/bin/env lua

-- Parse command-line arguments
local force_mode = false
for i, arg in ipairs(arg) do
  if arg == "-f" then
    force_mode = true
  end
end

local lfs = require "lfs" -- LuaFileSystem for directory traversal

-- ANSI color codes
local colors = {
  reset = "\27[0m",
  bold = "\27[1m",
  green = "\27[32m",
  yellow = "\27[33m",
  red = "\27[31m",
  blue = "\27[34m",
  magenta = "\27[35m",
}

local installed_brew_packages = {}

-- Execute an os command and return exit code
local function execute(cmd)
  local handle = io.popen(cmd .. " 2>&1; echo $?")
  local result = handle:read "*a"
  handle:close()
  local lines = {}
  for line in result:gmatch "[^\r\n]+" do
    table.insert(lines, line)
  end
  local exit_code = tonumber(lines[#lines])
  table.remove(lines)
  return exit_code, table.concat(lines, "\n")
end

-- Expands '~' to the user's home directory in the given path
local function expand_path(path)
  if path:sub(1, 1) == "~" then
    return os.getenv "HOME" .. path:sub(2)
  else
    return path
  end
end

-- Checks if the symlink at 'output' points to 'source'
local function is_symlink_correct(source, output)
  local attr = lfs.symlinkattributes(output)
  if attr and attr.mode == "link" then
    local target = lfs.symlinkattributes(output, "target")
    return lfs.attributes(target)
      and lfs.attributes(source)
      and lfs.attributes(target).ino == lfs.attributes(source).ino
  end
  return false
end

-- Gets all installed brew packages
local function get_installed_brew_packages()
  local exit_code, formula = execute "brew list --formula"
  if exit_code == 0 then
    for package in formula:gmatch "[^\r\n]+" do
      installed_brew_packages[package] = true
    end
  else
    print(colors.red .. "Warning: Failed to get list of installed brew packages" .. colors.reset)
  end
  local exit_code, cask = execute "brew list --cask"
  if exit_code == 0 then
    for package in cask:gmatch "[^\r\n]+" do
      installed_brew_packages[package] = true
    end
  else
    print(colors.red .. "Warning: Failed to get list of installed brew casks" .. colors.reset)
  end
end

-- Checks if a Homebrew package is already installed
local function is_brew_package_installed(package_name)
  -- package_name might be neovim or /foo/bar/neovim so we need to only include the last part
  local package_name = package_name:gsub("^.*/", "")
  return installed_brew_packages[package_name] == true
end

-- Creates the parent directory of a given path if it doesn't exist
local function ensure_parent_directory(path)
  local parent = path:match "(.+)/[^/]*$"
  if parent then
    local success, err = lfs.mkdir(parent)
    if not success and not lfs.attributes(parent) then
      return false, "Failed to create parent directory: " .. (err or "unknown error")
    end
  end
  return true
end

-- Creates a backup of an existing file or directory
local function create_backup(path)
  local backup_path = path .. ".before-nos"
  local i = 1
  while lfs.attributes(backup_path) do
    backup_path = path .. ".before-nos." .. i
    i = i + 1
  end
  local cmd = string.format('mv "%s" "%s"', path, backup_path)
  local exit_code, error_output = execute(cmd)
  if exit_code ~= 0 then
    return false, "Failed to create backup: " .. error_output
  end
  return true, backup_path
end

-- Processes each module by installing dependencies and creating symlinks
local function process_module(module_name)
  local module_dir = "modules/" .. module_name
  local init_file = module_dir .. "/init.lua"

  print(colors.bold .. colors.blue .. "• " .. module_name .. colors.reset)

  -- Load the init.lua file
  local config_func, load_err = loadfile(init_file)
  if not config_func then
    print("  " .. colors.red .. "✗ Error loading configuration: " .. load_err .. colors.reset)
    return
  end

  local success, config = pcall(config_func)
  if not success or not config then
    print("  " .. colors.red .. "✗ Error executing configuration: " .. tostring(config) .. colors.reset)
    return
  end

  local dependencies_installed = false

  -- Process brew dependencies
  if config.brew then
    local all_deps_installed = true
    for _, brew_entry in ipairs(config.brew) do
      local package_name, install_options
      if type(brew_entry) == "string" then
        package_name = brew_entry
        install_options = ""
      else
        package_name = brew_entry.name
        install_options = brew_entry.options or ""
      end

      if not is_brew_package_installed(package_name) then
        all_deps_installed = false
        dependencies_installed = true
        local cmd = "brew install " .. package_name .. " " .. install_options
        local exit_code, output = execute(cmd)
        if exit_code ~= 0 then
          print(
            "  "
              .. colors.red
              .. "✗ dependencies → could not install `"
              .. package_name
              .. "`: "
              .. output
              .. colors.reset
          )
        else
          print("  " .. colors.green .. "✓ dependencies → installed `" .. package_name .. "`" .. colors.reset)
          installed_brew_packages[package_name] = true -- Add newly installed package to the list
        end
      else
        print("  " .. colors.green .. "✓ dependencies → `" .. package_name .. "` already installed" .. colors.reset)
      end
    end
    if all_deps_installed then
      print("  " .. colors.green .. "✓ all dependencies installed" .. colors.reset)
    end
  end

  -- Check symlink configuration
  if config.config then
    local source = lfs.currentdir() .. "/" .. module_dir:gsub("^./", "") .. "/" .. config.config.source:gsub("^./", "")
    local output = expand_path(config.config.output)
    if is_symlink_correct(source, output) then
      print("  " .. colors.green .. "✓ config → symlink correct" .. colors.reset)
    else
      local attr = lfs.attributes(output)
      if attr then
        if force_mode then
          local success, result = create_backup(output)
          if success then
            print("  " .. colors.yellow .. "! config → existing config backed up to " .. result .. colors.reset)
          else
            print("  " .. colors.red .. "✗ config → " .. result .. colors.reset)
            return
          end
        else
          print(
            "  "
              .. colors.red
              .. "✗ config → file already exists at "
              .. output
              .. ". Use -f to force."
              .. colors.reset
          )
          return
        end
      end

      -- Ensure parent directory exists
      local success, err = ensure_parent_directory(output)
      if not success then
        print("  " .. colors.red .. "✗ config → " .. err .. colors.reset)
        return
      end

      local cmd = string.format('ln -s%s "%s" "%s"', force_mode and "f" or "", source, output)
      local exit_code, error_output = execute(cmd)
      if exit_code ~= 0 then
        print("  " .. colors.red .. "✗ config → failed to create symlink: " .. error_output .. colors.reset)
      else
        print("  " .. colors.green .. "✓ config → symlink created" .. colors.reset)
      end
    end
  end

  -- Run post_install hook if dependencies were installed
  if dependencies_installed and config.post_install then
    print("  " .. colors.yellow .. "• Running post-install hook" .. colors.reset)
    local exit_code, output = execute(config.post_install)
    if exit_code ~= 0 then
      print("  " .. colors.red .. "✗ post-install → failed: " .. output .. colors.reset)
    else
      print("  " .. colors.green .. "✓ post-install → completed successfully" .. colors.reset)
    end
  end

  print "" -- Add a blank line between modules
end

-- Recursively search for init.lua files
local function find_init_files(dir, processed_dirs)
  processed_dirs = processed_dirs or {}
  local init_files = {}
  local current_dir_processed = false

  for entry in lfs.dir(dir) do
    if entry ~= "." and entry ~= ".." then
      local full_path = dir .. "/" .. entry
      local attr = lfs.attributes(full_path)
      if attr.mode == "directory" then
        -- Check if this directory or any parent has been processed
        local should_process = true
        for processed_dir in pairs(processed_dirs) do
          if full_path:find(processed_dir, 1, true) == 1 then
            should_process = false
            break
          end
        end

        if should_process then
          for _, subfile in ipairs(find_init_files(full_path, processed_dirs)) do
            table.insert(init_files, subfile)
          end
        end
      elseif entry == "init.lua" and not current_dir_processed then
        table.insert(init_files, dir)
        processed_dirs[dir] = true
        current_dir_processed = true
        break -- Stop processing this directory
      end
    end
  end
  return init_files
end

-- Main function to iterate over modules and process them
local function main()
  get_installed_brew_packages()

  local modules_dir = "modules"
  if not lfs.attributes(modules_dir) then
    print("  " .. colors.red .. "✗ modules directory not found" .. colors.reset)
    return
  end

  local init_files = find_init_files(modules_dir)
  if #init_files == 0 then
    print("  " .. colors.red .. "✗ no modules found" .. colors.reset)
    return
  end

  for _, module_dir in ipairs(init_files) do
    local module_name = module_dir:gsub("^" .. modules_dir .. "/", "")
    process_module(module_name)
  end
end

main()
