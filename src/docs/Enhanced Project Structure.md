# **Modular Core Structure**

By grouping your logic into sub-directories within core/, you create a "feature-based" architecture. This is standard practice for professional projects.

## **Recommended Folder Layout**

res://src/  
├── core/  
│   ├── grid/               \# Grid system, pathfinding, nodes  
│   ├── logistics/          \# Resource movement, belts, logic  
│   ├── power/              \# Energy generation, distribution, grid  
│   ├── storage/            \# Inventories, chests, containers  
│   ├── crafting/           \# Recipes, manufacturing logic  
│   └── game\_manager.gd     \# The main orchestrator/singleton  
├── tests/  
│   ├── grid/  
│   ├── logistics/  
│   └── ...  
└── docs/

## **Why this is superior:**

1. **Lower Cognitive Load**: When you need to fix a bug in the power system, you only look at the power/ folder. You aren't distracted by 30 other files from unrelated systems.  
2. **Namespace Clarity**: You can name your files more simply (e.g., controller.gd inside power/ and controller.gd inside grid/ won't collide).  
3. **Easier Testing**: You can map your tests/ folder directly to your core/ folder structure. This makes it incredibly easy to find the test file corresponding to any core script.  
4. **Team Scaling**: If you ever bring someone else onto the project, they will immediately understand where to look for specific systems based on the intuitive folder names.

## **A "Rule of Thumb" for Separation:**

If you find yourself having more than **5–7 scripts** in a single folder, that is usually a sign that it's time to break that folder into logical sub-components.

* **Tip:** If you have common data structures (like a Resource that handles recipes) used by multiple systems, consider adding a core/common/ or core/data/ folder to hold those shared classes\!