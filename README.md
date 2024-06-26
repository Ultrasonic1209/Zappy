# Zappy
Zappy is a Roblox Studio Plugin implementation of [Zap's Playground](https://zap.redblox.dev/playground.html). It works by taking the WASM from the playground and translating it to Luau using [Wasynth](https://github.com/Rerumu/Wasynth).
The UI is made with a lightly modified version of [PluginEssentials](https://github.com/mvyasu/PluginEssentials/) to give it a look that's consistent with Studio's built-in plugins.

## Features
With [valid IDL](https://zap.redblox.dev/intro/getting-started.html#writing-your-first-network-description) input, you will get the client and server code emitted by Zap after clicking Generate. You also have the option of having the code be automatically sent to your game to save you the hassle of copy-pasting. Server code can be exported to `ServerScriptService` and client code can be exported to `ReplicatedStorage`.

![image](https://github.com/Ultrasonic1209/Zappy/assets/44583181/ad7f45b9-0857-4a7c-8146-96c79e1046f5)

The plugin contains the same diagnostics as the playground, so you will still benefit from the same helpful error messages that Zap has to offer.

![image](https://github.com/Ultrasonic1209/Zappy/assets/44583181/9b77c372-3024-4b75-a4f7-ad33f26c93aa)

## Installing

1. Build or download the plugin from [GitHub Releases](https://github.com/Ultrasonic1209/Zappy/releases/latest).
2. Open your plugins folder (WIN+R then enter `%localappdata%\Roblox\Plugins`, or click **Plugins Folder** inside Studio's Plugins ribbon).
3. Copy the plugin you downloaded to your plugins folder.
4. Relaunch Studio.

Zappy should then appear along with all your other plugins.

## Building

1. Install Rojo with [Aftman](https://github.com/LPGhatguy/aftman) (`aftman install`) or [manually](https://rojo.space/docs/v7/getting-started/installation/).
2. Run `rojo build ./build.project.json --output ZappyPlugin.rbxm`.

## Logo
Zappy's logo was sourced from [Twitter](https://github.com/twitter/twemoji/blob/master/assets/svg/26a1.svg) and is under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license. The colour of the logo was changed to a blue hue.
