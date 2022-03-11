unit TaskRecord;

interface
type
    FolderType = (FNone, FToday, FWeek);
    TTask = record
        id, ProjectId, RepeatInterval, LastRepeat, CreationDate: longint;
        name: string;
        folder: FolderType;
        done, removed, green: boolean;
    end;
    FileOfTask = file of TTask;

function TaskRecordCount(var TasksFile: FileOfTask): longint;
procedure SetTaskRecordCount(NewCount: longint; var TasksFile: FileOfTask);
procedure GetTaskRecord(id: longint; var task: TTask; var TasksFile: FileOfTask);
procedure GetTaskRecordName(id: longint; var name: string; 
    var TasksFile: FileOfTask);
function GetTaskRecordFolder(id: longint; var TasksFile: FileOfTask): FolderType;
procedure SetTaskRecordFolder(id: longint; NewFolder: FolderType; 
    var TasksFile: FileOfTask);
procedure SetTaskRecord(var task: TTask; var TasksFile: FileOfTask);
procedure SetTaskRecordName(id: longint; var name: string; 
    var TasksFile: FileOfTask);
procedure SetTaskRecordProject(id: longint; var ProjectId: longint;
        var TasksFile: FileOfTask);
procedure SetTaskRecordDone(id: longint; var TasksFile: FileOfTask);
procedure SetTaskRecordRemoved(id: longint; var TasksFile: FileOfTask);
procedure SetTaskRecordGreen(id: longint; var TasksFile: FileOfTask);
procedure AddTaskRecord(var name: string; var TasksFile: FileOfTask);

implementation
uses sysutils;

function TaskRecordCount(var TasksFile: FileOfTask): longint;
var
    tmp: TTask;
begin
    GetTaskRecord(0, tmp, TasksFile);
    TaskRecordCount := tmp.id;
end;

procedure SetTaskRecordCount(NewCount: longint; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(0, tmp, TasksFile);
    tmp.id := NewCount;
    seek(TasksFile, 0);
    write(TasksFile, tmp);
end;

procedure GetTaskRecord(id: longint; var task: TTask; var TasksFile: FileOfTask);
begin
    seek(TasksFile, id);
    read(TasksFile, task);
end;

procedure GetTaskRecordName(id: longint; var name: string; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile);
    name := tmp.name;
end;

function GetTaskRecordFolder(id: longint; var TasksFile: FileOfTask): FolderType;
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile);
    GetTaskRecordFolder := tmp.folder;
end;
procedure SetTaskRecordFolder(id: longint; NewFolder: FolderType; 
    var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile);
    tmp.folder := NewFolder;
    SetTaskRecord(tmp, TasksFile);
end;

procedure SetTaskRecord(var task: TTask; var TasksFile: FileOfTask);
begin
    seek(TasksFile, task.id);
    write(TasksFile, task);
end;

procedure SetTaskRecordName(id: longint; var name: string; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.name := name;
    SetTaskRecord(tmp, TasksFile);
end;

procedure SetTaskRecordProject(id: longint; var ProjectId: longint;
        var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.ProjectId := ProjectId;
    SetTaskRecord(tmp, TasksFile);
end;

procedure SetTaskRecordDone(id: longint; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.done := not tmp.done;
    SetTaskRecord(tmp, TasksFile);
end;

procedure SetTaskRecordRemoved(id: longint; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.removed := not tmp.removed;
    SetTaskRecord(tmp, TasksFile);
end;

procedure SetTaskRecordGreen(id: longint; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.green := not tmp.green;
    SetTaskRecord(tmp, TasksFile);
end;

procedure AddTaskRecord(var name: string; var TasksFile: FileOfTask);
var
    tmp: TTask;
    date: longint;
begin
    date := DateTimeToTimeStamp(now).date; 
    tmp.id := TaskRecordCount(TasksFile) + 1;
    tmp.name := name;
    tmp.done := false;
    tmp.removed := false;
    tmp.green := false;
    tmp.ProjectId := 0;
    tmp.RepeatInterval := 0;
    tmp.LastRepeat := 0;
    tmp.CreationDate := date;
    SetTaskRecord(tmp, TasksFile);
    SetTaskRecordCount(tmp.id, TasksFile);
end;

end.
