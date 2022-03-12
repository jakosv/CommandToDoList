unit database;

interface
uses TaskRecord, ProjectRecord, ListOfTasks, ListOfProjects;

procedure InitDatabase(TasksFilename, ProjectsFilename: string);
procedure AddTask(var name: string);
procedure DoneTask(id: longint);
procedure SetTaskFolder(id: longint; folder: FolderType);
procedure SetTaskProject(id, ProjectId: longint);
procedure SetTaskGreen(id: longint);
procedure SetTaskName(id: longint; var NewName: string);
procedure SetTaskRepeat(id: longint; repeating: boolean;
    interval: integer; NextRepeat: longint; RepeatDays: word);
procedure RemoveTask(id: longint);
procedure AddProject(var name: string);
procedure RemoveProject(id: longint);
function FetchTasks: TaskList;
function FetchProjectTasks(ProjectId: longint): TaskList;
function FetchProjects: ProjectList;

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

procedure SetTaskRepeat(id: longint; repeating: boolean;
    interval: integer; NextRepeat: longint; RepeatDays: word);
begin
    reset(TasksFile);
    SetTaskRecordRepeat(id, repeating, interval, NextRepeat, RepeatDays, 
        TasksFile);
    close(TasksFile);
end;

procedure RemoveProject(id: longint);
begin
    reset(ProjectsFile);
    SetProjectRecordRemoved(id, ProjectsFile);
    close(ProjectsFile);
end;

function FetchTasks: TaskList;
var
    list: TaskList;
    TempTask: TTask;
    i, cnt: longint;
begin
    reset(TasksFile);
    TaskListInit(list);
    cnt := TaskRecordCount(TasksFile);
    seek(TasksFile, 1);
    for i:=1 to cnt do
    begin
        read(TasksFile, TempTask);
        if TempTask.removed or TempTask.done then
            continue;
        TaskListAdd(list, TempTask);
    end;
    close(TasksFile);
    FetchTasks := list;
end;

function FetchProjectTasks(ProjectId: longint): TaskList;
var
    list: TaskList;
    TempTask: TTask;
    i, cnt: longint;
begin
    reset(TasksFile);
    TaskListInit(list);
    cnt := TaskRecordCount(TasksFile);
    seek(TasksFile, 1);
    for i:=1 to cnt do
    begin
        read(TasksFile, TempTask);
        if (not TempTask.removed) and (not TempTask.done) and 
            (TempTask.ProjectId = ProjectId) 
        then
        begin
            TaskListAdd(list, TempTask);
        end;
    end;
    close(TasksFile);
    FetchProjectTasks := list;
end;

function FetchProjects: ProjectList;
var
    list: ProjectList;
    TempProject: TProject;
    i, cnt: longint;
begin
    reset(ProjectsFile);
    ProjectListInit(list);
    cnt := ProjectRecordCount(ProjectsFile);
    seek(ProjectsFile, 1);
    for i:=1 to cnt do
    begin
        read(ProjectsFile, TempProject);
        if TempProject.removed then
            continue;
        ProjectListAdd(list, TempProject);
    end;
    close(ProjectsFile);
    FetchProjects := list;
end;

end.
