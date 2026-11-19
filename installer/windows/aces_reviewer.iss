#define MyAppName "CPE Reviewer"
#ifndef MyAppVersion
  #define MyAppVersion "1.8.0"
#endif
#define MyAppPublisher "ACES"
#define MyAppExeName "cpe_reviewer.exe"

[Setup]
AppId={{37E603EA-F240-41B0-B946-68D8F4095B2B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\CPE Reviewer
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\dist\windows
OutputBaseFilename=CPE-Reviewer-{#MyAppVersion}-Windows-x64-Setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
UsePreviousAppDir=yes
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb,*.lib,*.exp"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  UpdateMode: Boolean;

function InitializeSetup(): Boolean;
begin
  UpdateMode := Pos('/UPDATECHECK=1', Uppercase(GetCmdTail)) > 0;
  Result := True;
end;

procedure InitializeWizard();
begin
  if UpdateMode then
  begin
    WizardForm.Caption := 'Update CPE Reviewer';
    WizardForm.WelcomeLabel1.Caption := 'Update CPE Reviewer';
    WizardForm.WelcomeLabel2.Caption :=
      'This wizard will update CPE Reviewer in place. Your progress, ' +
      'chats, settings, and downloaded models are kept.';
  end;
end;
