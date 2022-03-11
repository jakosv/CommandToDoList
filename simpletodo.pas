program SimpleToDoList;
uses sysutils, ListOfTasks, ListOfProjects, database;

const
    TasksFilename = '.tasks';
    ProjectsFilename = '.projects';
    MaxParamsCount = 255;

type
    ParamsArray = array[1..MaxParamsCount] of string;

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

function ConcatParams(var params: ParamsArray; ParamsCount: integer): string;
var
    res: string;
    i: integer;
begin
    res := '';
    for i:=2 to ParamsCount do
    begin
        res := res + params[i];
        if i <> ParamsCount then
            res := res + ' ';
    end;
    ConcatParams := res;
end;

procedure PrintTask(number: longint; var name: string);
begin
    writeln(number, '. ', name);
end;

procedure ShowTasks(tasks: TaskList);
var
    list: TaskList;
    ProjectName: string;
    number: longint;
begin
    number := 1;
    list := tasks;
    while list <> nil do
    begin
        PrintTask(number, list^.task.name);
        number := number + 1;
        list := list^.next;
    end;
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

procedure AddTaskCmd(var params: ParamsArray; ParamsCount: integer; var list:
    TaskList);
var
    name: string;
begin
    if ParamsCount < 2 then
        exit;
    name := ConcatParams(params, ParamsCount);
    AddTask(name);
    TaskListClear(list);
    list := FetchTasks;
end;


procedure RemoveTaskCmd(var params: ParamsArray; ParamsCount: integer;
    var list: TaskList);
var
    number, TaskId: longint;
    found: boolean;
begin
    number := StrToInt(params[2]); 
    GetTaskId(number, list, TaskId, found);
    if not found then
        exit;
    RemoveTask(TaskId);
    TaskListClear(list);
    list := FetchTasks;
end;

var
    tasks: TaskList;
    projects: ProjectList;
    params: ParamsArray;
    cmd: string;
    ParamsCount: integer;
begin
    InitDatabase(TasksFilename, ProjectsFilename);
    tasks := FetchTasks;
    projects := FetchProjects;
    while true do
    begin
        readln(cmd);
        ParseCmd(cmd, params, ParamsCount);
        if ParamsCount < 1 then
            continue
        else if params[1] = 'tl' then 
            ShowTasks(tasks)
        else if params[1] = 'ta' then
            AddTaskCmd(params, ParamsCount, tasks)
        else if params[1] = 'tr' then
            RemoveTaskCmd(params, ParamsCount, tasks)
        else if params[1] = 'q' then
            break;
    end;
end.
