ImGui_ImplDX11_Data :: struct {
    pd3dDevice: *ID3D11Device;
    pd3dDeviceContext: *ID3D11DeviceContext;
    pFactory: *IDXGIFactory;
    pVB: *ID3D11Buffer;
    pIB: *ID3D11Buffer;
    pVertexShader: *ID3D11VertexShader;
    pInputLayout: *ID3D11InputLayout;
    pVertexConstantBuffer: *ID3D11Buffer;
    pPixelShader: *ID3D11PixelShader;
    pFontSampler: *ID3D11SamplerState;
    pFontTextureView: *ID3D11ShaderResourceView;
    pRasterizerState: *ID3D11RasterizerState;
    pBlendState: *ID3D11BlendState;
    pDepthStencilState: *ID3D11DepthStencilState;
    VertexBufferSize: s32 = 5000;
    IndexBufferSize: s32 = 10000;
}
 
ImGui_ImplDX11_GetBackendData :: () -> *ImGui_ImplDX11_Data {
    return ifx ImGui.GetCurrentContext() then ImGui.GetIO().BackendRendererUserData else null;
}

D3D11_Texture :: struct {
    texture: *ID3D11Texture2D;
    out_srv: *ID3D11ShaderResourceView;
    out_width   : s32;
    out_height  : s32;
    loaded      := false;
}