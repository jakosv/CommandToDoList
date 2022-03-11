unit ListOfProjects;

interface
uses ProjectRecord;

type
    ProjectItemPtr = ^ProjectItem;
    ProjectItem = record
        project: TProject;
        next: ProjectItemPtr;
    end;
    ProjectList = ProjectItemPtr;

procedure ProjectListInit(var list: ProjectList);
procedure ProjectListAdd(var list: ProjectList; var project: TProject);
procedure ProjectListRemove(var list: ProjectList; var project: TProject);
function ProjectListIsEmpty(list: ProjectList): boolean;
procedure ProjectListClear(var list: ProjectList);

implementation

procedure ProjectListInit(var list: ProjectList);
begin
    list := nil;
end;

procedure ProjectListAdd(var list: ProjectList; var project: TProject);
var
    tmp: ProjectItemPtr;
begin
    new(tmp);
    tmp^.project := project;
    tmp^.next := list;
    list:= tmp;
end;

procedure ProjectListRemove(var list: ProjectList; var project: TProject);
var
    tmp: ProjectItemPtr;
    PtrToProjectItemPtr: ^ProjectItemPtr;
begin
    PtrToProjectItemPtr := @(list);
    while PtrToProjectItemPtr^ <> nil do
    begin
        if PtrToProjectItemPtr^^.project.id = project.id then
            break;
        PtrToProjectItemPtr := @(PtrToProjectItemPtr^^.next);
    end;
    tmp := PtrToProjectItemPtr^;
    PtrToProjectItemPtr^ := PtrToProjectItemPtr^^.next;
    dispose(tmp);
end;

procedure ProjectListClear(var list: ProjectList);
begin
    while not ProjectListIsEmpty(list) do
    begin
        ProjectListRemove(list, list^.project);
        list := list^.next;
    end;
end;

function ProjectListIsEmpty(list: ProjectList): boolean;
begin
    ProjectListIsEmpty := (list = nil);
end;

end.

