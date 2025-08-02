local detected_os = package.config:sub(1,1) == "\\" and "windows" or (os.getenv("HOME") and os.getenv("HOME"):find("/Users/") and "mac" or "linux")
local function get_config_dir()
    if package.config:sub(1,1) == "\\" then  -- Windows
        return os.getenv("APPDATA") .. "\\Wireshark\\plugins\\who_is_plugin"
    elseif os.getenv("HOME") and os.getenv("HOME"):find("/Users/") then  -- macOS
        return os.getenv("HOME") .. "/.config/wireshark/plugins/who_is_plugin"
    else  -- Linux/Unix
        return os.getenv("HOME") .. "/.config/wireshark/plugins/who_is_plugin"
    end
end
local function ensure_dir_exists(path)
    if package.config:sub(1,1) == "\\" then  -- Windows
        os.execute('mkdir "' .. path .. '" 2>nul')
    else
        os.execute('mkdir -p "' .. path .. '" 2>/dev/null')
    end
end
local config_dir = get_config_dir()
ensure_dir_exists(config_dir)

local json_config_path = config_dir .. "/who_is_config.json"
-- Default config
local default_config = {
    shell_command = "whois {ip}",
    output_format = 'json',
    os = detected_os,
    api_service = 'https://ipwhois.app/json/{ip}',
    fallback_api = 'http://ip-api.com/json/{ip}',
    customCurlForApiKey = nil
}
local updatable_config = {
    shell_command = '__REPLACE_ME__ Example: "whois {ip}" or "curl -s https://ipinfo.io/{ip}"',
    output_format = '__REPLACE_ME__ Options: "text", "json", "yaml", "xml"',
    os = '__REPLACE_ME__ Optional override: "windows", "linux", "mac"',
    api_service = '__REPLACE_ME__ Example: "https://ipwhois.app/json/{ip}"',
    fallback_api = '__REPLACE_ME__ Example: "http://ip-api.com/json/{ip}"',
    customCurlForApiKey = '__REPLACE_ME__ Optional, if API requires a key Example : curl -H "Authorization: Token {YOUR_API_KEY}" https://example.com/api'
}

-- Write JSON config to file
local function write_config_to_file()
    local existing_file = io.open(json_config_path, "r")
    if existing_file then
        existing_file:close()
        return -- If file exists, we don't overwrite it
    end
    local json_text = string.format([[
        {
          "shell_command": "%s",
          "output_format": "%s",
          "os": "%s",
          "api_service": "%s",
          "fallback_api": "%s",
          "customCurlForApiKey": "%s"
        }
]], default_config.shell_command, default_config.output_format, default_config.os, default_config.api_service, default_config.fallback_api, default_config.customCurlForApiKey or "")

    local file, err = io.open(json_config_path, "w")
    if not file then
        print("Failed to write config:", err)
        return false, err
    end
    file:write(json_text)
    file:write([[
        //
        // Example WHOIS config template:
        //
        // shell_command: __REPLACE_ME__ Example: "whois {ip}" or "curl -s https://ipinfo.io/{ip}"
        // output_format: __REPLACE_ME__ Options: "text", "json", "yaml", "xml"
        // os: __REPLACE_ME__ Optional override: "windows", "linux", mac"
        // api_service: __REPLACE_ME__ Example: "https://ipwhois.app/json/{ip}"
        // fallback_api: __REPLACE_ME__ Example: "http://ip-api.com/json/{ip}"
        // customCurlForApiKey: __REPLACE_ME__ Optional: e.g. curl -H "Authorization: Token {YOUR_API_KEY}" https://example.com/api
        //
]]
    );
    file:close()
    return true
end
local function load_config_from_file_initial ()
    local file = io.open(json_config_path, "r")
    if not file then
        print("No config file found, using defaults.")
        return false
    end
    local content = file:read("*a")
    file:close()

    local function extract(k)
        return content:match('"' .. k .. '"%s*:%s*"(.-)"')
    end

    for _, k in ipairs({"shell_command", "output_format", "os", "api_service", "fallback_api", "customCurlForApiKey"}) do
        local v = extract(k)
        if v and not v:match("__REPLACE_ME__") then
            updatable_config[k] = v
        else 
            updatable_config[k] = default_config[k] -- Use default if not set or still a placeholder
        end
    end

    --local win = TextWindow.new("WHOIS Config Loaded")
    --win:append("✅ Config loaded from: " .. json_config_path .. "\n\n")
    --for k, v in pairs(config) do
    --     win:append(string.format("%-15s: %s\n", k, v))
    --end    
end

-- Load config from JSON file (if it exists)
local function load_config_from_file()
    local file = io.open(json_config_path, "r")
    if not file then
        print("No config file found, using defaults.")
        return false
    end
    local content = file:read("*a")
    file:close()

    local function extract(k)
        return content:match('"' .. k .. '"%s*:%s*"(.-)"')
    end

    for _, k in ipairs({"shell_command", "output_format", "os", "api_service", "fallback_api", "customCurlForApiKey"}) do
        local v = extract(k)
        if v and not v:match("__REPLACE_ME__") then
            updatable_config[k] = v
        else 
            updatable_config[k] = default_config[k] -- Use default if not set or still a placeholder
        end
    end

    local win = TextWindow.new("WHOIS Config Loaded")
    win:append("✅ Config loaded from: " .. json_config_path .. "\n\n")
    --for k, v in pairs(config) do
    --     win:append(string.format("%-15s: %s\n", k, v))
    --end
end

-- Format WHOIS table output
local function parse_json(text) local r={} for k,v in text:gmatch('"([%w_]+)"%s*:%s*"(.-)"') do r[k]=v end return r end
local function parse_yaml(text) local r={} for k,v in text:gmatch("([%w_]+):%s*(.-)\n") do r[k]=v end return r end
local function parse_xml(text) local r={} for k,v in text:gmatch("<(%w+)>([^<]+)</%1>") do r[k]=v end return r end
local function parse_whois_text(text)
    local r = {}
    -- The pattern matches a key (words, underscores, hyphens, and spaces)
    -- followed by a colon and the rest of the line as the value.
    for k, v in text:gmatch("([%w_\\- ]+):%s*(.+)") do
        -- Trim any extra whitespace from the key and value before storing.
        r[k:gsub("^%s+|%s+$", "")] = v:gsub("^%s+|%s+$", "")
    end
    return r
end

local function get_parsed_whois_info(raw_result, output_format)
    local parsed_data = {}
    
    if output_format == "json" then
        parsed_data = parse_json(raw_result)
    elseif output_format == "yaml" then
        parsed_data = parse_yaml(raw_result)
    elseif output_format == "xml" then
        parsed_data = parse_xml(raw_result)
    elseif output_format == "text" then
        parsed = parse_whois_text(raw) -- This is the new line
    else
        -- Fallback to an empty table if format is unknown
        return {}
    end

    return parsed_data
end


local function format_table(tbl, ip)
    local lines = {"WHOIS results for IP: " .. ip}
    for k,v in pairs(tbl) do
        if k ~= "raw" then
            table.insert(lines, string.format("%-16s %s", k .. ":", v))
        end
    end
    return table.concat(lines, "\n")
end

    -- This version uses Lua's standard 'io.popen' to run the command and
    -- capture its output, replacing a separate 'run_shell' function.
local function fetch_data(cmd)
    local file = io.popen(cmd, "r")
     if file then
         local content = file:read("*all") or ""
         file:close()
         return content
     end
     return "" -- Return an empty string on command failure
end

-- WHOIS via shell
local function whois_shell(ip)
    local cmd = updatable_config.shell_command:gsub("{ip}", ip)
    local result = fetch_data(cmd)

    local parsed = {}
    if updatable_config.output_format == "json" then parsed = parse_json(result)
    elseif updatable_config.output_format == "xml" then parsed = parse_xml(result)
    elseif updatable_config.output_format == "yaml" then parsed = parse_yaml(result)
    elseif output_format == "text" then parsed = parse_whois_text(result)
    else return result end

    return format_table(parsed, ip)
end



-- Refactored WHOIS via API function    

local function whois_api(ip)

    local result_string = ""
    local result = ""

    -- Check if a custom cURL command is provided.
    -- If so, this command is used as a complete override.
    if updatable_config.customCurlForApiKey and updatable_config.customCurlForApiKey ~= "" then
        result_string = "Using custom cURL command.\n"
        -- Execute the custom cURL command, replacing the {ip} placeholder.
        local custom_command = updatable_config.customCurlForApiKey:gsub("{ip}", ip)
        result = fetch_data(custom_command)
    else
        result_string = "Using default API service.\n"
        -- If no custom command is set, use the primary API service.
        local primary_service = updatable_config.api_service:gsub("{ip}", ip)
        local initial_result = fetch_data('curl -s "' .. primary_service .. '"')
        
        -- Check if the primary service request failed (empty result or "success": false)
        if initial_result == "" or initial_result:match('"success"%s*:%s*false') then
            result_string = result_string .. "Primary API failed, using fallback service.\n"
            -- If it failed, use the fallback API service.
            local fallback_service = updatable_config.fallback_api:gsub("{ip}", ip)
            result = fetch_data('curl -s "' .. fallback_service .. '"')
        else
            result = initial_result
        end
    end

    -- If no data was fetched after all attempts, return an error message
    if result == "" then
        return updatable_config["api_service"] .. " " .. result_string .. "Failed to retrieve WHOIS data."
    end

    local parsed_data = get_parsed_whois_info(result, updatable_config["output_format"])
    
    
    -- Parse the final result as JSON and format it into a table for display.
    -- Append the formatted table string to our result string.
    result_string = result_string .. format_table(parsed_data, ip)

    return result_string
end

local function run_command_safely(cmd, callback)
    if _G.async_run_command then
        -- Use the non-blocking Wireshark function
        _G.async_run_command(cmd, callback)
    else
        -- Fallback to a synchronous, blocking method.
        -- WARNING: This will freeze the Wireshark UI.
        print("Warning: async_run_command is not available. Using a blocking command execution method.")
        local file = io.popen(cmd, "r")
        local output = ""
        if file then
            output = file:read("*all") or ""
            file:close()
        end
        -- Call the callback immediately with the output.
        callback(output)
    end
end

-- Packet listener
local latest_ip = {src = nil, dst = nil}
local listener = Listener.new("ip")
function listener.packet(pinfo) latest_ip.src = tostring(pinfo.src) latest_ip.dst = tostring(pinfo.dst) end

-- Show WHOIS results   

local function show_whois(method)
    local win = TextWindow.new("WHOIS Lookup", true)
    if not latest_ip.src then win:append("No IPs captured yet.") return end
    win:append("📤 Source IP:\n" .. method(latest_ip.src) .. "\n\n")
    win:append("📥 Destination IP:\n" .. method(latest_ip.dst) .. "\n")
end


-- Create config file + instructions
local function generate_config_file()
    write_config_to_file()
    local win = TextWindow.new("WHOIS Config Created")
    win:append("✅ WHOIS config created at:\n" .. json_config_path .. "\n\n")
    win:append("You can edit this JSON to customize:\n\n")
    win:append("- shell_command: Shell command to run with '{ip}' placeholder\n")
    win:append("- output_format: 'text', 'json', 'xml', or 'yaml'\n")
    win:append("- os: Force override OS detection ('windows', 'linux', 'mac')\n")
    win:append("- api_service: Custom REST endpoint with '{ip}' placeholder\n")
    win:append("- fallback_api: Optional fallback REST service\n")
    win:append("- customCurlForApiKey: If your API requires authentication\n\n")
    win:append("Reload using WHOIS → Load Config File.")
end

-- Help view
local function show_whois_help()
    local win = TextWindow.new("WHOIS Plugin Help")
    win:append("🔧 WHOIS Plugin for Wireshark\n\n")
    win:append("This plugin allows you to perform WHOIS lookups using either:\n")
    win:append("• A shell command (default: whois)\n")
    win:append("• A public API service (default: ipwhois.app)\n\n")
    win:append("📂 Configurable via JSON file: " .. json_config_path .. "\n\n")
    win:append("Fields:\n")
    win:append("- shell_command: Shell WHOIS command with {ip} placeholder\n")
    win:append("- output_format: text | json | yaml | xml\n")
    win:append("- os: (optional) override OS detection\n")
    win:append("- api_service: REST API endpoint with {ip}\n")
    win:append("- fallback_api: Backup API if main one fails\n")
    win:append("- customCurlForApiKey: Optional API key (if required)\n\n")
    win:append("You can:\n")
    win:append("• Generate a config: WHOIS → Generate Config File\n")
    win:append("• Load saved config: WHOIS → Load Config File\n")
    win:append("• View help: WHOIS → Help\n\n")
    win:append("👈 Right-click a packet → WHOIS → Shell/API Lookup\n")
end

write_config_to_file();
load_config_from_file_initial();

-- Register menu options
register_packet_menu("WHOIS → Shell Lookup", function() show_whois(whois_shell) end, MENU_PACKET)
register_packet_menu("WHOIS → API Lookup", function() show_whois(whois_api) end, MENU_PACKET)
register_packet_menu("WHOIS → Generate Config File", function() generate_config_file() end, MENU_PACKET)
register_packet_menu("WHOIS → Load Config File", load_config_from_file, MENU_PACKET)
register_packet_menu("WHOIS → Help", show_whois_help, MENU_PACKET)
