program SimpleToDoList;
uses sysutils, ListOfTasks, ListOfProjects, database, TaskRecord,
    ProjectRecord;

const
    TasksFilename = '.tasks';
    ProjectsFilename = '.projects';
    MaxParamsCount = 255;
    TitleLineSize = 80;
    TitleLineSymbol = '=';

type
    ParamsArray = array[1..MaxParamsCount] of string;
    ScreenType = (STasks, SProjects, SProjectTasks, SToday, SWeek, SDoneTasks,
        SRemovedTasks, SRemovedProjects, SHelp);

procedure ParseCmd(var str: string; var params: ParamsArray;
    var ParamsCount: integer);
var
    i: integer;
    CurrentParam: string;
begin
    ParamsCount := 0;
    CurrentParam := '';
    str := str + ' ';
    for i:=1 to length(str) do
    begin
        if ((str[i] = ' ') and (length(CurrentParam) > 0)) then
        begin
            ParamsCount := ParamsCount + 1;
            params[ParamsCount] := CurrentParam;
            CurrentParam := '';
        end
        else
            CurrentParam := CurrentParam + str[i];
    end;
end;

function ConcatParams(var params: ParamsArray; ParamsCount, StartPos: integer): string;
var
    res: string;
    i: integer;
begin
    res := '';
    for i:=StartPos to ParamsCount do
    begin
        res := res + params[i];
        if i <> ParamsCount then
            res := res + ' ';
    end;
    ConcatParams := res;
end;

function IsNumber(var str: string): boolean;
var
    i: integer;
begin
    for i:=1 to length(str) do
        if (str[i] < '0') or (str[i] > '9') then
        begin
            IsNumber := false;
            exit;
        end;
    IsNumber := true;
end;


procedure PrintGreenText(var str: string);
begin
    write(#27'[1;32m');
    write(str);
    write(#27'[0m');
end;

procedure PrintLine(size: integer; ReturnLine: boolean);
var
    i: integer;
begin
    for i:=1 to size do
        write(TitleLineSymbol);
    if ReturnLine then
        writeln;
end;

procedure PrintTitleLine(title: string);
var
    LineSize, i: integer;
begin
    LineSize := (TitleLineSize - length(title) - 2) div 2;
    PrintLine(LineSize, false);
    write(' ', title, ' ');
    PrintLine(TitleLineSize - (LineSize + length(title) + 2), false);
    writeln;
end;

procedure help;
begin
    PrintTitleLine('Help');
    writeln('tl - tasks list');
    writeln('p [ProjectNumber] - project tasks list');
    writeln('a [name] - add task to current list');
    writeln('r [TaskNumber] - remove task from current list');
    writeln('n [TaskNumber] [name] - rename task from current list');
    writeln('m [TaskNumber] [t/w/n/ProjectId] - move task from current ',
        'list to (today/week/none/project)');
    writeln('g [TaskNumber] - set task green form current list');
    writeln('s [TaskNumber] - set task done from current list');
    PrintLine(TitleLineSize, true);
    writeln('pl - projects list');
    writeln('a [name] - add project to current list');
    writeln('r [ProjectNumber] - remove project from current list');
    PrintLine(TitleLineSize, true);
end;

procedure PrintTask(number: integer; var task: TTask);
var
    TaskDays, today: longint;
begin
    today := DateTimeToTimeStamp(now).date;
    TaskDays := today - task.CreationDate;
    write(number, '. '); 
    if task.green then
        PrintGreenText(task.name)
    else
        write(task.name);
    writeln(' | TaskDays: ', TaskDays);
end;


procedure PrintProject(number: longint; var name: string);
begin
    writeln(number, '. ', name);
end;

procedure GetTaskId(TaskNumber: longint; var list: TaskList; var id: longint;
    var found: boolean);
var
    tmp: TaskList;
    number: longint;
begin
    tmp := list;
    number := 1;
    found := false;
    while tmp <> nil do
    begin
        if number = TaskNumber then
        begin
            found := true;
            id := tmp^.task.id;
            exit;
        end;
        number := number + 1;
        tmp := tmp^.next;
    end;
end;

procedure UpdateTaskList(var list: TaskList; NewTaskList: TaskList);
begin
    TaskListClear(list);
    list := NewTaskList;
end;

procedure UpdateProjectList(var list: ProjectList);
begin
    ProjectListClear(list);
    list := FetchProjects;
end;

procedure GetProjectByNumber(ProjectNumber: longint; var list: ProjectList; 
    var Project: TProject; var found: boolean);
var
    tmp: ProjectList;
    number: longint;
begin
    tmp := list;
    number := 1;
    found := false;
    while tmp <> nil do
    begin
        if number = ProjectNumber then
        begin
            found := true;
            project := tmp^.project;
            exit;
        end;
        number := number + 1;
        tmp := tmp^.next;
    end;
end;

procedure ShowTasks(list: TaskList; title: string);
var
    ProjectName: string;
    number: longint;
begin
    writeln;
    PrintTitleLine(title);
    number := 1;
    while list <> nil do
    begin
        PrintTask(number, list^.task);
        number := number + 1;
        list := list^.next;
    end;
    PrintLine(TitleLineSize, true);
    writeln;
end;

procedure AddTaskCmd(var params: ParamsArray; ParamsCount: integer);
var
    name: string;
begin
    if ParamsCount < 2 then
        exit;
    name := ConcatParams(params, ParamsCount, 2);
    AddTask(name);
end;

procedure DoneTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, TaskId: longint;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskId(number, list, TaskId, found);
    if not found then
        exit;
    DoneTask(TaskId);
end;

procedure SetTaskGreenCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, TaskId: longint;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskId(number, list, TaskId, found);
    if not found then
        exit;
    SetTaskGreen(TaskId);
end;

procedure RenameTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, TaskId: longint;
    found: boolean;
    name: string;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskId(number, list, TaskId, found);
    if not found then
        exit;
    name := ConcatParams(params, ParamsCount, 3);
    SetTaskName(TaskId, name);
end;

procedure MoveTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var tasks: TaskList; var projects: ProjectList);
var
    number, TaskId, ProjectNumber: longint;
    found: boolean;
    project: TProject;
    folder: FolderType;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskId(number, tasks, TaskId, found);
    if not found then
        exit;
    if (params[3] = 't') or (params[3] = 'today') then
        folder := FToday
    else if (params[3] = 'w') or (params[3] = 'week') then
        folder := FWeek
    else if (params[3] = 'n') or (params[3] = 'none') then
        folder := FNone;
    if IsNumber(params[3]) then
    begin
        ProjectNumber := StrToInt(params[3]);
        GetProjectByNumber(ProjectNumber, projects, project, found);
        if not found then
            SetTaskProject(TaskId, 0)  
        else 
            SetTaskProject(TaskId, project.id);
    end
    else
        SetTaskFolder(TaskId, folder);
end;

procedure RemoveTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, TaskId: longint;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskId(number, list, TaskId, found);
    if not found then
        exit;
    RemoveTask(TaskId);
end;

procedure ShowProjectTasks(var params: ParamsArray; ParamsCount: integer;
    var tasks: TaskList; var projects: ProjectList);
var
    project: TProject;
    number: longint;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]);
    GetProjectByNumber(number, projects, project, found);
    if not found then
        exit;
    tasks := FetchProjectTasks(project.id);
    PrintProject(number, project.name);
    ShowTasks(tasks, 'Project Tasks');
end;

procedure ShowProjects(list: ProjectList; title: string);
var
    number: longint;
begin
    writeln;
    PrintTitleLine(title);
    number := 1;
    while list <> nil do
    begin
        PrintProject(number, list^.project.name);
        number := number + 1;
        list := list^.next;
    end;
    PrintLine(TitleLineSize, true);
    writeln;
end;

procedure AddProjectCmd(var params: ParamsArray; ParamsCount: integer);
var
    name: string;
    list: ProjectList;
begin
    if ParamsCount < 2 then
        exit;
    list := FetchProjects;
    name := ConcatParams(params, ParamsCount, 2);
    AddProject(name);
    ProjectListClear(list);
end;

procedure RemoveProjectCmd(var params: ParamsArray; ParamsCount: integer);
var
    number, ProjectId: longint;
    project: TProject;
    list: ProjectList;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    list := FetchProjects;
    GetProjectByNumber(number, list, project, found);
    if not found then
        exit;
    RemoveProject(project.id);
    ProjectListClear(list);
end;

var
    params: ParamsArray;
    cmd: string;
    ParamsCount: integer;
    CurrentScreen: ScreenType;
    tasks: TaskList;
    projects: ProjectList;
begin
    InitDatabase(TasksFilename, ProjectsFilename);
    CurrentScreen := STasks;
    ParamsCount := 0;
    tasks := nil;
    projects := nil;
    while true do
    begin
        case CurrentScreen of
            STasks: begin
                tasks := FetchTasks;
                ShowTasks(tasks, 'Tasks');
            end;
            SProjectTasks: begin
                ShowProjectTasks(params, ParamsCount, tasks, projects);
            end;
            SProjects: begin
                projects := FetchProjects;
                ShowProjects(projects, 'Projects');
            end;
            SHelp:
                help;
        end;
        write('(cmd) ');
        readln(cmd);
        ParseCmd(cmd, params, ParamsCount);
        if ParamsCount < 1 then
            continue
        else if params[1] = 'tl' then 
        begin
            CurrentScreen := STasks;
            continue;
        end
        else if params[1] = 'p' then 
        begin
            CurrentScreen := SProjectTasks;
            continue;
        end
        else if params[1] = 'pl' then 
        begin
            CurrentScreen := SProjects;
            continue;
        end
        else if (params[1] = 'h') or (params[1] = 'help') then
            CurrentScreen := SHelp
        else if params[1] = 'q' then
            break;

        case CurrentScreen of
            STasks, SProjectTasks: begin
                if params[1] = 'a' then
                begin
                    AddTaskCmd(params, ParamsCount);
                    CurrentScreen := STasks;
                end
                else if params[1] = 'r' then
                    RemoveTaskCmd(params, ParamsCount, tasks)
                else if params[1] = 'd' then
                    DoneTaskCmd(params, ParamsCount, tasks)
                else if params[1] = 'g' then
                    SetTaskGreenCmd(params, ParamsCount, tasks)
                else if params[1] = 'm' then
                    MoveTaskCmd(params, ParamsCount, tasks, projects)
                else if params[1] = 'n' then
                    RenameTaskCmd(params, ParamsCount, tasks)
            end;
            SProjects: begin
                if params[1] = 'a' then
                    AddProjectCmd(params, ParamsCount)
                else if params[1] = 'r' then
                    RemoveProjectCmd(params, ParamsCount)
            end;
        end;
    end;
end.
