CheckKeyDebounce :: (key_status: *KeyStatus, deltaTime: float32) -> bool {
    using key_status;
    if ImGui.IsKeyDown(key) {
        down_time += deltaTime;
        if down_time > KEY_DEPRESS_TIME && !is_down {
            print("KeyStatus % is down\n", key);
            is_down = true;
            return true;
        }
    } else {
        down_time = 0.0;
        is_down = false;
    }
    return false;
}

CheckKeyCombination :: (mod: ImGui.Key, key: ImGui.Key) -> bool {
    // Note difference between IsKeyDown and IsKeyPressed
    return ImGui.IsKeyDown(mod) && ImGui.IsKeyPressed(key);
}

KeyboardDetectInput :: (keyboard: *Keyboard, done: *bool, deltaTime: float32) {
    using keyboard;
    if CheckKeyCombination(lCtrl.key, w.key) {
        print("Ctrl+W pressed\n");
        (<<done) = true; 
    }
}

KEY_DEPRESS_TIME : float32 : 0.02;

KeyStatus :: struct {
    key         : ImGui.Key = .None;
    down_time   : float32 = 0.0;
    is_down     := false;
}

Keyboard :: struct {
    space       := KeyStatus.{key = .Space};
    enter       := KeyStatus.{key = .Enter}; 
    q           := KeyStatus.{key = .Q};
    w           := KeyStatus.{key = .W};
    e           := KeyStatus.{key = .E};
    r           := KeyStatus.{key = .R};
    t           := KeyStatus.{key = .T};
    y           := KeyStatus.{key = .Y};
    a           := KeyStatus.{key = .A};
    s           := KeyStatus.{key = .S};
    d           := KeyStatus.{key = .D};
    f           := KeyStatus.{key = .F};
    g           := KeyStatus.{key = .G};
    h           := KeyStatus.{key = .H};
    j           := KeyStatus.{key = .J};
    k           := KeyStatus.{key = .K};
    l           := KeyStatus.{key = .L};
    z           := KeyStatus.{key = .Z};
    x           := KeyStatus.{key = .X};
    c           := KeyStatus.{key = .C};
    v           := KeyStatus.{key = .V};
    b           := KeyStatus.{key = .B};
    lCtrl       := KeyStatus.{key = .LeftCtrl};
    lShift      := KeyStatus.{key = .LeftShift};
    lAlt        := KeyStatus.{key = .LeftAlt};
    numKeyMinus := KeyStatus.{key = .KeypadSubtract};
    numKeyPlus  := KeyStatus.{key = .KeypadAdd};
}
