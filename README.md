# ☕ Coffee Components — Roblox Plugin
#### (Coffee-Components-Plugin)

**Turn any selected Instances into reusable `Instance.new()` module code.**  
Build Roblox interfaces (and pretty much anything) the *React way* — modular, declarative, and fast.

---

## 💡 What It Does

Coffee Components lets you **convert selected Instances into Luau modules** that recreate them using `Instance.new()`.  
Once generated, you can reuse them just like React components - create, customize, and render UI (or other objects) directly from code.

> Example: Select a GUI button in Roblox Studio → turn it into a component (All of the GUI button's properties, descendants and descendant's properties will be saved, so it can be styled - that's the main point of the plugin) → call it from your scripts to generate buttons dynamically without manually referencing paths or worrying about `Infinite yield` warnings.

--- 

## ⚙️ Setting Up

Get the plugin from the [Creator Hub / Toolbox](https://create.roblox.com/store/asset/78239748407454)
Or download and set it up manually:
1. Download - [CoffeeComponents___V2_1.rbxm](https://github.com/Coffilhg/Coffee-Components-Plugin/blob/main/CoffeeComponents___V2_1.rbxm)
2. Insert it into Studio (Drag the file into Roblox Studio)
3. Right-Mouse-Click the Folder you just inserted
4. Save / Export
5. Save as Local Plugin
6. Done! You’re ready to start converting Instances into components.

---

## 🧩 Technical Notes

The Entry Point is [EveryInstanceProperty.luau](https://github.com/Coffilhg/Coffee-Components-Plugin/blob/main/CoffeeComponents/EveryInstanceProperty.luau); everything else is a ModuleScript .

Some Instance Classes don’t replicate perfectly:
- **Scripts, LocalScripts and ModuleScripts** will only be copied without their Content, because Content property cannot be set during runtime - only Plugins/Roblox/Manual Input has permission to do so.
- **MeshParts and Custom Textures (BasePart.MaterialVariant)** may not transfer correctly due to Roblox replication limitations (Again, some properties might not be set in a usual way during runtime).
- You’re free to modify the plugin to fit your needs, following the [MIT-License](https://github.com/Coffilhg/Coffee-Components-Plugin/blob/main/LICENSE)

---

## 🌍 License

**MIT License © 2025 Coffilhg**
You may use, modify, and distribute this plugin freely.
Please include attribution to "Coffilhg" in your game credits.

Full License: [LICENSE](https://github.com/Coffilhg/Coffee-Components-Plugin/blob/main/LICENSE)