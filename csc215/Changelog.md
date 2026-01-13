# Changelog
## December 12th, 2025
- Added CSTUFF, set up SIMH simulator to be aimed at C: instead of ASM
- Removed ASM stuff from D:, made B: into storage for C compiler
  - `SUBMIT CSTUFF C` to set up, `ERA *.*` on C: afterward to clean
  - CSTUFF.SUB is custom to work on B: and include R, W, and PIP
  - D: now a backup disk for testing other people's stuff
- Task for the day found under C_Code/SUMALL/SUMALL.C
- Updated .gitignore to make R and W to C: easier