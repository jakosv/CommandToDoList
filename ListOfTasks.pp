unit ListOfTasks;

interface
uses TaskRecord;

type
    TaskItemPtr = ^TaskItem;
    TaskItem = record
        task: TTask;
        next: TaskItemPtr;
    end;
    TaskList = TaskItemPtr;

procedure TaskListInit(var list: TaskList);
procedure TaskListAdd(var list: TaskList; var task: TTask);
procedure TaskListRemove(var list: TaskList; var task: TTask);
function TaskListIsEmpty(list: TaskList): boolean;
procedure TaskListClear(var list: TaskList);

implementation

procedure TaskListInit(var list: TaskList);
begin
    list := nil;
end;

procedure TaskListAdd(var list: TaskList; var task: TTask);
var
    tmp: TaskItemPtr;
begin
    new(tmp);
    tmp^.task := task;
    tmp^.next := list;
    list:= tmp;
end;

procedure TaskListRemove(var list: TaskList; var task: TTask);
var
    tmp: TaskItemPtr;
    PtrToTaskItemPtr: ^TaskItemPtr;
begin
    PtrToTaskItemPtr := @(list);
    while PtrToTaskItemPtr^ <> nil do
    begin
        if PtrToTaskItemPtr^^.task.id = task.id then
        begin
            tmp := PtrToTaskItemPtr^;
            PtrToTaskItemPtr^ := PtrToTaskItemPtr^^.next;
            dispose(tmp);
            exit;
        end;
        PtrToTaskItemPtr := @(PtrToTaskItemPtr^^.next);
    end;
end;

procedure TaskListClear(var list: TaskList);
var
    tmp: TaskItemPtr;
begin
    while not TaskListIsEmpty(list) do
    begin
        tmp := list;
        list := list^.next;
        TaskListRemove(list, tmp^.task);
    end;
end;

function TaskListIsEmpty(list: TaskList): boolean;
begin
    TaskListIsEmpty := (list = nil);
end;

end.

