unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, OverbyteIcsWndControl, OverbyteIcsWSocket, Vcl.StdCtrls,
  OverbyteIcsWinSock, Vcl.ExtCtrls, TlHelp32, ShellApi;

type
  TfrmMain = class(TForm)
    memLog: TMemo;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function Ping: string;
    function KillTask(ExeFileName: string): Integer;
    procedure LaunchServer;
    procedure Log(s: string);
  public
  end;

const
  ISODateMask = 'yyyy-mm-dd' ;
  ISODateTimeMask = 'yyyy-mm-dd"T"hh:nn:ss' ;
  ISODateLongTimeMask = 'yyyy-mm-dd"T"hh:nn:ss.zzz' ;
  ISOTimeMask = 'hh:nn:ss' ;
  LongTimeMask = 'hh:nn:ss:zzz' ;
  FullDateTimeMask = 'yyyy/mm/dd"-"hh:nn:ss' ;

var
  frmMain: TfrmMain;
  missedPings: integer;

implementation

{$R *.dfm}

procedure TfrmMain.FormShow(Sender: TObject);
begin
  Log('Starting monitor');
  missedPings := 0;
  Timer1.Enabled := true;
end;

function TfrmMain.Ping: string;
begin
  result := '';
  with TWSocket.Create(self) do
  begin
    Proto := 'udp';
    SocketFamily := sfIPv4;
    Addr         := '172.30.0.96';
    LocalAddr    := '172.30.0.96';
//    Addr         := '192.168.190.1';
//    LocalAddr    := '192.168.190.1';
    Port       := '27015';
    LocalPort  := '0';
    Connect;
    SendStr('ÿÿÿÿi');
    ReceiveStr;
    sleep(200);
    result := ReceiveStr;
    if (Length(result) > 1) and (result[length(result)]=#0) then
      SetLength(result, Length(result) - 1);
    Close;
  end;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  if Ping = 'ÿÿÿÿj' then
    //Log('Up')
  else
  begin
    missedPings := missedPings + 1;
    Log('Missed ping count '+inttostr(missedPings));
  end;

  if missedPings >= 2 then
  begin
    missedPings := 0;
    Timer1.Enabled := false;
    try
      Log('Killing task hlds.exe');
      KillTask('hlds.exe');
      sleep(2000);
      Log('Launching server');
      LaunchServer;
    finally
      Timer1.Enabled := true;
    end;
  end;
end;

function TfrmMain.KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TfrmMain.LaunchServer;
var
  params: string;
  fileName: string;
  directory: string;
begin
  //params := '-console -game dod +maxplayers 32 +map dod_saints';
  params := '-console +maxplayers 32 -game dod +port 27015 -nojoy -noipx -heapsize 50000000 +map dod_saints '+
            '+servercfgfile server.cfg +lservercfgfile +mapcyclefile mapcycle.txt +motdfile motd.txt '+
            '+logsdir logs -zone 2048';
  fileName := 'C:\steam\hlds.exe';
  directory := 'C:\steam\';
  ShellExecute(Handle, 'open', PChar(fileName), PChar(params), PChar(directory), SW_SHOWNORMAL);
end;

procedure TfrmMain.Log(s: string);
begin
  memLog.Lines.Add(FormatDateTime(FullDateTimeMask, Now) + ' ' + s)
end;

end.
