RenderDockingInterface :: () {
    dockspace_flags : ImGui.DockNodeFlags = ImGui.DockNodeFlags.None;
    window_flags : ImGui.WindowFlags = /*ImGui.WindowFlags.MenuBar |*/ ImGui.WindowFlags.NoDocking;
    { // opt_fullscreen = true
        viewport : ImGui.Viewport = ImGui.GetMainViewport();
        ImGui.SetNextWindowPos(viewport.Pos);
        ImGui.SetNextWindowSize(viewport.Size);
        ImGui.SetNextWindowViewport(viewport.ID_);
        ImGui.PushStyleVar(ImGui.StyleVar.WindowRounding, 0.0);
        ImGui.PushStyleVar(ImGui.StyleVar.WindowBorderSize, 0.0);
        window_flags |= ImGui.WindowFlags.NoTitleBar | ImGui.WindowFlags.NoCollapse | ImGui.WindowFlags.NoResize | ImGui.WindowFlags.NoMove;
        window_flags |= ImGui.WindowFlags.NoBringToFrontOnFocus | ImGui.WindowFlags.NoNavFocus;
    }
    
    if dockspace_flags & ImGui.DockNodeFlags.PassthruCentralNode {
        window_flags |= ImGui.WindowFlags.NoBackground;
    }

    styleval : ImGui.ImVec2 = make_vector2(0, 0);
    ImGui.PushStyleVar(ImGui.StyleVar.WindowPadding, styleval);
    ImGui.Begin("DockSpace Demo", null, window_flags);
    ImGui.PopStyleVar(3);
    
    // TODO: Add menu bar for controlling visibility of settings and playback control.

    // Submit the DockSpace
    dock_style : ImGui.ImVec2 = make_vector2(0, 0);
    ImGui.DockSpace(ImGui.GetID("MyDockSpace"), dock_style, dockspace_flags);
    ImGui.End();
}