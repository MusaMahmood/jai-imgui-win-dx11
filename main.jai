hwnd : HWND;
driver_type := D3D_DRIVER_TYPE.NULL;
feature_level := D3D_FEATURE_LEVEL._11_0;

g_pd3dDevice : *ID3D11Device;
g_pd3dDeviceContext : *ID3D11DeviceContext;
g_pSwapChain : *IDXGISwapChain;
g_mainRenderTargetView : *ID3D11RenderTargetView;
g_resizeWidth : u32 = 0;
g_resizeHeight : u32 = 0;

main :: () {
    print("\n\n------------ PROGRAM_OUTPUT ------------\n\n");

    wc : WNDCLASSEXW; memset(*wc, 0, size_of(WNDCLASSEXW));
    wc.cbSize = size_of(WNDCLASSEXW);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = xx WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = null;
    wc.hIcon = LoadIconW(null, utf8_to_wide("APPICON"));
    wc.hCursor = LoadCursorW(null, IDC_ARROW); 
    wc.hbrBackground = null;
    wc.lpszMenuName = null; 
    wc.lpszClassName = utf8_to_wide("JaiWindowClass");
    
    if RegisterClassExW(*wc) == 0 {
        print("RegisterClassExW failed\n");
        return;
    }

    rc: RECT;
    rc.left = 0; rc.top = 0; rc.right = 1280; rc.bottom = 800;

    AdjustWindowRect(*rc, WS_OVERLAPPEDWINDOW, BOOL.FALSE);
    hwnd = CreateWindowExW(WS_EX_APPWINDOW, utf8_to_wide("JaiWindowClass"), utf8_to_wide("Dear ImGui DirectX11 Example"), WS_OVERLAPPEDWINDOW,
         CW_USEDEFAULT, CW_USEDEFAULT, rc.right - rc.left, rc.bottom - rc.top, null, null, null, null);

    if !hwnd {
        print("CreateWindowExW failed\n");
        DestroyWindow(hwnd);
        return;
    }
    defer DestroyWindow(hwnd);

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    // Init D3D
    init_device();
    CreateRenderTarget();
    defer CleanupDeviceD3D();

    log("ImGui (docking) % ", to_string(ImGui.GetVersion()));

    imgui_context := ImGui.CreateContext();
    defer ImGui.DestroyContext(imgui_context);

    io := ImGui.GetIO();
    io.ConfigFlags_ |= ImGui.ConfigFlags.NavEnableKeyboard;     // Enable Keyboard Controls
    io.ConfigFlags_ |= ImGui.ConfigFlags.NavEnableGamepad;      // Enable Gamepad Controls
    io.ConfigFlags_ |= ImGui.ConfigFlags.DockingEnable;
    io.ConfigFlags_ |= ImGui.ConfigFlags.ViewportsEnable;
    
    // Setup style
    ImGui.StyleColorsDark();
    style : *ImGui.Style = ImGui.GetStyle();
    // TODO: Set custom light/dark modes. Use compile time execution function to convert hex codes to float.
    if io.ConfigFlags_ & ImGui.ConfigFlags.ViewportsEnable {
        style.WindowRounding = 0.0;
        style.Colors[ImGui.Col.WindowBg].w = 1.0;
    }

    // Setup ImGui binding
    ImGui.ImplWin32_Init(hwnd);
    defer ImGui.ImplWin32_Shutdown();
    ImGui.ImplDX11_Init(cast,no_check(*ImGui.ID3D11Device) g_pd3dDevice, cast,no_check(*ImGui.ID3D11DeviceContext)g_pd3dDeviceContext);
    defer ImGui.ImplDX11_Shutdown();

    all_font_files := FindAllFonts("../fonts");
    defer array_free(all_font_files);
    all_fonts : [..]*ImGui.ImFont; array_resize(*all_fonts, all_font_files.count);
    current_font_index := -1;
    for ff : 0..all_font_files.count-1 {
        str_len := all_font_files[ff].count;
        font_path_cstr := to_c_string(all_font_files[ff]);
        defer free(font_path_cstr);
        print("Loading font: %\n", all_font_files[ff]);
        all_fonts[ff] = ImGui.IO.Fonts.AddFontFromFileTTF(io.Fonts, font_path_cstr, 14.0);
        // if wildcard_match(all_font_files[ff], "*segoeui.ttf*") {
        if wildcard_match(all_font_files[ff], "*Roboto-Regular*") {
            current_font_index = ff;
        }
    }

    clear_color := make_vector4(0.45, 0.55, 0.60, 1.00);

    show_demo_window := true;
    keyboard: Keyboard; 
    done : bool = false; 
 
    // Main loop
    while !done {
        msg : MSG;
        while (PeekMessageW(*msg, null, 0, 0, PM_REMOVE)) {
            TranslateMessage(*msg);
            DispatchMessageW(*msg);
            if (msg.message == WM_QUIT) {
                done = true;
            }
        }
        if done { break; }

        // Check Keyboard input
        KeyboardDetectInput(*keyboard, *done, io.DeltaTime);

        // Handle Window Resize: 
        if (g_resizeWidth != 0 && g_resizeHeight != 0) {
            CleanupRenderTarget();
            IDXGISwapChain_ResizeBuffers(g_pSwapChain, 0, g_resizeWidth, g_resizeHeight, DXGI_FORMAT.UNKNOWN, 0);
            CreateRenderTarget();
            g_resizeWidth = 0;
            g_resizeHeight = 0;
        }

        // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
        // - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
        // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
        // Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
        ImGui.ImplDX11_NewFrame();
        // Start the frame. This call will update the io.WantCaptureMouse, io.WantCaptureKeyboard flag that you can use to dispatch inputs (or not) to your application.
        ImGui.ImplWin32_NewFrame();
        ImGui.NewFrame();
        // NOTE: UI content begins
        if current_font_index >= 0 { ImGui.PushFont(all_fonts[current_font_index]); }
        RenderDockingInterface();
        ImGui.ShowDemoWindow(*show_demo_window);
        ImGui.ImPlot.CreateContext();
        ImGui.ImPlot.ShowDemoWindow(*show_demo_window);
        ImGui.ImPlot.DestroyContext();
        if current_font_index >= 0 { ImGui.PopFont(); }
        // NOTE: UI content ends

        // Rendering
        ImGui.Render();
        clear_color_array : [4]float;
        clear_color_array[0] = clear_color.x; clear_color_array[1] = clear_color.y; clear_color_array[2] = clear_color.z; clear_color_array[3] = clear_color.w;
        ID3D11DeviceContext_OMSetRenderTargets(g_pd3dDeviceContext, 1, *g_mainRenderTargetView, null);
        ID3D11DeviceContext_ClearRenderTargetView(g_pd3dDeviceContext, g_mainRenderTargetView, *clear_color_array);
        ImGui.ImplDX11_RenderDrawData(ImGui.GetDrawData());
        
        if io.ConfigFlags_ & ImGui.ConfigFlags.ViewportsEnable {
            ImGui.UpdatePlatformWindows();
            ImGui.RenderPlatformWindowsDefault();
        }

        IDXGISwapChain_Present(g_pSwapChain, 1, 0); // Present with vsync
        // IDXGISwapChain_Present(g_pSwapChain, 0, 0); // Present without vsync
    }
}

CreateRenderTarget :: () {
    pBackBuffer : *ID3D11Texture2D;
    IDXGISwapChain_GetBuffer(g_pSwapChain, 0, *uid(ID3D11Texture2D_UUID), xx *pBackBuffer);
    ID3D11Device_CreateRenderTargetView(g_pd3dDevice, pBackBuffer, null, *g_mainRenderTargetView);
    IUnknown_Release(pBackBuffer);
}

CleanupDeviceD3D :: () {
    CleanupRenderTarget();
    if (g_pSwapChain) { IUnknown_Release(g_pSwapChain); g_pSwapChain = null; }
    if (g_pd3dDeviceContext) { IUnknown_Release(g_pd3dDeviceContext); g_pd3dDeviceContext = null; }
    if (g_pd3dDevice) { IUnknown_Release(g_pd3dDevice); g_pd3dDevice = null; }
}

CleanupRenderTarget :: () {
    if (g_mainRenderTargetView) { IUnknown_Release(g_mainRenderTargetView); g_mainRenderTargetView = null; }
}

init_device :: () -> bool {
    hr : HRESULT = S_OK; 
 
    flags : D3D11_CREATE_DEVICE_FLAG; 
 
    driver_types   := D3D_DRIVER_TYPE.[.HARDWARE, .WARP, .REFERENCE];
    feature_levels := D3D_FEATURE_LEVEL.[._11_1, ._11_0, ._10_1, ._10_0];
 
    for 0..driver_types.count-1 {

        driver_type = driver_types[it]; 
        hr = D3D11CreateDevice(null, driver_type, null, flags, feature_levels.data, feature_levels.count, D3D11_SDK_VERSION, *g_pd3dDevice, *feature_level, *g_pd3dDeviceContext);
 
        if hr == E_INVALIDARG {
            // DirectX 11.0 platforms will not recognize D3D_FEATURE_LEVEL_11_1 so we need to retry without it.
            hr = D3D11CreateDevice(null, driver_type, null, flags, feature_levels.data + 1, feature_levels.count - 1, D3D11_SDK_VERSION, *g_pd3dDevice, *feature_level, *g_pd3dDeviceContext);
        }
 
        if SUCCEEDED(hr) break;
    } 
    if FAILED(hr) {
        print("D3D11CreateDevice failed.\n");
        return false;
    }

    assert(g_pd3dDevice != null);
    print("Created D3D11 device % with feature level %\n", g_pd3dDevice, feature_level);


    // Obtain DXGI factory from device (since we used null for pAdapter above) 
    dxgi_factory : *IDXGIFactory1;
    {
        dxgi_device : *IDXGIDevice;
        hr = IUnknown_QueryInterface(g_pd3dDevice, *uid(IDXGIDevice_UUID), xx *dxgi_device); 
        // You could also use the vtable helper instead of the C api:
        // hr = vtable(g_pd3dDevice).QueryInterface(g_pd3dDevice, *uid(IDXGIDevice_UUID), xx *dxgi_device); 
        if SUCCEEDED(hr) {
            adapter : *IDXGIAdapter;
            hr = IDXGIDevice_GetAdapter(dxgi_device, *adapter);
            if SUCCEEDED(hr) {
                hr = IDXGIObject_GetParent(adapter, *uid(IDXGIFactory1_UUID), xx *dxgi_factory); 
                IUnknown_Release(adapter); 
            } 
            IUnknown_Release(dxgi_device); 
        }
        else {
            print("QueryInterface FAILED\n");
        }
    }
    if FAILED(hr) {
        print("GetAdapter failed.\n");
        return false;
    }

    print("Create swap chain\n");

    rc : RECT;
    GetClientRect(hwnd, *rc); 
    width := rc.right - rc.left; 
    height := rc.bottom - rc.top; 

    // Create swap chain 
    {
        // DirectX 11.0 systems 
        sd : DXGI_SWAP_CHAIN_DESC; 
        sd.BufferCount = 1; 
        sd.BufferDesc.Width = xx width; 
        sd.BufferDesc.Height = xx height; 
        sd.BufferDesc.Format = .R8G8B8A8_UNORM; 
        sd.BufferDesc.RefreshRate.Numerator = 60; 
        sd.BufferDesc.RefreshRate.Denominator = 1; 
        sd.BufferUsage = .RENDER_TARGET_OUTPUT; 
        sd.OutputWindow = hwnd; 
        sd.SampleDesc.Count = 1; 
        sd.SampleDesc.Quality = 0; 
        sd.Windowed = BOOL.TRUE; 
 
        hr = IDXGIFactory_CreateSwapChain(dxgi_factory, g_pd3dDevice, *sd, *g_pSwapChain); 
        if FAILED(hr) {
            log_error("CreateSwapChain failed: %", hr);
        }
    } 
 
    // Note this tutorial doesn't handle full-screen swapchains so we block the ALT+ENTER shortcut 
    IDXGIFactory_MakeWindowAssociation(dxgi_factory, hwnd, cast (u32) DXGI_MWA.NO_ALT_ENTER); 
    IUnknown_Release(dxgi_factory); 
 
    if FAILED(hr) return false;

    return true; 
}

// Called every time the application receives a message 
WndProc :: (hWnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) -> LRESULT #c_call {
    //ps : PAINTSTRUCT;
    hdc : HDC;
    // NOTE: you have to uncomment this line in imgui_impl_win32 before generating bindings.
    // You also have to #import "Windows"; in the windows.jai bindings file.
    if (ImGui.ImplWin32_WndProcHandler(hwnd, message, wParam, lParam)) {
        return cast(LRESULT) true;
    }
 
    if message == { 
    //case WM_PAINT;
        //hdc = BeginPaint(hWnd, *ps); 
        //EndPaint(hWnd, *ps); 
    case WM_SIZE;
        if (wParam == SIZE_MINIMIZED) {
            return 0;
        }
        g_resizeWidth  = cast(u32)LOWORD(lParam);
        g_resizeHeight = cast(u32)HIWORD(lParam);
        return 0;
    case WM_DESTROY;
        PostQuitMessage( 0 ); 
 
        // Note that this tutorial does not handle resizing (WM_SIZE) requests, 
        // so we created the window without the resize border. 
     case; 
        return DefWindowProcW( hWnd, message, wParam, lParam ); 
    } 
 
    return 0; 
} 

LOWORD :: (x: s64) -> s16 #expand { return cast,no_check(s16)((x) & 0x0000_0000_0000_ffff); }
HIWORD :: (x: s64) -> s16 #expand { return cast,no_check(s16)((x >> 16) & 0x0000_0000_0000_ffff); }

FindAllFonts :: (fonts_path: string) -> []string {
    fl : []string = file_list(fonts_path);
    return fl;
}

#load "src/UI/Dockspace.jai";
#load "src/Rendering/DX11.jai";
#load "src/IO/Keyboard.jai";

// Modules
ImGui       :: #import,dir "modules/ImGui";
#import "d3d11";
#import "d3d_compiler";
#import "dxgi";
#import "Basic";
#import "File";
#import "File_Utilities";
#import "Math";
#import "Pool";
#import "Sort";
#import "String";
#import "System";
#import "Thread";
#import "Windows";
#import "Windows_Utf8";