unit database;

interface
uses TaskRecord, ProjectRecord, ListOfTasks, ListOfProjects;

procedure InitDatabase(TasksFilename, ProjectsFilename: string);
procedure AddTask(var name: string);
procedure AddTaskCopy(var task: TTask);
procedure DoneTask(id: longint);
procedure SetTaskFolder(id: longint; folder: FolderType);
procedure SetTaskProject(id, ProjectId: longint);
procedure SetTaskGreen(id: longint);
procedure SetTaskName(id: longint; var NewName: string);
procedure SetTaskDescription(id: longint; var description: string);
procedure SetTaskRepeat(id: longint; repeating: boolean;
    interval: integer; NextRepeat: longint; RepeatDays: word);
procedure RemoveTask(id: longint);
procedure AddProject(var name: string);
procedure SetProjectName(id: longint; var NewName: string);
procedure SetProjectDescription(id: longint; var description: string);
procedure RemoveProject(id: longint);
function FetchTasks(ProjectId: longint; folder: FolderType; 
    done, removed: boolean): TaskList;
function FetchProjects(removed: boolean): ProjectList;

implementation
uses sysutils;
var
    TasksFile: FileOfTask;
    ProjectsFile: FileOfProject;

procedure InitDatabase(TasksFilename, ProjectsFilename: string);
var
    InfoTaskRecord: TTask;
    InfoProjectRecord: TProject;
begin
    {$I-}
    assign(TasksFile, TasksFilename);
    reset(TasksFile);
    if IOResult <> 0 then
    begin
        rewrite(TasksFile);
        InfoTaskRecord.name := 'Records information';
        InfoTaskRecord.id := 0;
        write(TasksFile, InfoTaskRecord);
    end;
    close(TasksFile);
    assign(ProjectsFile, ProjectsFilename);
    reset(ProjectsFile);
    if IOResult <> 0 then
    begin
        rewrite(ProjectsFile);
        InfoProjectRecord.name := 'Records information';
        InfoProjectRecord.id := 0;
        write(ProjectsFile, InfoProjectRecord);
    end;
    close(ProjectsFile);
end;

procedure AddTask(var name: string);
begin
    reset(TasksFile);
    AddTaskRecord(name, TasksFile);
    close(TasksFile);
end;

procedure AddTaskCopy(var task: TTask);
begin
    reset(TasksFile);
    AddTaskRecordCopy(task, TasksFile);
    close(TasksFile);
end;

procedure AddProject(var name: string);
begin
    reset(ProjectsFile);
    AddProjectRecord(name, ProjectsFile);
    close(ProjectsFile);
end;

procedure RemoveTask(id: longint);
begin
    reset(TasksFile);
    SetTaskRecordRemoved(id, TasksFile);
    close(TasksFile);
end;

procedure DoneTask(id: longint);
begin
    reset(TasksFile);
    SetTaskRecordDone(id, TasksFile);
    close(TasksFile);
end;

procedure SetTaskFolder(id: longint; folder: FolderType);
begin
    reset(TasksFile);
    SetTaskRecordFolder(id, folder, TasksFile);
    close(TasksFile);
end;

procedure SetTaskProject(id, ProjectId: longint);
begin
    reset(TasksFile);
    SetTaskRecordProject(id, ProjectId, TasksFile);
    close(TasksFile);
end;

procedure SetTaskGreen(id: longint);
begin
    reset(TasksFile);
    SetTaskRecordGreen(id, TasksFile);
    close(TasksFile);
end;

procedure SetTaskName(id: longint; var NewName: string);
begin
    reset(TasksFile);
    SetTaskRecordName(id, NewName, TasksFile);
    close(TasksFile);
end;

procedure SetTaskDescription(id: longint; var description: string);
begin
    reset(TasksFile);
    SetTaskRecordDescription(id, description, TasksFile);
    close(TasksFile);
end;

procedure SetTaskRepeat(id: longint; repeating: boolean;
    interval: integer; NextRepeat: longint; RepeatDays: word);
begin
    reset(TasksFile);
    SetTaskRecordRepeat(id, repeating, interval, NextRepeat, RepeatDays, 
        TasksFile);
    close(TasksFile);
end;

procedure SetProjectName(id: longint; var NewName: string);
begin
    reset(ProjectsFile);
    SetProjectRecordName(id, NewName, ProjectsFile);
    close(ProjectsFile);
end;

procedure SetProjectDescription(id: longint; var description: string);
begin
    reset(ProjectsFile);
    SetProjectRecordDescription(id, description, ProjectsFile);
    close(ProjectsFile);
end;

procedure RemoveProject(id: longint);
begin
    reset(ProjectsFile);
    SetProjectRecordRemoved(id, ProjectsFile);
    close(ProjectsFile);
end;

function IsTaskToday(var task: TTask; folder: FolderType): boolean;
var
    CurDate: longint;
begin
    CurDate := DateTimeToTimeStamp(Date).date;
    IsTaskToday := ((folder = FToday) and ((task.folder = folder) or
        (task.repeating and (task.NextRepeat <= CurDate))));
end;

function IsTaskOnWeek(var task: TTask; folder: FolderType): boolean;
var
    CurDate: longint;
begin
    CurDate := DateTimeToTimeStamp(Date).date;
    IsTaskOnWeek := ((folder = FWeek) and 
        ((task.folder = FWeek) or 
        (task.folder = FToday) or 
        (task.repeating and (task.NextRepeat <= (CurDate + 6)))));
end;

function RelevantTask(var task: TTask; ProjectId: longint; folder: FolderType;
    done, removed: boolean): boolean;
var
    AllFolders, AllProjects: boolean;
begin
    AllFolders := (folder = FNone);
    AllProjects := (ProjectId = 0);
    RelevantTask := (task.removed = removed) and 
                    (task.done = done) and
                    (AllFolders or IsTaskToday(task, folder) or
                        IsTaskOnWeek(task, folder)) and 
                    (AllProjects or (task.ProjectId = ProjectId));
end;

function FetchTasks(ProjectId: longint; folder: FolderType;
    done, removed: boolean): TaskList;
var
    list: TaskList;
    task: TTask;
    i, cnt: longint;
begin
    reset(TasksFile);
    TaskListInit(list);
    cnt := TaskRecordCount(TasksFile);
    seek(TasksFile, 1);
    for i:=1 to cnt do
    begin
        read(TasksFile, task);
        if RelevantTask(task, ProjectId, folder, done, removed) then
            TaskListAdd(list, task);
    end;
    close(TasksFile);
    FetchTasks := list;
end;

function FetchProjects(removed: boolean): ProjectList;
var
    list: ProjectList;
    project: TProject;
    i, cnt: longint;
begin
    reset(ProjectsFile);
    ProjectListInit(list);
    cnt := ProjectRecordCount(ProjectsFile);
    seek(ProjectsFile, 1);
    for i:=1 to cnt do
    begin
        read(ProjectsFile, project);
        if project.removed = removed then
            ProjectListAdd(list, project);
    end;
    close(ProjectsFile);
    FetchProjects := list;
end;

end.
