# Cleans, clones repos, modifies files, and builds the project, and runs.

$clean = $false
$choice = Read-Host "Enter 'clean' to clean the project (default: just regenerates bindings)"
if ($choice -eq "clean") {
    $clean = $true
} 

# Clean
if ($clean) {
    Remove-Item -Path src -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path .build -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path .\windows.jai -Force -ErrorAction SilentlyContinue
    Remove-Item -Path .\unix.jai -Force -ErrorAction SilentlyContinue

    # 1. Clone repos
    if (Test-Path -Path src) {
        Remove-Item -Path src -Recurse -Force
    }
    New-Item -Path . -Name src -ItemType Directory
    cd src
    git clone https://github.com/ocornut/imgui
    cd imgui; $imgui_folder = Get-Location
    git checkout docking 
    git checkout 823a1385a269d923d35b82b2f470f3ae1fa8b5a3
    Remove-Item -Path backends -Recurse -Force
    Remove-Item -Path docs -Recurse -Force
    Remove-Item -Path examples -Recurse -Force
    Remove-Item -Path misc -Recurse -Force
    Remove-Item -Path .\.git -Recurse -Force
    Remove-Item -Path .\.github -Recurse -Force
    cd ..
    git clone https://github.com/epezent/implot
    cd implot; $implot_folder = Get-Location
    git checkout 18758e237e8906a97ddf42de1e75793526f30ce9

    Robocopy $implot_folder $imgui_folder *.h *.cpp /E
    Robocopy $imgui_folder\backends $imgui_folder *.h *.cpp /E
    cd .. # src 
    Remove-Item -Path $implot_folder -Recurse -Force
    cd .. # back to root

    # 2. Modify files
    cd .\src\imgui

    $newLines = "IMPLOT_API void PlotLineJ(const char* label_id, const float* values, int count, float xscale=1, float x0=0, int offset=0, int stride=sizeof(float));", "IMPLOT_API void PlotLineJ(const char* label_id, const float* xs, const float* ys, int count, ImPlotLineFlags flags=0, int offset=0, int stride=sizeof(float));", "IMPLOT_API void PlotLineJD(const char* label_id, const double* values, int count, double xscale=1, double x0=0, int offset=0, int stride=sizeof(double));", "IMPLOT_API void PlotLineJD(const char* label_id, const double* xs, const double* ys, int count, ImPlotLineFlags flags=0, int offset=0, int stride=sizeof(double));"
    (Get-Content -Path .\implot.h) | ForEach-Object {
        $_
        if ($_ -match "// Plots a standard 2D line plot.") {
            # Add lines after comment:
            $newLines
        }
    } | Set-Content -Path .\implot.h

    $newLines2 = "void PlotLineJ(const char* label_id, const float* values, int count, float xscale, float x0, int offset, int stride) { PlotLine(label_id, values, count, (double)xscale, (double)x0, ImPlotLineFlags_None, offset, stride); }", "void PlotLineJ(const char* label_id, const float* xs, const float* ys, int count, ImPlotLineFlags flags, int offset, int stride) { PlotLine(label_id, xs, ys, count, flags, offset, stride); }", "void PlotLineJD(const char* label_id, const double* values, int count, double xscale, double x0, int offset, int stride) { PlotLine(label_id, values, count, xscale, x0, ImPlotLineFlags_None, offset, stride); }", "void PlotLineJD(const char* label_id, const double* xs, const double* ys, int count, ImPlotLineFlags flags, int offset, int stride) { PlotLine(label_id, xs, ys, count, flags, offset, stride); }", "`n"
    $line_number = 0
    (Get-Content -Path .\implot_items.cpp) | ForEach-Object {
        $_
        $line_number++
        if ($line_number -eq 1568) {
            # Add lines after comment:
            $newLines2
        }
    } | Set-Content -Path .\implot_items.cpp
    # (gc .\implot_items.cpp) -replace "// [SECTION] PlotLine`r`n", "// [SECTION] PlotLine`r`n$newLines2" | sc .\implot_items.cpp

    cd ..\..
}

# 3. Build & run:
jai .\generate.jai
