# Axial Stress Solver — 1D FEM & 3D Visualization Tool

![Language: C](https://img.shields.io/badge/Core_Solver-C99-blue.svg)
![GUI: MATLAB](https://img.shields.io/badge/GUI_%26_3D_View-MATLAB-orange.svg)
![Method: 1D FEM](https://img.shields.io/badge/Method-1D_FEM-green.svg)

**Axial Stress Solver** is an engineering desktop application for the static and thermo-mechanical analysis of stepped cylindrical bars fixed at both ends. It combines a fast **1D Finite Element Method (FEM) solver written in C** with an interactive **3D pre- and post-processing GUI built in MATLAB**.

![Axial Stress Solver Overview](docs/screenshots/01_test_case_1_dual_loads.png)

## Key Features

* **Hybrid C + MATLAB Architecture:** Decouples matrix assembly and Gaussian elimination (`math.c`) from interactive 3D rendering and diagram plotting (`SolverApp.m`) via structured text I/O.
* **Automatic Mesh Generation:** Dynamically discretizes the stepped bar into finite elements by placing nodes at both fixed supports, cross-section interfaces, and external force application points.
* **Combined Mechanical & Thermal Loading:** Supports multiple axial point loads ($F_i$) at arbitrary positions alongside uniform temperature changes ($\Delta T$ — heating and cooling).
* **Interactive 3D Visualization:**
  * Pre-processing view with stepped bar geometry, fixed walls, non-overlapping force arrows, and thermal indicators.
  * Post-processing 3D stress contour plot (`jet` colormap) with auto-scaled axial deformation and wireframe toggle.
* **Engineering Diagrams:** Generates clean 2D distributions for **Axial Displacement** $u(x)$, **Internal Axial Force** $N(x)$, and **Normal Stress** $\sigma(x)$, along with support reactions $R_A$ and $R_B$.

## Application Screenshots

### 1. Test Case 1 — Two-Segment Bar with Dual Axial Forces
*Geometry:* $L = [100, 100]\,\text{mm}$, $D = [50.463, 35.682]\,\text{mm}$ | *Loads:* $F_1 = +20\,\text{kN}$ at $x = 50\,\text{mm}$, $F_2 = +20\,\text{kN}$ at $x = 150\,\text{mm}$

![Test Case 1](docs/Output_Data_Analysis/MATLAB%20ZAD1.png)

### 2. Test Case 2 — Three-Segment Stepped Bar
*Geometry:* $L = [100, 100, 100]\,\text{mm}$, $D = [30, 15, 10]\,\text{mm}$ | *Load:* $F_1 = -29\,\text{kN}$ at $x = 100\,\text{mm}$

![Test Case 2 — Three-Segment Stepped Bar](docs/screenshots/02_test_case_2_stepped_bar.png)

### 3. Test Case 3 — Combined Mechanical & Thermal Loading ($\Delta T = +20\,^\circ\text{C}$)
*Geometry:* $L = [30, 30, 45]\,\text{mm}$, $D = [31.915, 31.915, 22.568]\,\text{mm}$ | *Loads:* $F_1 = +20\,\text{kN}$ at $x = 30\,\text{mm}$, $\alpha = 12 \times 10^{-6}/^\circ\text{C}$, $\Delta T = +20\,^\circ\text{C}$

![Test Case 3 — Combined Mechanical and Thermal Loading](docs/screenshots/03_test_case_3_thermal_load.png)

## Mathematical Formulation & Workflow

The solver models the bar using 1D linear bar elements with local stiffness $k_e = \frac{E A_e}{L_e}$ and equivalent thermal nodal forces $F_{\text{term}, e} = E A_e \alpha \Delta T$. The global equilibrium system is assembled as:

$$
[K_{\text{global}}]\{U\} = \{F_{\text{ext}}\} + \{F_{\text{term, global}}\}
$$

Fixed boundary conditions at both ends ($U_1 = 0$, $U_N = 0$) are enforced using the **Penalty Method** (multiplying end-node diagonal stiffness entries by $10^{15}$), and the resulting system is solved via **Gaussian Elimination**.

For full mathematical derivations, matrix assembly details, and unit consistency tables, refer to [`docs/Theoretical_Background_and_FEM_Formulation.pdf`](docs/Theoretical_Background_and_FEM_Formulation.pdf).

### Execution Pipeline

1. **Pre-Processing (`SolverApp.m`):** Validates user input, renders the 3D model, and exports parameters to `ulaz_za_C.txt`.
2. **Numerical Computation (`solver.exe`):** Reads `ulaz_za_C.txt`, builds the mesh and stiffness matrix, solves for nodal displacements, computes element forces/stresses, and writes results to `rezultati_iz_C.txt`.
3. **Post-Processing (`SolverApp.m`):** Parses `rezultati_iz_C.txt` and updates support reactions, 3D deformed stress contours, and 2D diagrams.

## Verification & Validation

The C 1D FEM solver was verified against hand-calculated analytical solutions (force method / superposition) and cross-checked against 3D finite element simulations (**ANSYS 3D FEM**) across three benchmark cases:

| Benchmark Case | Key Parameter | Analytical | C 1D FEM Solver | 1D Error | ANSYS 3D FEM | ANSYS 3D Diff. |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Test Case 1** *(2 Segments, $2 \times 20\,\text{kN}$)* | $R_A$ / $R_B$ ($\text{kN}$) | $-23.33$ / $-16.67$ | $-23.33$ / $-16.67$ | $0.00\%$ | $-23.18$ / $-16.82$ | $\approx 0.77\%$ |
| **Test Case 1** | $\sigma_{\max}$ ($\text{MPa}$) | $-16.67$ | $-16.67$ | $0.00\%$ | $-17.02$ | $2.10\%$ |
| **Test Case 2** *(3 Segments, $-29\,\text{kN}$)* | $R_A$ / $R_B$ ($\text{kN}$) | $+26.93$ / $+2.07$ | $+26.93$ / $+2.07$ | $0.00\%$ | $+26.78$ / $+2.22$ | $\approx 3.90\%$ |
| **Test Case 2** | $\sigma_{\max}$ ($\text{MPa}$) | $-38.10$ | $-38.10$ | $0.00\%$ | $-38.94$ | $2.20\%$ |
| **Test Case 3** *(Thermal $\Delta T = +20\,^\circ\text{C}$)* | $R_A$ / $R_B$ ($\text{kN}$) | $+12.22$ / $-32.22$ | $+12.22$ / $-32.22$ | $0.00\%$ | $+12.08$ / $-32.36$ | $\approx 0.79\%$ |
| **Test Case 3** | $\sigma_{\max}$ ($\text{MPa}$) | $-80.56$ | $-80.56$ | $0.00\%$ | $-82.15$ | $1.97\%$ |

> **Engineering Note on 1D vs. 3D FEM:** The C/MATLAB solver is based on classical 1D uniaxial bar theory ($\sigma_x = E \varepsilon_x$) and therefore reproduces analytical solutions with **$0.00\%$ numerical error**. In contrast, 3D solid elements in ANSYS account for **Poisson's ratio ($\nu \approx 0.3$)** — lateral contraction/expansion is constrained at the rigid end walls and stepped diameter transitions, producing a localized triaxial stress state and a minor $\approx 1.8\%$ difference relative to 1D theory.

* Detailed error tables and comparison charts: [`Output_Data_Analysis/Error_Analysis_Table.xlsx`](Output_Data_Analysis/Error_Analysis_Table.xlsx)
* Hand-written analytical derivations & benchmark test cases: [`Output_Data_Analysis/`](Output_Data_Analysis/)

## Repository Structure

```text
Axial-Stress-Solver-1D-FEM/
├── SolverApp.m                                         # MATLAB GUI, 3D visualization & I/O handler
├── math.c                                              # C source code for 1D FEM solver & Gaussian elimination
├── README.md                                           # Project documentation
├── docs/
│   ├── Theoretical_Background_and_FEM_Formulation.pdf  # Mathematical formulation & matrix equations
│   └── screenshots/
│       ├── 01_test_case_1_dual_loads.png               # Test Case 1 GUI output
│       ├── 02_test_case_2_stepped_bar.png              # Test Case 2 GUI output
│       └── 03_test_case_3_thermal_load.png             # Test Case 3 GUI output (thermal + mechanical)
└── Output_Data_Analysis/
    ├── Error_Analysis_Table.xlsx                       # Analytical vs. 1D FEM vs. ANSYS 3D comparison
    ├── Test_Case_1/                                    # Analytical & numerical files for Case 1
    ├── Test_Case_2/                                    # Analytical & numerical files for Case 2
    └── Test_Case_3/                                    # Analytical & numerical files for Case 3
```

## Getting Started

### Prerequisites

* **C Compiler:** GCC (e.g., MinGW-w64 on Windows)
* **MATLAB:** R2019b or newer (with `uifigure` / `uiaxes` support)

### How to Run

1. Clone this repository and navigate to the project directory:
   ```bash
   git clone https://github.com/your-username/Axial-Stress-Solver-1D-FEM.git
   cd Axial-Stress-Solver-1D-FEM
   ```

2. Compile the C computational core into `solver.exe`:
   ```bash
   gcc math.c -O2 -o solver.exe
   ```

3. Open MATLAB, set the Current Folder to the repository directory, and run:
   ```matlab
   SolverApp
   ```

4. Click **2. GENERATE 3D MODEL & INPUT FILE**, then click **3. RUN C SOLVER & LOAD RESULTS**.

## Author

**Stefan Dronjak**  
Mechanical Engineering — Finite Element Method & Scientific Computing
