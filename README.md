![My Screenshot](BasicUI/Screenshots/BasicUI%20Main%20Screenshot.jpg)


# BasicUI

**BasicUI** is a modular UI overhaul built specifically for
**Project Ascension: Reborn (Wrath 3.3.5 client)**

Designed to complement Ascension’s classless gameplay, BasicUI enhances clarity, reduces clutter, and provides powerful quality-of-life improvements while keeping the Blizzard feel intact.

---

## 🧩 Built for Ascension

BasicUI is designed with **Project Ascension Reborn** in mind:

* Supports dynamic builds and frequent spec changes
* Enhances visibility for proc-based and hybrid gameplay
* Keeps UI responsive during fast-paced combat
* Lightweight and performance-friendly

---

## ✨ Features

### 🎯 Clean Core UI

* Minimal, modernized Blizzard-style interface
* Consistent spacing, fonts, and layout
* Improved readability across all elements

### 🧱 Modular Architecture

* Fully modular system
* Enable or disable features individually
* Easy to expand and maintain

### ⚙️ In-Game Configuration

* Full settings menu powered by Ace3
* No need to edit Lua files
* Toggle modules and features live

**Access settings with:**

```
/basicui
```

### 📊 Datapanel System

* Top-anchored information bar
* Plugin-based design
* Real-time tracking for stats and utilities

### ⚙️ Quality of Life (QoL)

* Automation systems
* UI behavior improvements
* Reduced gameplay friction

---

## 📦 Installation

1. Download or clone:

   ```
   git clone https://github.com/Cokedriver/BasicUI-Asension-Reborn.git
   ```

2. Place in:

   ```
   Ascension Launcher\resources\client\Interface\AddOns
   ```

3. Folder name must be:

   ```
   BasicUI
   ```

4. Enable in-game AddOns menu

---

## 🧱 Project Structure

```id="struct2"
BasicUI/
│
├── Core/
│   ├── Core.lua
│   └── API.lua
│
├── Modules/
│   ├── Fonts.lua
│   ├── ActionBars.lua
│   ├── Buffs.lua
│   ├── Chat.lua
│   ├── Tooltip.lua
│   ├── Unitframes.lua
│   │
│   ├── Datapanel/
│   │   ├── Datapanel.lua
│   │   └── Plugins/
│   │       ├── BagSpace.lua
│   │       ├── Durability.lua
│   │       ├── Friends.lua
│   │       ├── Guild.lua
│   │       ├── Spec.lua
│   │       ├── Professions.lua
│   │       ├── Performance.lua
│   │       └── MainStats.lua
│   │
│   └── QoL/
│       ├── QoL.lua
│       └── SubModules/
│           ├── Automation.lua
│           ├── AutoGreed.lua
│           ├── AltBuy.lua
│           ├── DoubleTradeSkill.lua
│           ├── MapCoords.lua
│           ├── Minimap.lua
│           └── Notifications.lua
│
├── Libs/ (Ace3)
└── BasicUI.toc
```

---

## 🔌 Modules

### 🎮 ActionBars

* Clean layout for ability-heavy builds
* Improved usability and visibility

### 🧙 Unitframes

* Clear health/resource tracking
* Optimized for hybrid gameplay

### 💬 Chat

* Simplified and readable
* Reduced clutter

### 🧰 Tooltip

* Clean and structured information display

### 🧪 Buffs

* Better aura visibility and tracking

### 🎨 Fonts

* Unified font system across UI

---

## 📊 Datapanel Plugins

* **BagSpace** – Inventory tracking
* **Durability** – Gear condition
* **Friends** – Social tracking
* **Guild** – Guild status
* **Spec** – Build awareness
* **Professions** – Skill tracking
* **Performance** – FPS / latency
* **MainStats** – Core stat overview

---

## ⚙️ QoL SubModules

* **Automation** – General automation
* **AutoGreed** – Faster loot rolling
* **AltBuy** – Vendor shortcuts
* **DoubleTradeSkill** – Faster crafting
* **MapCoords** – Coordinate display
* **Minimap** – Map customization
* **Notifications** – Alerts and feedback

---

## 📚 Dependencies

Included libraries:

* AceGUI-3.0
* AceConfig-3.0
* AceEvent-3.0
* AceHook-3.0
* AceSerializer-3.0

No external setup required.

---

## 🧪 Development Status

> ⚠️ Active development (Ascension-focused)

* Features are actively evolving
* QoL and Map systems are still being refined
* Frequent updates expected

---

## 🐛 Known Issues

* Map fog/overlay conflicts in some zones
* Datapanel anchor issues after zoning
* Minor inconsistencies between modules

---

## 🤝 Contributing

Contributions are welcome:

1. Fork the repo
2. Create a branch
3. Submit a pull request

---

## 🎯 Goals

* Keep the UI lightweight and responsive
* Improve clarity for Ascension gameplay
* Maintain Blizzard-style feel
* Stay modular and extensible

---

## 📜 License

MIT License

---

## 🙌 Credits

* Blizzard Entertainment
* Ace3 framework
* Project Ascension Reborn community

---

## 💬 Final Notes

BasicUI is built for the unique nature of Ascension:

* Hybrid builds
* Proc-heavy combat
* Frequent respecs

With full **in-game configuration**, you can tailor the UI to your playstyle without touching code.
