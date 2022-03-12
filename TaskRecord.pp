unit TaskRecord;

interface
type
    FolderType = (FNone, FToday, FWeek);
    TTask = record
        id, ProjectId, NextRepeat, CreationDate, days: longint;
        RepeatInterval: integer;
        RepeatDays: word;
        name, description: string;
        folder: FolderType;
        done, removed, green, repeating: boolean;
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
procedure SetTaskRecordDescription(id: longint; var description: string; 
    var TasksFile: FileOfTask);
procedure SetTaskRecordProject(id: longint; var ProjectId: longint;
        var TasksFile: FileOfTask);
procedure SetTaskRecordRepeat(id: longint; repeating: boolean;
    interval: integer; NextRepeat: longint; RepeatDays: word;
    var TasksFile: FileOfTask);
procedure SetTaskRecordDone(id: longint; var TasksFile: FileOfTask);
procedure SetTaskRecordRemoved(id: longint; var TasksFile: FileOfTask);
procedure SetTaskRecordGreen(id: longint; var TasksFile: FileOfTask);
procedure AddTaskRecord(var name: string; var TasksFile: FileOfTask);
procedure AddTaskRecordCopy(var task: TTask; var TasksFile: FileOfTask);

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

procedure SetTaskRecordDescription(id: longint; var description: string; 
    var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.description := description;
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

procedure SetTaskRecordRepeat(id: longint; repeating: boolean;
    interval: integer; NextRepeat: longint; RepeatDays: word; 
    var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.repeating := repeating;
    tmp.RepeatInterval := interval;
    tmp.NextRepeat := NextRepeat;
    tmp.CreationDate := NextRepeat;
    tmp.RepeatDays := RepeatDays;
    SetTaskRecord(tmp, TasksFile);
end;

procedure SetTaskRecordRepeatDays(id: longint; repeating: boolean;
    RepeatDays: word; NextRepeat: longint; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    GetTaskRecord(id, tmp, TasksFile); 
    tmp.repeating := repeating;
    tmp.RepeatInterval := 0;
    tmp.NextRepeat := 0;
    tmp.RepeatDays := RepeatDays;
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
    tmp.description := '';
    tmp.done := false;
    tmp.removed := false;
    tmp.repeating := false;
    tmp.green := false;
    tmp.ProjectId := 0;
    tmp.RepeatInterval := 0;
    tmp.days := 0;
    tmp.NextRepeat := 0;
    tmp.RepeatDays := 0;
    tmp.CreationDate := date;
    SetTaskRecord(tmp, TasksFile);
    SetTaskRecordCount(tmp.id, TasksFile);
end;

procedure AddTaskRecordCopy(var task: TTask; var TasksFile: FileOfTask);
var
    tmp: TTask;
begin
    tmp.id := TaskRecordCount(TasksFile) + 1;
    tmp.name := task.name;
    tmp.description := task.description;
    tmp.done := task.done;
    tmp.removed := task.removed;
    tmp.repeating := task.repeating;
    tmp.green := task.green;
    tmp.ProjectId := task.ProjectId;
    tmp.RepeatInterval := task.RepeatInterval;
    tmp.days := task.days;
    tmp.NextRepeat := task.NextRepeat;
    tmp.RepeatDays := task.RepeatDays;
    tmp.CreationDate := task.NextRepeat;
    SetTaskRecord(tmp, TasksFile);
    SetTaskRecordCount(tmp.id, TasksFile);
end;

end.
