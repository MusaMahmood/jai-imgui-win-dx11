Basic ImGui project in Jai with Windows and DX11 backend. I might add examples of how to draw images/video, but for now this is just a minimal template. 
Includes Implot because I was too lazy to tear it out (I needed it for other projects and it was easier just to bundle with ImGui). 
See modules/ImGui/build_from_scratch.ps1 on how to remove. I'll remove it in a future commit. 

Uses the following libraries:
- ImGui 1.89.6, docking branch with DX11 and Win32 backends: https://github.com/ocornut/imgui/tree/docking
- ImPlot, some specific 1.89.6 compatible commit, see modules/ImGui/build_from_scratch.ps1

Windows only (obviously).

