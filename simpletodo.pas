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
    writeln('rm [TaskNumber] - remove task from current list');
    writeln('n [TaskNumber] [name] - rename task from current list');
    writeln('rd [TaskNumber] [Day] - set task to repeat ',
        'on the day of week (1 - Monday, 2 - Tuesday, etc.)');
    writeln('ri [TaskNumber] [interval] [StartDay] - set task to repeat ',
        'with interval starting from (1 - Monday, 2 - Tuesday, etc.)');
    writeln('mv [TaskNumber] [t/w/n/ProjectId] - move task from current ',
        'list to (today/week/none/project)');
    writeln('g [TaskNumber] - set task green form current list');
    writeln('s [TaskNumber] - set task done from current list');
    PrintLine(TitleLineSize, true);
    writeln('pl - projects list');
    writeln('a [name] - add project to current list');
    writeln('rm [ProjectNumber] - remove project from current list');
    PrintLine(TitleLineSize, true);
end;

procedure PrintTask(number: integer; var task: TTask);
var
    TaskDays, today: longint;
    NextRepeat: TTimeStamp;
begin
    today := DateTimeToTimeStamp(now).date;
    TaskDays := today - task.CreationDate;
    write(number, '. '); 
    if task.green then
        PrintGreenText(task.name)
    else
        write(task.name);
    write(' | TaskDays: ', TaskDays);
    if task.repeating then
    begin
        if task.NextRepeat > today then
        begin
            NextRepeat.date := task.NextRepeat; 
            write(' | Next repeat ',
                DateToStr(TimeStampToDateTime(NextRepeat)));
        end
        else
            write(' | Repeating ');
    end;
    writeln
end;


procedure PrintProject(number: longint; var name: string);
begin
    writeln(number, '. ', name);
end;

procedure GetTaskByNumber(TaskNumber: longint; var list: TaskList; 
    var task: TTask; var found: boolean);
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
            task := tmp^.task;
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
    number: longint;
    task: TTask;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    DoneTask(task.id);
end;

procedure RepeatIntervalTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, NextRepeat, CurDate: longint;
    interval: integer;
    StartDay, today: word;
    found: boolean;
    task: TTask;
begin
    if ParamsCount < 3 then
        exit;
    today := (DayOfWeek(Date) - 2) mod 7 + 1;
    if ParamsCount < 4 then
        StartDay := today
    else
        StartDay := (StrToInt(params[4]) - 1) mod 7 + 1;
    CurDate := DateTimeToTimeStamp(Date).date; 
    number := StrToInt(params[2]); 
    interval := StrToInt(params[3]);
    if StartDay < today then
        NextRepeat := CurDate + (7 - today) + StartDay
    else
        NextRepeat := CurDate + (StartDay - today);
    GetTaskByNumber(number, list, task, found);
    if (not found) or (interval <= 0) then
    begin
        SetTaskRepeat(task.id, false, 0, 0, 0);
        exit;
    end;
    SetTaskRepeat(task.id, true, interval, NextRepeat, 0);
end;

function NextRepeatDate(RepeatDays: word): longint;
var
    day, interval, today: word;
    res: longint;
begin
    today := (DayOfWeek(Date) - 2) mod 7 + 1;
    interval := 8;
    for day:=1 to 7 do
    begin
        if (RepeatDays and (1 shl (day - 1))) <> 0 then
        begin
            if (today > day) and (((7 - today) + day) < interval) then
                interval := ((7 - today) + day)
            else if (today <= day) and ((day - today) < interval) then
                interval := (day - today);
        end;
    end;
    NextRepeatDate := DateTimeToTimeStamp(Date).date + interval; 
end;

procedure RepeatDaysTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, NextRepeat, CurDate: longint;
    day, today: word;
    task: TTask;
    found: boolean;
begin
    if ParamsCount < 3 then
        exit;
    CurDate := DateTimeToTimeStamp(Date).date; 
    number := StrToInt(params[2]); 
    day := (StrToInt(params[3]) - 1) mod 7 + 1;
    GetTaskByNumber(number, list, task, found);
    task.RepeatDays := task.RepeatDays xor (1 shl (day - 1));
    if (not found) or (task.RepeatDays = 0) then
    begin
        SetTaskRepeat(task.id, false, 0, 0, 0);
        exit;
    end;
    NextRepeat := NextRepeatDate(task.RepeatDays); 
    SetTaskRepeat(task.id, true, 0, NextRepeat, task.RepeatDays);
end;

procedure SetTaskGreenCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number: longint;
    task: TTask;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    SetTaskGreen(task.id);
end;

procedure RenameTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, TaskId: longint;
    task: TTask;
    found: boolean;
    name: string;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    name := ConcatParams(params, ParamsCount, 3);
    SetTaskName(task.id, name);
end;

procedure MoveTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var tasks: TaskList; var projects: ProjectList);
var
    number, ProjectNumber: longint;
    found: boolean;
    project: TProject;
    task: TTask;
    folder: FolderType;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, tasks, task, found);
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
            SetTaskProject(task.id, 0)  
        else 
            SetTaskProject(task.id, project.id);
    end
    else
        SetTaskFolder(task.id, folder);
end;

procedure RemoveTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number: longint;
    task: TTask;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    RemoveTask(task.id);
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
                else if params[1] = 'rm' then
                    RemoveTaskCmd(params, ParamsCount, tasks)
                else if params[1] = 'd' then
                    DoneTaskCmd(params, ParamsCount, tasks)
                else if params[1] = 'g' then
                    SetTaskGreenCmd(params, ParamsCount, tasks)
                else if params[1] = 'mv' then
                    MoveTaskCmd(params, ParamsCount, tasks, projects)
                else if params[1] = 'n' then
                    RenameTaskCmd(params, ParamsCount, tasks)
                else if params[1] = 'rd' then
                    RepeatDaysTaskCmd(params, ParamsCount, tasks)
                else if params[1] = 'ri' then
                    RepeatIntervalTaskCmd(params, ParamsCount, tasks)
            end;
            SProjects: begin
                if params[1] = 'a' then
                    AddProjectCmd(params, ParamsCount)
                else if params[1] = 'rm' then
                    RemoveProjectCmd(params, ParamsCount)
            end;
        end;
    end;
end.
