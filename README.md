# REPL GD

[![Chat on Discord](https://img.shields.io/discord/853476898071117865?label=chat&logo=discord)](https://discord.gg/6mcdWWBkrr)

A REPL (Read-Evaluate-Print-Loop) for Godot 3.x.

## Installation: Editor
1. Grab the `addons/repl_gd` and `addons/advanced-expression` folders and place them in your project's `addons` folder. Create the folder if it does not exist
2. Activate the `REPL GD` plugin in the editor

## Installation: Game
1. Grab the `addons/repl_gd/repl.gd` file and place it in _your_ debug UI (no debug UI is provided at this time by this project)
2. In the `repl.gd` file, modify the `Env._init` and the general `_init` function to accept a `SceneTree` argument
3. Pass in your game's `SceneTree` to the file somehow idk

## Builtin commands

### `exit`
Calls `get_tree().quit()`. Disabled when running in the editor.

### `reset`
Resets the REPL's state. All saved variables, functions, and `SceneTree` nodes are freed.

### `clear`
Clears the REPL's output.
