# Godot 4 Aseprite Importers

[![en](https://img.shields.io/badge/lang-en-red.svg)](README.md)
[![ru](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

This is a plugin for the [Godot](https://godotengine.org/) 4.x game engine that adds several import plugins for the [Aseprite](https://www.aseprite.org/) 1.3+ graphics pixel art editor files.

https://user-images.githubusercontent.com/7024016/236665418-fe8036b9-7de5-4608-a247-b35a7f97891b.mp4

## 💽 Installation

Simply download it from [Godot Asset Library](https://godotengine.org/asset-library/asset/1880).

Alternatively download or clone this repository and copy the contents of the `addons` folder to your own project's `addons` folder.

Then:

- Go to Project Settings
- Switch to the Plugins tab
- Enable the plugin
- Switch to the General tab
- Turn on Advanced Settings toggle
- Scroll down the settings tree and select Aseprite Importers section
- Specify the path to Aseprite executable file

## 👷‍♀️ How to use

After installing the plugin, the project will support `.ase`- and `.aseprite`-files.
1. Place the Aseprite graphics files in the project
2. Select one or more Aseprite graphics files in the project file system tree
3. Select one of the import plugins in the import panel
4. Set import preferences
5. Optionally set a customized settings configuration for the selected import plugin as default
6. Click the `Reimport` button

## 🛠 Import settings

- **`Spritesheet`** - *spritesheet import settings group*
	- **`Embed Image` (not implemented yet)** - *include the resulting image in a resource or place it next to the source file*
	- **`Layout`** - *spritesheet layout type*
		- **`Packed`** *all the sprites trimmed and compactly arranged in the spritesheet*
		- **`By Rows`** (with the **`Fixed Columns Count`** parameter) - *all the sprites have similar size and layed out by rows with fixed length*
		- **`By Columns`** (with the **`Fixed Columns Count`** parameter) - *all the sprites have similar size and layed out by columns with fixed height*
	- **`Border Type`** - *the type of the border around each sprite*
		- **`None`** - *does not create border around sprites*
		- **`Transparent`** - *creates a 1 pixel wide transparent border around each sprite*
		- **`Extruded`** - *creates a 1 pixel wide border, duplicating the colors of adjacent sprite pixels, around each sprite*
	- **`Trim`** - (only for grid-based layouts) - *reduces all sprite cells equally so that the animation fits into the new cell size*
	- **`Ignore Empty`** - *does not include sprites in the spritesheet image, on which all pixels are transparent*
	- **`Merge Duplicates`** - *merges the same sprites into the same areas on the spritesheet image*
- **`Animation`** - *animation settings group*
	- **`Default`** - *settings for the default animation (if there are no tags available in the Aseprite graphics file)*
		- **`Name`** - *the name for the default animation*
		- **`Direction`** - *default animation direction*
			- **`Forward`** - *animation plays from the first to the last frame*
			- **`Reverse`** - *animation plays from the first to the last frame*
			- **`Ping-pong`** - *the animation plays from the first to the last frame, and then back to the first, without duplicating the last frame*
			- **`Ping-pong reverse`** - *the animation plays from the last to the first frame, and then back to the last, without duplicating the first frame*
		- **`Repeat Count`** - *number of repetitions. Edge frames are not duplicated when animation changes direction*
	- **`Autoplay`** - *the name of the animation that will be marked as starting automatically*
	- **`Strategy...` (only for animations based on `AnimationPlayer`)** - *set of node properties that the AnimationPlayer will use to animate*
- **`Layers` (not implemented yet)** - *Aseprite layers settings group*
	- **`Include Reg Ex` (not implemented yet)** - *Regular expression for white list of included layers*
	- **`Exclude Reg Ex` (not implemented yet)** - *Regular expression for blacklist of included layers*
- **`Tags` (not implemented yet)** - *Aseprite tags settings group*
	- **`Include Reg Ex` (not implemented yet)** - *Regular expression for white list of included tags*
	- **`Exclude Reg Ex` (not implemented yet)** - *Regular expression for blacklist of included tags*


## 🧱 Types of Imported Resources

### 🖼️ `Texture`

You can import your `*.aseprite` or `*.ase` files as regular textures from image files. Unfortunately you can not select layers or frames to render. It renders all visible layers from first animation frame.

### 🎞 `SpriteFrames`-based animations

- **`SpriteFrames`** - *creates a `SpriteFrames` resource for further use in animated sprites*
- **`AnimatedSprite2D`** - *creates ready-to-use animated sprite for 2D scenes*
- **`AnimatedSprite3D`** - *creates ready-to-use animated sprite for 3D scenes*

### 📽 `AnimationPlayer`-based animations

Creates a `PackedScene` resources with an `AnimationPlayer` child node that animates it's owner. You can see `AnimationPlayer` node in the parent node if you check the `Editable Children` box in the context menu.

- **`Sprite2D`** - *creates a `PackedScene` resource with `Sprite2D` node and child `AnimationPlayer` node*
- **`Sprite3D`** - *creates a `PackedScene` resource with `Sprite3D` node and child `AnimationPlayer` node*
- **`TextureRect`** - *creates a `PackedScene` resource with `TextureRect` node and child `AnimationPlayer` node*

#### Animation strategies with `AnimationPlayer`:

##### For grid-based spritesheet layout:
- **`Animate sprite's region`** - *animates the `region` property of the sprite*
- **`Animate sprite's frame index`** - *animates the `frame` property of the sprite*
- **`Animate sprite's frame coords`** - *animates the `frame_coords` property of the sprite*
- **`Animate single atlas texture's region`** - *animates the `region` property of the atlas texture of the sprite*
- **`Animate multiple atlas texture instances`** - *instantiates an `AtlasTexture` per unique frame and animates the `texture` property of the sprite*

##### For packed spritesheet layout:
- **`Animate sprite's region and offset`** - *animates the `region` and `offset` properties of the sprite*
- **`Animate single atlas texture's region and margin`** - *animates the `region` and `margin` properties of the `AtlasTexture` in the `texture` property of the sprite*
- **`Animate multiple atlas texture instances`** - *instantiates an `AtlasTexture` per unique frame and animates the `texture` property of the sprite*

## 🤖 In plans for the future:

### Handle import error messages in the console

Some errors may appear in the console during the import process. Most of them are internal bugs in the Godot engine version 4.x, while it has not yet been fixed all the shortcomings.

If there will be error messages related directly to the import script - please create a ticket with their description and reproduction algorithm.

### Add import settings

- Checkbox to embed image in resource **`Spritesheet/Embed Image: bool`**
- Regular expressions for **`Layers/Include`**, **`Layers/Exclude`**, **`Tags/Exclude`** and **`Tags/Exclude`**
- Import regular texture resources (**`TileSetAtlasSource`**, **`ImageTexture`**, **`CompressedTexture`**, **`PortableCompressedTexture`** and **`AtlasTexture`**)
- Regular sprites (`Sprite2D` and `Sprite3D` without animation)
- Import resource type **`TileSetAtlasSource`**
- Import resource type **`NinePatchRect`**
- And something else, if there are interesting proposals from you)))
