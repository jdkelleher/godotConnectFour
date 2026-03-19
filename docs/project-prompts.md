# Project Prompt Log

Date started: 2026-03-19
Policy: Append-only, chronological order.
Scope: Prompts used to define and implement this Godot Connect Four project.

## 1) User Prompt

Create a complete graphical Connect Four game in Godot 4 using GDScript.

Core concept:
- Build a polished 2D Connect Four game with a clear, colorful graphical interface.
- Support exactly 2 player slots.
- Before the game starts, show a setup screen where the user can choose, for each of the 2 player slots, whether that player is Human or Computer.
- This should allow the following match types:
  - Human vs Human
  - Human vs Computer
  - Computer vs Computer
- Each player should have a distinct disc color and clear on-screen labeling.

Gameplay requirements:
- Use standard Connect Four rules with a 7-column by 6-row board.
- Players take turns dropping discs into columns.
- Discs should fall to the lowest available row in a selected column with a simple drop animation.
- Prevent invalid moves, including selecting a full column or making moves after the game is over.
- Detect wins for horizontal, vertical, and diagonal four-in-a-row combinations.
- Detect a draw when the board is full and no player has won.
- Show the active player's turn clearly during gameplay.
- After a win or draw, show the result and provide buttons to restart or return to the setup/menu screen.

Computer player requirements:
- Either player slot can be assigned as a Computer player.
- Computer players must make only valid moves.
- Implement AI that plays reasonably well.
- A minimax-based AI with adjustable difficulty is preferred.
- If practical, expose AI difficulty settings or thinking delay as exported variables.
- Structure the AI so either player can be human or computer without changing the core game logic.

UI requirements:
- Include a main menu or setup screen for match configuration.
- The setup screen should allow selecting Human or Computer for Player 1 and Player 2.
- Use simple but attractive visuals:
  - board background
  - distinct disc colors for the 2 players
  - hover or selection feedback on columns
  - basic animations for disc drops and end-game feedback
- The interface should be easy to understand and work well on common desktop window sizes.

Architecture requirements:
- Use Godot 4 scene structure and clean GDScript organization.
- Separate game logic from presentation as much as practical.
- Create reusable scripts for:
  - board and game-state logic
  - turn management
  - player configuration
  - AI move selection
  - UI/menu flow
- Keep the code organized and maintainable.
- Add comments only where needed for non-obvious logic.

Deliverables:
- Provide the recommended scene hierarchy and script structure.
- Generate all GDScript code needed for the game.
- Explain how to set up the scenes and nodes in Godot.
- Include any exported variables needed to tune visuals and AI behavior.
- Ensure the project is runnable as-is in Godot 4.

## 2) Assistant Clarification Prompt

Should the plan assume code-drawn/vector-style visuals in Godot, or imported custom art assets?

Selected answer:
- Code-drawn/vector UI and board.

## 3) Assistant Clarification Prompt

How should AI difficulty be exposed?

Selected answer:
- Setup-screen difficulty selector.

## 4) Assistant Subagent Prompt (Explore)

Quick exploration of the current workspace for a Godot project. Determine whether this repository already contains a Godot 4 project, any existing scenes/scripts/assets, project.godot, or conventions to reuse. Report: 1) top-level files/folders, 2) whether the repo is empty or scaffolded, 3) any blockers for implementing a complete 2D Connect Four game, 4) any Godot-specific setup already present. Do not modify files.

## 5) Assistant Subagent Prompt (Explore)

Medium-thorough exploration of the workspace for any existing gameplay, menu, scene flow, board logic, or AI patterns that could be reused for a Connect Four implementation. Look for GDScript files, scenes, resources, and project settings. Report concise findings with file paths if any exist. Do not modify files.

## 6) User Prompt

Allow difficulty selecion when choosing computer based on a hybrid heuristic minmax

## 7) User Prompt

store all prompts used for this project in a file in the repository

## 8) User Prompt

Start implementation

## 9) User Prompt

continue

## 10) Assistant Clarification Prompt

Git status shows an untracked `.vscode/settings.json`. How should it be handled: (1) commit it, (2) delete it, or (3) keep locally but add `.vscode/` to `.gitignore`?

Selected answer:
- 3 — keep locally and add `.vscode/` to `.gitignore`.

## 11) User Prompt

continue

## 12) User Prompt

update to godot 4.6

## 13) User Prompt

add a README.md file to the repository with includes a short intro explaining that this was a fun expiriment to use CoPilot to make a playable game using Godot. Include a How to Play section with instructions to download Godot, import the Connect Four project, and play the game

## 14) User Prompt

Enhance the README.md with Godot download link, add a link to project-prompts.md explaining it contains all prompts used to make this project, and update project-prompts.md so it contains all prompts used so far. Then stage and commit all changes. Finally push to github.com.
