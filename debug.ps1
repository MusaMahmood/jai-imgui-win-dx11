if (!(Test-Path -Path ".\bin")) {
    New-Item -ItemType Directory -Path ".\bin"
}

jai -llvm .\main.jai -exe jai-imgui-win-dx11-debug -output_path .\bin

cd .\bin
Start-Process -FilePath .\jai-imgui-win-dx11-debug.exe

cd ..