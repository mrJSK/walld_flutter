#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                      _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line,
                      _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Work area (screen minus taskbar)
  RECT workArea;
  SystemParametersInfo(SPI_GETWORKAREA, 0, &workArea, 0);

  // OVERSIZE by 2 px in each direction to push border off-screen
  const int overshoot = 2;

  int x      = workArea.left   - overshoot;
  int y      = workArea.top    - overshoot;
  int width  = (workArea.right  - workArea.left) + overshoot * 2;
  int height = (workArea.bottom - workArea.top)  + overshoot * 2;

  Win32Window::Point origin(x, y);
  Win32Window::Size  size(width, height);

  if (!window.Create(L"Wall-D", origin, size)) {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(false);

  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
