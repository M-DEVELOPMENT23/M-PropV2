# M-PropV2 - Advanced Prop Creator

## Table of Contents

-   [Description](#description-)
-   [Features](#features-️)
-   [Dependencies](#dependencies-)
-   [Installation](#installation-)
-   [Usage](#usage-)
-   [Configuration](#configuration-)
-   [Controls](#controls-)
-   [Optimization](#optimization-)
-   [Credits](#credits-)
-   [License](#license-)

## Description 📜
**M-PropV2** is a powerful and fully standalone script for FiveM that allows for the precise creation, management, and placement of props. The script is built around an advanced gizmo tool, giving you real-time control to move, rotate, and scale objects with ease. All props are saved to the database (`m_props_created`), ensuring persistence across server restarts.

## Features 🛠️
✅ **Advanced Gizmo Tool** for precise, real-time object manipulation (Move, Rotate, Scale).
✅ **Full 3D Rotation** allows you to save props at any angle (pitch, roll, yaw).
✅ **Object Scaling** to dynamically resize any prop directly from the menu.
✅ **Undo System** keeps a history of your last 20 actions (Create, Delete, Update).
✅ **Grid-Based Streaming** props only spawn when players are nearby for maximum optimization.
✅ **ox_target Integration** to edit, duplicate, or delete props using the third-eye.
✅ **Mass Management** tools to delete props by radius or model name.
✅ **ACE Permission System** (`propcreator.admin`) to restrict access.
✅ **Modern UI** built with `ox_lib`.

---

## Dependencies 📦
-   [ox_lib](https://github.com/overextended/ox_lib)
-   [oxmysql](https://github.com/overextended/oxmysql)

---

## Installation 📥

### 1️⃣ **Download and add the script**
Place the folder in your server's `resources/` directory.

### 2️⃣ **Configure `server.cfg`**
Add the permission for your admin group and ensure dependencies start first:

```ini
ensure ox_lib
ensure oxmysql
ensure M-PropV2

# Permission setup
add_ace group.admin propcreator.admin allow
```

### 3️⃣ **Set up the database**
Run the following SQL query. **This is critical** as it matches the schema used in `server.lua`.

```sql
CREATE TABLE IF NOT EXISTS `m_props_created` (
  `propid` INT(11) NOT NULL AUTO_INCREMENT,
  `propname` VARCHAR(255) NOT NULL,
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `rotX` FLOAT NOT NULL DEFAULT 0,
  `rotY` FLOAT NOT NULL DEFAULT 0,
  `rotZ` FLOAT NOT NULL DEFAULT 0,
  `scale` FLOAT NOT NULL DEFAULT 1.0,
  `freeze` TINYINT(1) NOT NULL DEFAULT 1,
  `colision` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`propid`)
);
```

---

## Usage 📌

### 🏗️ **Opening the Menu**
-   Use the command **/propcreator** (configurable in `Config.lua`) to open the main menu.
-   **Options:**
    -   **Editor Mode:** Toggles the visual lines and markers for existing props.
    -   **New Prop:** Spawns a new prop via input name.
    -   **Advanced Tools:** Search nearby props, mass delete by radius/model.
    -   **Undo Last:** Reverts the previous action.

### 🎯 **Using ox_target**
1.  Ensure you are in **Editor Mode** (Toggle it in the main menu).
2.  Hold your Target key (usually LAlt) and look at a prop created by this script.
3.  Options available:
    -   ✏️ **Edit:** Re-open the Gizmo to move/scale/rotate.
    -   📄 **Duplicate:** Clone the prop immediately.
    -   🗑️ **Delete:** Remove the prop permanently.

---

## Configuration 🎛️
Edit `Config.lua` to suit your server needs:

```lua
-- Command to open the menu
Config.OpenMenuCommand = "propcreator"

-- Streaming distances (affect performance)
Config.Streaming = {
    SpawnRadius = 150.0,
    DespawnRadius = 180.0,
    GridSize = 45.0
}
```

---

## Controls 🎮
When using the **Gizmo** (placing or editing):

*Controls may vary depending on the Gizmo resource used, but typically:*

| Key | Action |
| :--- | :--- |
| **W** | Translate (Move) Mode |
| **E** | Rotate Mode |
| **R** | Scale Mode |
| **LAlt** | Toggle Snapping |
| **Mouse** | Drag handles to manipulate |

---

## Optimization 🚀
This script uses a **Grid System** map approach:
-   **Server Side:** Only loads props from DB on start.
-   **Client Side:** Props are grouped into grid cells. Native GTA objects only exist when you are within `SpawnRadius`.
-   **Idle:** 0.00ms usage when not moving near grid borders.

---

## Credits 👏
Special thanks to the community members whose work laid the foundation for the Gizmo system used in this resource:

-   **AvarianKnight**: For the [original discovery and implementation](https://forum.cfx.re/t/allow-drawgizmo-to-be-used-outside-of-fxdk/5091845/8?u=demi-automatic) of `DrawGizmo` outside of FxDK. The gizmo logic in this script is heavily based on his code, adapted and modified for this specific tool.
-   **Andyyy7666**: For contributions and logic related to gizmo integration references found in [ox_lib PR #453](https://github.com/overextended/ox_lib/pull/453).

---

## License 📜

This script is open-source. You are free to modify it for your server.

