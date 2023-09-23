AT_COMPILE_TIME :: true;

COMPILE       :: true; // Enable to compile the imgui library from source before generating bindings.
COMPILE_DEBUG :: false; // Compile a debug or release version of ImGui?

// We don’t ship the Dear ImGui source with the compiler. Download a Dear ImGui release and update this path if you want to re-generate the bindings.
IMGUI_PATH :: "src/imgui";

MACOS_MIN_VERSION :: "10.14";

DECLARATIONS_TO_OMIT :: string.[
    // We have custom declarations for these in module.jai:
    "ImVec2",
    "ImVec4",
    "ImColor",
    "ImVector",
    "ImDrawCallback",

    // Jai has its own, better "String_Builder"
    "ImGuiTextBuffer",

    "ImDrawCallback_ResetRenderState", // casting an integer to a function pointer is not supported in Jai.
];

#if AT_COMPILE_TIME {
    #run {
        set_build_options_dc(.{do_output=false});
        if !generate_bindings() {
            compiler_set_workspace_status(.FAILED);
        }
    }
} else {
    #import "System";

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        if !generate_bindings() {
            exit(1);
        }
    }
}

generate_bindings :: () -> bool {
    #if COMPILE {
        #import "BuildCpp";

        imgui_src_files: [..] string;
        array_add(*imgui_src_files, tprint("%/imgui.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/imgui_widgets.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/imgui_draw.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/imgui_tables.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/imgui_demo.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/implot.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/implot_items.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/implot_demo.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/imgui_impl_dx11.cpp", IMGUI_PATH));
        array_add(*imgui_src_files, tprint("%/imgui_impl_win32.cpp", IMGUI_PATH));

        success := true;
        #if OS == .WINDOWS {
            make_directory_if_it_does_not_exist("windows");
            success &&= build_cpp_dynamic_lib("windows/ImGui-Jai", ..imgui_src_files, extra = .["/DIMGUI_API=__declspec(dllexport)", "/DIMPLOT_API=__declspec(dllexport)", "/DIMGUI_IMPL_API=__declspec(dllexport)"], debug=COMPILE_DEBUG);
            // We set IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS. Otherwise all users of the ImGui module have to link against "imm32".
            success &&= build_cpp_static_lib("windows/ImGui-Jai", ..imgui_src_files, extra = .["/DIMGUI_API=__declspec(dllexport)", "/DIMPLOT_API=__declspec(dllexport)", "/DIMGUI_IMPL_API=__declspec(dllexport)", "/DIMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS"], debug=COMPILE_DEBUG);
        } else #if OS == .LINUX {
            make_directory_if_it_does_not_exist("linux");
            success &&= build_cpp_dynamic_lib("linux/ImGui-Jai", ..imgui_src_files, debug=COMPILE_DEBUG);
            // @Hack: Is -fno-threadsafe-statics really the way to go? Without it, we get linker errors when using the static library
            // due to "__cxa_guard_acquire" et al not being defined. The library users probably need to link agains libc++ or something. But do we really want to enforce that?
            success &&= build_cpp_static_lib("linux/ImGui-Jai", ..imgui_src_files, extra = .["-fno-exceptions", "-fno-rtti", "-fno-threadsafe-statics"], debug=COMPILE_DEBUG);
        } else #if OS == .MACOS {
            make_directory_if_it_does_not_exist("macos");
            MACOS_VERSION_ARG :: #run tprint("-mmacosx-version-min=%", MACOS_MIN_VERSION);
            success &&= build_cpp_dynamic_lib("macos/ImGui-Jai", ..imgui_src_files, extra = .["-std=c++20", MACOS_VERSION_ARG], debug=COMPILE_DEBUG);
            // @Hack: Is -fno-threadsafe-statics really the way to go? Without it, we get linker errors when using the static library
            // due to "__cxa_guard_acquire" et al not being defined. The library users probably need to link agains libc++ or something. But do we really want to enforce that?
            success &&= build_cpp_static_lib("macos/ImGui-Jai", ..imgui_src_files, extra = .["-std=c++20", "-fno-exceptions", "-fno-rtti", "-fno-threadsafe-statics", MACOS_VERSION_ARG], debug=COMPILE_DEBUG);
        } else {
            assert(false);
        }

        if !success     return false;
    }

    defer array_reset(*begin_end_string_args);

    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        #if OS == .WINDOWS {
            array_add(*libpaths, "windows");
            output_filename = "windows.jai";
        } else {
            #if OS == .LINUX {
                array_add(*libpaths, "linux");
            } else #if OS == .MACOS {
                array_add(*libpaths, "macos");
            } else {
                assert(false);
            }
            output_filename = "unix.jai";
            generate_library_declarations = false;
            footer = FOOTER_UNIX;
        }

        array_add(*libnames,      "ImGui-Jai");
        array_add(*include_paths, IMGUI_PATH);
        array_add(*source_files,  tprint("%/imgui.h", IMGUI_PATH));
        array_add(*source_files,  tprint("%/implot.h", IMGUI_PATH));
        array_add(*source_files,  tprint("%/imgui_impl_dx11.h", IMGUI_PATH));
        array_add(*source_files,  tprint("%/imgui_impl_win32.h", IMGUI_PATH));
        array_add(*extra_clang_arguments, "-x", "c++", "-DWIN32_LEAN_AND_MEAN");
        array_add(*flatten_namespaces, "ImGui");
        // array_add(*flatten_namespaces, "ImPlot"); 
        array_add(*strip_prefixes, "ImGui");
        // array_add(*strip_prefixes, "ImPlot");
        auto_detect_enum_prefixes = false;
        log_stripped_declarations = true;
        log_unsupported = true;
        generate_compile_time_struct_checks = false;
        strip_flags |= .INLINED_FUNCTIONS; // "inline" functions are not present in the static library.

        visitor   = imgui_visitor;
        get_func_args_for_printing = imgui_get_function_arg_for_printing;
    }

    return generate_bindings(opts, output_filename);
}

begin_end_string_args: [..]*Declaration;

enums_for_typedefs: Table(string, *Enum);

imgui_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    // ImGui has "typedef ints" for each enum. but we want to just use the enums directly,
    // so we get nice type safety, and .unary dots, etc.
    //
    // Look for declarations inside functions (i.e., arguments) or structs (i.e., fields)
    get_associated_enum_name :: (name: string) -> string {
        if name.count > 1 && name[name.count - 1] != #char "_" {
            return tprint("%_", name);
        }
        return name;
    }

    if !parent_decl {
        if array_find(DECLARATIONS_TO_OMIT, decl.name) {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
            return .STOP;
        }
        if decl.name == "ImGuiContext" {
            decl.output_name = decl.name; // Don’t shorten ImGuiContext to Context as this would conflict
        }

        if decl.kind == .TYPEDEF {
            old_name := decl.name;
            if old_name {
                new_name := get_associated_enum_name(old_name);
                for context.generator.global_scope.members {
                    if it.kind != .ENUM  || it.name != new_name     continue;

                    en := cast(*Enum)it;

                    // Don't output the integer typedef
                    decl.decl_flags |= .OMIT_FROM_OUTPUT;

                    // Make sure the enums like "FocusFlags_" get outputted as "FocusFlags"
                    if en.output_name.count > 2 && en.output_name[en.output_name.count - 1] == #char "_" {
                        en.output_name.count -= 1;
                    }

                    // Keep the comment, if there is one:
                    if decl.comment.text && !en.comment.text {
                        en.comment = decl.comment;
                    }

                    table_add(*enums_for_typedefs, old_name, en);
                    break;
                }
            }
        }
    }

    // Look for function arguments with "typedef" types.
    if parent_decl &&
        (parent_decl.kind == .FUNCTION || parent_decl.kind == .STRUCT) &&
        decl.kind == .DECLARATION && decl.type.type_of_typedef != null
    {
        old_name := decl.type.type_of_typedef.name;
        if old_name {
            en, found := table_find(*enums_for_typedefs, old_name);
            if found {
                // swap in the enum for the typedef
                decl.type.type_of_typedef = null;
                decl.type.type_of_enum = en;

                // we'll also need to output a cast, like "cast(EnumType)5" for the default argument
                decl.decl_flags |= .NEEDS_DEFAULT_ARGUMENT_CAST;
            }
        }
    }

    if decl.kind == .ENUM {
        // ImGui has lots of enums that should be enum flags. Luckily, they all end in "…Flags_".
        if ends_with(decl.name, "Flags_") {
            en := cast(*Enum)decl;
            en.flags |= .IS_ENUM_FLAGS;
            en.flags |= .VALUES_IN_HEX;
        }
    }

    if decl.kind == .FUNCTION {
        func := cast(*Function)decl;
        type := func.type.type_of_function;
        // ImGui also has functions with pairs of arguments like "text_begin" and "text_end"
        // for the pointers to the beginning and end of a string. We'll generate wrappers for
        // those function which take a jai string.
        //
        // Here we collect pointers to "_begin" arguments, and use them in
        // get_func_args_for_printing below.
        for type.arguments {
            if it_index == 0 || !ends_with(it.name, "_end")     continue;
            arg_type := find_underlying_type(it.type);
            if !arg_type.pointer_to || !(arg_type.pointer_to.number_flags & ._8BIT) continue; // Only convert *u8 ranges to string

            name_part := slice(it.name, 0, it.name.count - "_end".count);
            if !name_part   continue;

            // the first arg may appear as "text_begin" or just "text"
            name_part_with_begin := tprint("%_begin", name_part);
            prev_arg := type.arguments[it_index - 1];
            if prev_arg.name == name_part || prev_arg.name == name_part_with_begin {
                array_add(*begin_end_string_args, prev_arg);
                func.decl_flags |= .NEEDS_ARGUMENT_WRAPPER;
            }
        }
    }

    return .RECURSE;
}

// Modify function with _begin and _end string arguments as they get printed.
// See the note above about "text_begin".
imgui_get_function_arg_for_printing :: (func: *Function, type: *Function_Type, mode: Arg_Print_Mode) -> []*Declaration {
    args: [..]*Declaration;
    for type.arguments {
        if array_find(begin_end_string_args, it) {
            if mode == {
                case .OUTER_WRAPPER;
                    // For the outer wrapper, remove any "_begin" part of the argument, and
                    // change its type to a jai string
                    arg_copy := New(Declaration);
                    (<<arg_copy) = <<it;
                    arg_copy.type = context.generator.type_def_jai_string;
                    if ends_with(it.name, "_begin") {
                        arg_copy.output_name = slice(it.name, 0, it.name.count - "_begin".count);
                    }
                    array_add(*args, arg_copy);

                    it_index += 1; // skip the next argument-we collpase the _begin and _end args into one string arg

                    continue;
                case .INNER_WRAPPER_CALL;
                    // For the inner wrapper function call, we pass the incoming arg
                    // as two arguments: "jai_string.data, jai_string.data + jai_string.count" -- corresponding
                    // to the _begin and _end parts.
                    base_arg_name := it.name;
                    if ends_with(it.name, "_begin") {
                        base_arg_name = slice(it.name, 0, it.name.count - "_begin".count);
                    }

                    arg_copy := New(Declaration);
                    (<<arg_copy) = <<it;
                    arg_copy.output_name = tprint("%.data", base_arg_name);
                    array_add(*args, arg_copy);

                    arg_copy_2 := New(Declaration);
                    (<<arg_copy_2) = <<it;
                    arg_copy_2.output_name = tprint("%.data + %.count", base_arg_name, base_arg_name);
                    array_add(*args, arg_copy_2);

                    it_index += 1; // skip the next arg, since we already added a second one above
                    continue;
            }
        }

        array_add(*args, it);
    }

    return args;
}

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";

FOOTER_UNIX :: #string END

#if OS == .MACOS    imgui :: #library "macos/ImGui";
#if OS == .LINUX    imgui :: #library "linux/ImGui";

END
