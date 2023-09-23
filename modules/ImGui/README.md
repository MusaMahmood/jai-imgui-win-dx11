![screenshot](examples/example_screenshot.jpg)

This uses a modified copy of ImGui and ImPlot based on version 1.89.6. I plan on adding other imgui utilties like imfilebrowser. To use it, clone the repo into ./jai/modules.

This is not the cleanest solution, so I do not recommend using this for a serious project, because you would have to customize the bindings any time you wanted to update ImGui/ImPlot etc. 
Also, it requires you to create manual bindings for all the plotting procedures that are based on C++ templates in ImPlot. 

Uses: 
 - ImGui, Docking branch, Commit: 823a1385a269d923d35b82b2f470f3ae1fa8b5a3
 - ImPlot, main branch: 18758e237e8906a97ddf42de1e75793526f30ce9

For ImPlot, I added bindings for template functions for float/double args as required. 
I only did this for PlotLine(), because it's the only one I need right now (also I'm lazy). I renamed "PlotLine" as "PlotLineJ" for float32 and "PlotLineJD" for float64.

See the build_from_scratch.ps1 powershell script for instructions to replicate from scratch. It should "Just Work"™


Known issues: 
    - ImPlot Demo "Bar Stacks" crashes for some reason when you open it. Haven't bothered debugging this yet. 