program CommandToDoList;
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
    ScreenType = (STasks, SProjects, SProjectTasks, SProjectDoneTasks, SToday, 
        SWeek, SDoneTasks, SRemovedTasks, SRemovedProjects, SHelp);

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
    LineSize: integer;
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
    writeln('t - today tasks list');
    writeln('w - week tasks list');
    writeln('dl - done tasks list');
    writeln('rmtasks - removed tasks list');
    writeln('p [ProjectNumber] - project tasks list');
    writeln('a [name] - add task to current list');
    writeln('rm [TaskNumber] - remove task from current list');
    writeln('i [TaskNumber] - show task info');
    writeln('n [TaskNumber] [name] - rename task from current list');
    writeln('ds [TaskNumber] [description] - change task description');
    writeln('rd [TaskNumber] [Day] - set task to repeat ',
        'on the day of week (1 - Monday, 2 - Tuesday, etc.)');
    writeln('ri [TaskNumber] [interval] [StartDay] - set task to repeat ',
        'with interval starting from (1 - Monday, 2 - Tuesday, etc.)');
    writeln('mv [TaskNumber] [t/w/n/ProjectId] - move task from current ',
        'list to (today/week/none/project)');
    writeln('g [TaskNumber] - set task green form current list');
    writeln('d [TaskNumber] - set task done from current list');
    PrintLine(TitleLineSize, true);
    writeln('pl - projects list');
    writeln('rmprojects - removed projects list');
    writeln('a [name] - add project to current list');
    writeln('n [ProjectNumber] [name] - change project name');
    writeln('ds [ProjectNumber] [description] - change project description');
    writeln('rm [ProjectNumber] - remove project from current list');
    writeln('i [ProjectNumber] - show project info');
    PrintLine(TitleLineSize, true);
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

procedure GetTaskProjectName(ProjectId: longint; var name: string;
    var found: boolean; projects: ProjectList);
var
    list: ProjectList;
begin
    list := projects;
    found := false;
    while list <> nil do
    begin
        if list^.project.id = ProjectId then
        begin
            name := list^.project.name; 
            found := true;
            exit;
        end;
        list := list^.next;
    end;
end;

procedure ShowTaskInfo(var params: ParamsArray; ParamsCount: integer;
    tasks: TaskList);
var
    ProjectName: string;
    FoundProject, FoundTask: boolean;
    day, number: integer;
    TaskDays, today: longint;
    NextRepeat: TTimeStamp;
    task: TTask;
    projects: ProjectList;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]);
    GetTaskByNumber(number, tasks, task, FoundTask);
    if not FoundTask then
        exit;
    today := DateTimeToTimeStamp(now).date;
    TaskDays := today - task.CreationDate;
    projects := FetchProjects(false);
    GetTaskProjectName(task.ProjectId, ProjectName, FoundProject, projects);
    PrintTitleLine('Task Info');
    write('- '); 
    if task.green then
        PrintGreenText(task.name)
    else
        write(task.name);
    writeln;
    if task.description <> '' then
        writeln('- ', task.description);
    if task.folder = FToday then
        writeln('- List: Today'); 
    if task.folder = FWeek then
        writeln('- List: Week'); 
    if FoundProject then
        writeln('- Project: ', ProjectName);
    if task.repeating then
    begin
        if task.RepeatInterval <> 0 then
            writeln('- Repeat interval: ', task.RepeatInterval)
        else if task.RepeatDays <> 0 then
        begin
            write('- Repeat days: ');
            for day:=1 to 7 do
                if (task.RepeatDays and (1 shl (day - 1))) <> 0 then
                    write(LongDayNames[day mod 7 + 1], ' ');
            writeln;
        end;
        if task.NextRepeat > today then
        begin
            NextRepeat.date := task.NextRepeat; 
            writeln('- Next repeat: ',
                DateToStr(TimeStampToDateTime(NextRepeat)));
        end
        else
            writeln('- TaskDays: ', TaskDays);
    end
    else
        writeln('- TaskDays: ', TaskDays);
    PrintLine(TitleLineSize, true);
    writeln;
end;

procedure PrintTodayTask(number: integer; var task: TTask);
begin
    write(number, '. '); 
    if task.green then
        PrintGreenText(task.name)
    else
        write(task.name);
end;

procedure PrintTask(number: integer; var task: TTask);
var
    TaskDays, today: longint;
    NextRepeat: TTimeStamp;
begin
    today := DateTimeToTimeStamp(now).date;
    TaskDays := today - task.CreationDate;
    PrintTodayTask(number, task);
    if (task.folder = FToday) or 
        (task.repeating and (task.NextRepeat <= today))
        then
        write(' | Today')
    else if (task.folder = FWeek) or 
        (task.repeating and (task.NextRepeat <= (today + 6)))
        then
        write(' | Week');
    if task.repeating then
    begin
        if task.NextRepeat > today then
        begin
            NextRepeat.date := task.NextRepeat; 
            write(' | Next repeat: ',
                DateToStr(TimeStampToDateTime(NextRepeat)));
        end
        else
            write(' | TaskDays: ', TaskDays, ' | Repeating ');
    end
    else
        write(' | TaskDays: ', TaskDays);
end;


procedure PrintWeekTask(number: integer; var task: TTask);
var
    today: longint;
    NextRepeat: TTimeStamp;
begin
    today := DateTimeToTimeStamp(now).date;
    PrintTodayTask(number, task);
    if (task.folder = FToday) or 
        (task.repeating and (task.NextRepeat <= today))
        then
        write(' | Today');
    if task.repeating then
    begin
        if task.NextRepeat > today then
        begin
            NextRepeat.date := task.NextRepeat; 
            write(' | Next repeat: ',
                DateToStr(TimeStampToDateTime(NextRepeat)));
        end
        else
            write(' | Repeating ');
    end;
end;


procedure PrintProject(number: longint; var name: string);
begin
    writeln(number, '. ', name);
end;

procedure UpdateTaskList(var list: TaskList; NewTaskList: TaskList);
begin
    TaskListClear(list);
    list := NewTaskList;
end;

procedure UpdateProjectList(var list: ProjectList);
begin
    ProjectListClear(list);
    list := FetchProjects(false);
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

procedure ShowTasks(list: TaskList; title: string; screen: ScreenType);
var
    number: longint;
begin
    PrintTitleLine(title);
    number := 1;
    while list <> nil do
    begin
        if screen = SToday then
            PrintTodayTask(number, list^.task)
        else if screen = SWeek then
            PrintWeekTask(number, list^.task)
        else
            PrintTask(number, list^.task);
        writeln;
        number := number + 1;
        list := list^.next;
    end;
    PrintLine(TitleLineSize, true);
    writeln;
end;

function NextRepeatDate(day, RepeatDays: word): longint;
var
    WeekDay, interval, today: word;
begin
    today := (DayOfWeek(Date) - 2 + 7) mod 7 + 1;
    interval := 8;
    for WeekDay:=1 to 7 do
    begin
        if (RepeatDays and (1 shl (WeekDay - 1))) <> 0 then
        begin
            if (day > WeekDay) and (((7 - day) + WeekDay) < interval) then
                interval := ((7 - day) + WeekDay)
            else if (day <= WeekDay) and ((WeekDay - day) < interval) then
                interval := (WeekDay - day);
        end;
    end;
    NextRepeatDate := DateTimeToTimeStamp(Date).date + (day - today) + interval; 
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
    number, CurDate: longint;
    task: TTask;
    day: word;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    if task.repeating then
    begin
        if task.RepeatInterval <> 0 then
        begin
            CurDate := DateTimeToTimeStamp(Date).date;
            task.NextRepeat := CurDate + task.RepeatInterval;
        end
        else
        begin
            day := DayOfWeek(Date);
            task.NextRepeat := NextRepeatDate(day, task.RepeatDays);
        end;
        AddTaskCopy(task);
    end;
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
    today := (DayOfWeek(Date) - 2 + 7) mod 7 + 1;
    if ParamsCount < 4 then
        StartDay := today
    else
        StartDay := StrToInt(params[4]);
    if (StartDay < 1) or (StartDay > 7) then
        exit;
    CurDate := DateTimeToTimeStamp(Date).date; 
    number := StrToInt(params[2]); 
    interval := StrToInt(params[3]);
    writeln(today);
    if StartDay < today then
        NextRepeat := CurDate + (7 - today) + StartDay
    else
        NextRepeat := CurDate + (StartDay - today);
    GetTaskByNumber(number, list, task, found);
    if (not found) or (interval <= 0) then
    begin
        SetTaskRepeat(task.id, false, 0, CurDate, 0);
        exit;
    end;
    SetTaskRepeat(task.id, true, interval, NextRepeat, 0);
end;

procedure RepeatDaysTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, CurDate: longint;
    day, today: word;
    task: TTask;
    found: boolean;
begin
    if ParamsCount < 3 then
        exit;
    CurDate := DateTimeToTimeStamp(Date).date; 
    number := StrToInt(params[2]); 
    day := StrToInt(params[3]);
    if (day < 1) or (day > 7) then
        exit;
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    task.RepeatDays := task.RepeatDays xor (1 shl (day - 1));
    if task.RepeatDays = 0 then
    begin
        SetTaskRepeat(task.id, false, 0, CurDate, 0);
        exit;
    end;
    today := (DayOfWeek(Date) - 2 + 7) mod 7 + 1;
    task.NextRepeat := NextRepeatDate(today, task.RepeatDays);
    SetTaskRepeat(task.id, true, 0, task.NextRepeat, task.RepeatDays);
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
    number: longint;
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

procedure ChangeTaskDescriptionCmd(var params: ParamsArray; 
    ParamsCount: integer; var list: TaskList);
var
    number: longint;
    task: TTask;
    found: boolean;
    description: string;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetTaskByNumber(number, list, task, found);
    if not found then
        exit;
    description := ConcatParams(params, ParamsCount, 3);
    SetTaskDescription(task.id, description);
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

procedure ProjectTasksCmd(var params: ParamsArray; ParamsCount: integer;
    var projects: ProjectList; var project: TProject; 
    var FoundProject: boolean);
var
    number: longint;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]);
    GetProjectByNumber(number, projects, project, FoundProject);
end;

procedure ShowProjectInfo(var params: ParamsArray; ParamsCount: integer;
    var projects: ProjectList);
var
    project: TProject;
    number: longint;
    found: boolean;
    CreationDate: TTimeStamp;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]);
    GetProjectByNumber(number, projects, project, found);
    if not found then
        exit;
    PrintTitleLine('Project Info');
    writeln('- ', project.name);
    if project.description <> '' then
        writeln('- ', project.description);
    CreationDate.date := project.CreationDate;
    writeln('- Creation date: ',
        DateToStr(TimeStampToDateTime(CreationDate)));
    PrintLine(TitleLineSize, true);
    writeln;
end;

procedure ShowProjects(list: ProjectList; title: string);
var
    number: longint;
begin
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
    list := FetchProjects(false);
    name := ConcatParams(params, ParamsCount, 2);
    AddProject(name);
    ProjectListClear(list);
end;

procedure RenameProjectCmd(var params: ParamsArray; ParamsCount: integer;
    var list: ProjectList);
var
    number: longint;
    project: TProject;
    found: boolean;
    name: string;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetProjectByNumber(number, list, project, found);
    if not found then
        exit;
    name := ConcatParams(params, ParamsCount, 3);
    SetProjectName(project.id, name);
end;

procedure ChangeProjectDescriptionCmd(var params: ParamsArray; 
    ParamsCount: integer; var list: ProjectList);
var
    number: longint;
    project: TProject;
    found: boolean;
    description: string;
begin
    if ParamsCount < 3 then
        exit;
    number := StrToInt(params[2]); 
    GetProjectByNumber(number, list, project, found);
    if not found then
        exit;
    description := ConcatParams(params, ParamsCount, 3);
    SetProjectDescription(project.id, description);
end;

procedure RemoveProjectCmd(var params: ParamsArray; ParamsCount: integer;
    var list: ProjectList);
var
    number: longint;
    project: TProject;
    found: boolean;
begin
    if ParamsCount < 2 then
        exit;
    number := StrToInt(params[2]); 
    GetProjectByNumber(number, list, project, found);
    if not found then
        exit;
    RemoveProject(project.id);
end;

var
    params: ParamsArray;
    cmd: string;
    ParamsCount: integer;
    CurrentScreen: ScreenType;
    CurProject: TProject;
    found: boolean;
    tasks: TaskList;
    projects: ProjectList;
begin
    InitDatabase(TasksFilename, ProjectsFilename);
    CurrentScreen := SToday;
    ParamsCount := 0;
    tasks := nil;
    projects := nil;
    while true do
    begin
        case CurrentScreen of
            STasks: begin
                tasks := FetchTasks(0, FNone, false, false);
                ShowTasks(tasks, 'All Tasks', CurrentScreen);
            end;
            SToday: begin
                tasks := FetchTasks(0, FToday, false, false);
                ShowTasks(tasks, 'Today Tasks', CurrentScreen);
            end;
            SWeek: begin
                tasks := FetchTasks(0, FWeek, false, false);
                ShowTasks(tasks, 'Week Tasks', CurrentScreen);
            end;
            SProjectTasks: begin
                tasks := FetchTasks(CurProject.id, FNone, false, false);
                writeln('Project: ', CurProject.name);
                ShowTasks(tasks, 'Project Tasks', CurrentScreen);
            end;
            SProjectDoneTasks: begin
                tasks := FetchTasks(CurProject.id, FNone, true, false);
                writeln('Project: ', CurProject.name);
                ShowTasks(tasks, 'Project Done Tasks', CurrentScreen);
            end;
            SDoneTasks: begin
                tasks := FetchTasks(0, FNone, true, false);
                ShowTasks(tasks, 'Done Tasks', CurrentScreen);
            end;
            SRemovedTasks: begin
                tasks := FetchTasks(0, FNone, false, true);
                ShowTasks(tasks, 'Removed Tasks', CurrentScreen);
            end;
            SProjects: begin
                projects := FetchProjects(false);
                ShowProjects(projects, 'Projects');
            end;
            SRemovedProjects: begin
                projects := FetchProjects(true);
                ShowProjects(projects, 'Removed Projects');
            end;
            SHelp:
                help;
        end;
        write('(cmd) ');
        readln(cmd);
        ParseCmd(cmd, params, ParamsCount);
        if ParamsCount < 1 then
            continue;
        if params[1] = 'tl' then 
            CurrentScreen := STasks
        else if params[1] = 't' then
            CurrentScreen := SToday
        else if params[1] = 'w' then
            CurrentScreen := SWeek
        else if params[1] = 'dl' then
        begin
            if CurrentScreen = SProjectTasks then
                CurrentScreen := SProjectDoneTasks
            else 
                CurrentScreen := SDoneTasks
        end
        else if params[1] = 'p' then 
        begin
            ProjectTasksCmd(params, ParamsCount, projects, CurProject, found);
            if found then
                CurrentScreen := SProjectTasks;
        end
        else if params[1] = 'pl' then 
            CurrentScreen := SProjects
        else if params[1] = 'rmtasks' then
            CurrentScreen := SRemovedTasks
        else if params[1] = 'rmprojects' then
            CurrentScreen := SRemovedProjects
        else if (params[1] = 'h') or (params[1] = 'help') then
            CurrentScreen := SHelp
        else if params[1] = 'q' then
            break
        else
        begin
            case CurrentScreen of
                STasks, SProjectTasks, SToday, SWeek: begin
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
                    else if params[1] = 'ds' then
                        ChangeTaskDescriptionCmd(params, ParamsCount, tasks)
                    else if params[1] = 'i' then
                        ShowTaskInfo(params, ParamsCount, tasks)
                    else if params[1] = 'rd' then
                        RepeatDaysTaskCmd(params, ParamsCount, tasks)
                    else if params[1] = 'ri' then
                        RepeatIntervalTaskCmd(params, ParamsCount, tasks)
                end;
                SDoneTasks, SRemovedTasks, SProjectDoneTasks: begin
                    if params[1] = 'rm' then
                        RemoveTaskCmd(params, ParamsCount, tasks)
                    else if params[1] = 'd' then
                        DoneTaskCmd(params, ParamsCount, tasks)
                end;
                SProjects: begin
                    if params[1] = 'a' then
                    begin
                        AddProjectCmd(params, ParamsCount);
                        CurrentScreen := SProjects;
                    end
                    else if params[1] = 'rm' then
                        RemoveProjectCmd(params, ParamsCount, projects)
                    else if params[1] = 'n' then
                        RenameProjectCmd(params, ParamsCount, projects)
                    else if params[1] = 'ds' then
                        ChangeProjectDescriptionCmd(params, ParamsCount, 
                            projects)
                    else if params[1] = 'i' then
                        ShowProjectInfo(params, ParamsCount, projects)
                end;
                SRemovedProjects: begin
                    if params[1] = 'rm' then
                        RemoveProjectCmd(params, ParamsCount, projects)
                end;
            end;
        end;
    end;
end.
