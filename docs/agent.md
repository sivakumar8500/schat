---

## 🧱 14. Code Generation (Mason Mandatory)

### Objective
All files in the project MUST be generated using Mason bricks.  
Manual file creation is strictly prohibited.

---

### 📦 Tools
- Mason CLI
- Mason Bricks (custom templates)

---

### 🔒 Rules

- ❌ Do NOT create files manually
- ❌ Do NOT write raw files directly
- ✅ ALWAYS use Mason commands to generate code

---

### 📁 Required Bricks

Project must define the following Mason bricks:

1. feature
2. bloc
3. usecase
4. repository
5. model (Freezed)
6. page
7. widget
8. test (unit/widget/integration)

---

### 🛠️ Example Commands

```bash
mason make feature --name auth
mason make bloc --name auth
mason make model --name user
mason make usecase --name login
```

---

### 🧠 AI Instructions

AI MUST:
- Use Mason structure when generating code
- Provide Mason command before code output
- Follow brick templates strictly
- Assume all templates already exist

---

### 📂 Brick Output Rules

Each brick must:
- Follow Clean Architecture
- Place files in correct folders
- Generate boilerplate + test files
- Include Freezed for models
- Include BLoC for state management

---

### 🔁 Regeneration Rule

- Any modification to existing code must:
  1. Update Mason brick
  2. Re-generate files

---

### 🧪 Validation

Project must include validation to ensure:
- No manually created files
- All files follow brick structure

---

### 🚫 Strict Enforcement

If AI generates:
- Direct file code without Mason reference → ❌ INVALID
- Missing Mason command → ❌ INVALID

---

### 🏁 Final Mason Rule

👉 "No Mason → No Code"

---

### 🧪 Code Coverage Requirement

AI MUST:
- Write comprehensive widget and unit tests for ALL generated features.
- Ensure the overall project code coverage is strictly **> 80%**.
- After generating code, always execute tests and verify coverage percentage.

---

## 🎨 15. UI / Styling Guidelines

### Objective
Ensure consistency across the application by adhering to centralized styling utilities.

### 🔒 Rules
1. **Spaces**: All constant spacing (width/height) across the entire application MUST use `CommonSpaces` (e.g., `CommonSpaces.h16`, `CommonSpaces.w12`). If a required space size does not exist, add it to `lib/utils/common_spaces.dart` before using it.
2. **Fonts**: All text fonts MUST use standard font families defined in `CommonFonts`. If a new font family is required, add it to `lib/utils/common_fonts.dart` before using it.
3. **Typography / TextStyles**: All text styles MUST use extension font styles from `CommonFontStyles` (e.g., `context.titleMedium`, `context.bodyMedium`). If a style needs modification, use `.copyWith(...)`. If a new style is required, add it to `lib/utils/common_fontstyles.dart` before using it.
4. **Icons**: Any new icon shown/used in the application must be registered in `CommonIcons` before using.
5. **Colors**: All colors MUST use theme/color schemes from `CommonColors` via `context.colors`. If a new color is needed, add it to `lib/utils/common_colors.dart` before using it.

