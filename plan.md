---

## 📝 Planning Mode Workflow

### Objective
Establish a strict workflow for handling tasks, ensuring all implementation is planned and approved before any code is written or generated.

---

### 🔄 The Workflow

When a prompt or task is given:

1. **Research & Analyze**: Understand the requirements and the current state of the codebase.
2. **Create a Plan of Action**: Formulate a step-by-step plan detailing:
   - What needs to be done.
   - Which Mason bricks will be used (e.g., `mason make feature`, `mason make bloc`).
   - Which files will be affected.
3. **Show the Plan**: Present the plan clearly to the user.
4. **Halt Execution**: Wait for explicit user approval. Do **NOT** write any code or run any code-generation tools.
5. **Proceed on Approval**: Only when the user says "proceed", "start", or "implement" should the execution begin.

---

### 🔒 Rules for the Plan

- The plan must explicitly mention the Mason commands that will be used.
- The plan must adhere to all rules defined in `agent.md`.
- No files should be modified or created during the planning phase.

---

### 🏁 Final Rule

👉 "No Plan Approval → No Implementation"
