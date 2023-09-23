if (!(Test-Path -Path ".\bin")) {
    New-Item -ItemType Directory -Path ".\bin"
}

jai -llvm .\main.jai -exe jai-imgui-win-dx11 -output_path .\bin -release -quiet

cd .\bin
Start-Process -FilePath .\jai-imgui-win-dx11.exe

cd .. 