# Zappy
Zappy is a Roblox Studio Plugin implementation of [Zap's Playground](https://zap.redblox.dev/playground.html). It works by taking the WASM from the playground and translating it to Luau using [Wasynth](https://github.com/Rerumu/Wasynth).
The UI is made with a lightly modified version of [PluginEssentials](https://github.com/mvyasu/PluginEssentials/) to give it a look that's consistent with Studio's built-in plugins.

## Features
With [valid IDL](https://zap.redblox.dev/intro/getting-started.html#writing-your-first-network-description) input, you will get the client and server code emitted by Zap after clicking Generate. 
### Auto-export
To save you the hassle of manually copy-pasting your generated code, Zappy can automatically export your client, server, and tooling code to specific locations within your game:

By default, Zappy saves client and (and tooling, [if you have it enabled](https://zap.redblox.dev/config/options.html#tooling)) code to `ReplicatedStorage` and server code to `ServerScriptService`, but if you'd prefer Zappy export someplace else, those default output locations are easily configurable within the plugin!

![image](https://github.com/user-attachments/assets/b961635c-c3c1-474c-bae5-4267df584b37)

To change your client/server/tooling output path, select an Instance in the Studio Explorer and click the relevant "Change `<ScriptName>`.Parent" button to change the output location to that Instance.

For example, if you want to save Zap's exported client code to a ModuleScript named `BoatsZapClient` as a child of the ModuleScript at `game.ReplicatedStorage.Client.Boats`, you can:
- make sure "Reparent previously exported ModuleScripts when output path changes" is disabled so Zappy doesn't move unrelated Zap client code into `Boats`,
- change the Client Output textbox text to "BoatsZapClient",
- select the `Boats` ModuleScript in the Studio Explorer,
- and click the purple "Change Parent" button to set the new client output path: 

![image](https://github.com/user-attachments/assets/fe72b522-d882-4279-a693-a8d29e4cf4b6)

- Zappy should now show your Client Export Location as `ReplicatedStorage.Client.Boats["BoatsZapClient"]`:
  
![image](https://github.com/user-attachments/assets/55e33cd6-1af9-4c6d-8be2-e3ddc9f663ee)

- The next time you click Generate, Zappy will save your client output to `game.ReplicatedStorage.Client.Boats.BoatsZapClient`.

### Diagnostics

The plugin contains the same diagnostics as the playground, so you will still benefit from the same helpful error messages that Zap has to offer.

![image](https://github.com/user-attachments/assets/129d4350-e556-4986-8859-e829e6ca874d)

## Installing

1. Build or download the plugin from [GitHub Releases](https://github.com/Ultrasonic1209/Zappy/releases/latest).
2. Open your plugins folder (WIN+R then enter `%localappdata%\Roblox\Plugins`, or click **Plugins Folder** inside Studio's Plugins ribbon).
3. Copy the plugin you downloaded to your plugins folder.
4. Relaunch Studio.

Zappy should then appear along with all your other plugins.

## Building

1. Install Rojo with [Aftman](https://github.com/LPGhatguy/aftman) (`aftman install`), [Rokit](https://github.com/rojo-rbx/rokit) (`rokit install`) or [manually](https://rojo.space/docs/v7/getting-started/installation/).
2. Run `rojo build ./build.project.json --output ZappyPlugin.rbxm`.

## Logo
Zappy's logo was sourced from [Twitter](https://github.com/twitter/twemoji/blob/master/assets/svg/26a1.svg) and is under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license. The colour of the logo was changed to a blue hue.
