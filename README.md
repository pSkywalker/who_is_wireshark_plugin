<!DOCTYPE html>
<html lang="en">

<body>

    <h1>🌍 Wireshark WHOIS Plugin</h1>

    <p>
        A powerful and flexible Lua plugin for Wireshark that brings WHOIS lookups directly to your fingertips. Analyze network traffic and get detailed IP intelligence without leaving the application. This plugin is highly configurable and works seamlessly across Windows, macOS, and Linux.
        <br>
        <br>
        Whether you prefer using a local shell command or a public API, this plugin has you covered.
    </p>

    <hr>

    <h3>✨ Features</h3>
    <ul>
        <li>
            <strong>Integrated Context Menu:</strong> Right-click any packet in your capture to instantly perform a WHOIS lookup on its source and destination IP addresses.
        </li>
        <li>
            <strong>Flexible Lookup Methods:</strong> Choose between running a local shell command (<code>whois</code>, <code>curl</code>) or using a public REST API service for your lookups.
        </li>
        <li>
            <strong>Easy Configuration:</strong> A single JSON file handles all settings, including commands, API endpoints, and output formats.
        </li>
        <li>
            <strong>Automatic Setup:</strong> The plugin automatically detects your operating system and creates a default configuration file for you on the first run.
        </li>
        <li>
            <strong>Multi-format Parsing:</strong> Supports parsing and displaying results in <strong>JSON</strong>, <strong>YAML</strong>, <strong>XML</strong>, and plain <strong>text</strong>.
        </li>
        <li>
            <strong>Fallback APIs:</strong> Configure a backup API to use if your primary service fails, ensuring you always get results.
        </li>
    </ul>

    <hr>

    <h3>🚀 Getting Started</h3>

    <h4>Installation</h4>
    <ol>
        <li>
            <span>⬇️</span> Download the <code>who_is_plugin.lua</code> file from this repository.
        </li>
        <li>
            Place the file in your Wireshark plugins directory. The location depends on your operating system:
            <ul>
                <li><strong>Windows:</strong> <code>%APPDATA%\Wireshark\plugins\who_is_plugin\</code></li>
                <li><strong>macOS / Linux:</strong> <code>~/.config/wireshark/plugins/who_is_plugin\</code></li>
            </ul>
        </li>
        <li>
            <span>🔄</span> Restart Wireshark. The plugin will now be active!
        </li>
    </ol>

    <h4>First Run</h4>
    <p>
        On the first launch, the plugin automatically creates a default configuration file named <code>who_is_config.json</code> in the same directory as the <code>.lua</code> file. This file contains a template to get you started.
    </p>

    <hr>

    <h3>🔧 Usage & Configuration</h3>
    <p>
        Once installed, you'll find the <strong>WHOIS</strong> menu by right-clicking on any packet in your capture.
    </p>

    <h4>The <code>who_is_config.json</code> File</h4>
    <p>
        This is the heart of the plugin's customizability. You can manually edit this file to suit your needs.
    </p>
    <table>
        <thead>
            <tr>
                <th>Field</th>
                <th>Description</th>
                <th>Example Value</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><code>shell_command</code></td>
                <td>The command to run in your terminal. Use <code>{ip}</code> as a placeholder for the IP address.</td>
                <td><code>"whois {ip}"</code></td>
            </tr>
            <tr>
                <td><code>output_format</code></td>
                <td>The format of the output from your command/API. Valid options: <code>"text"</code>, <code>"json"</code>, <code>"yaml"</code>, <code>"xml"</code>.</td>
                <td><code>"json"</code></td>
            </tr>
            <tr>
                <td><code>os</code></td>
                <td>(Optional) Override the auto-detected OS. Useful for cross-platform debugging.</td>
                <td><code>"windows"</code></td>
            </tr>
            <tr>
                <td><code>api_service</code></td>
                <td>The primary REST API endpoint to use. Use <code>{ip}</code> as a placeholder.</td>
                <td><code>"https://ipwhois.app/json/{ip}"</code></td>
            </tr>
            <tr>
                <td><code>fallback_api</code></td>
                <td>A backup API to use if your primary service fails.</td>
                <td><code>"http://ip-api.com/json/{ip}"</code></td>
            </tr>
            <tr>
                <td><code>customCurlForApiKey</code></td>
                <td>(Optional) A full cURL command string if your API requires an authentication token. This will override the other API settings.</td>
                <td><code>"curl -H 'Authorization: Token {YOUR_API_KEY}' https://example.com/api/{ip}"</code></td>
            </tr>
        </tbody>
    </table>

    <h4>Menu Options</h4>
    <p>
        Your WHOIS menu gives you the following options:
    </p>
    <ul>
        <li>
            <span>💻</span> <strong>Shell Lookup:</strong> This option runs the command specified in the <code>shell_command</code> field of your config file.
        </li>
        <li>
            <span>🌐</span> <strong>API Lookup:</strong> This option queries the APIs defined in the <code>api_service</code> and <code>fallback_api</code> fields. It's especially useful if the native <code>whois</code> command is not available or if you need more detailed API-based data.
        </li>
        <li>
            <span>⚙️</span> <strong>Generate Config File:</strong> If you've accidentally deleted your <code>who_is_config.json</code>, this option will recreate the default file for you.
        </li>
        <li>
            <span>📥</span> <strong>Load Config File:</strong> This is the most important option after making changes! <strong>Click this after you edit and save the <code>who_is_config.json</code> file.</strong> This reloads your new settings instantly, so you don't need to restart Wireshark.
        </li>
        <li>
            <span>❓</span> <strong>Help:</strong> Opens a window with a quick summary of the plugin's features and instructions.
        </li>
    </ul>

    <hr>

    <h3>💡 Tips</h3>
    <ul>
        <li>
            <strong>Customizing the Shell Command:</strong> You can replace the default <code>whois</code> command with any terminal command that accepts an IP address as an argument. For example, you could use <code>curl</code> to query a different web service.
        </li>
        <li>
            <strong>Performance:</strong> For most systems, the shell lookup is very fast. The API lookup depends on your internet connection and the responsiveness of the service.
        </li>
    </ul>
</body>
</html>
