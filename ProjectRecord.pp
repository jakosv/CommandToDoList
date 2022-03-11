unit ProjectRecord;

interface
type
    TProject = record
        id: longint;
        name: string;
        removed: boolean;
    end;
    FileOfProject = file of TProject;

function ProjectRecordCount(var ProjectsFile: FileOfProject): longint;
procedure SetProjectRecordCount(NewCount: longint;
    var ProjectsFile: FileOfProject);
procedure GetProjectRecord(id: longint; var project: TProject;
    var ProjectsFile: FileOfProject);
procedure GetProjectRecordName(id: longint; var name: string;
    var ProjectsFile: FileOfProject);
procedure SetProjectRecord(id: longint; var project: TProject;
    var ProjectsFile: FileOfProject);
procedure SetProjectRecordRemoved(id: longint; var ProjectsFile: FileOfProject);
procedure AddProjectRecord(var name: string; var ProjectsFile: FileOfProject);

implementation
uses sysutils;

function ProjectRecordCount(var ProjectsFile: FileOfProject): longint;
var
    tmp: TProject;
begin
    GetProjectRecord(0, tmp, ProjectsFile);
    ProjectRecordCount := tmp.id;
end;

procedure SetProjectRecordCount(NewCount: longint; 
    var ProjectsFile: FileOfProject);
var
    tmp: TProject;
begin
    GetProjectRecord(0, tmp, ProjectsFile);
    tmp.id := NewCount;
end;

procedure GetProjectRecord(id: longint; var project: TProject;
    var ProjectsFile: FileOfProject);
begin
    seek(ProjectsFile, id);
    read(ProjectsFile, project);
end;

procedure GetProjectRecordName(id: longint; var name: string;
    var ProjectsFile: FileOfProject);
var
    tmp: TProject;
begin
    GetProjectRecord(id, tmp, ProjectsFile);
    name := tmp.name;
end;

procedure SetProjectRecord(id: longint; var project: TProject; 
    var ProjectsFile: FileOfProject);
begin
    seek(ProjectsFile, id);
    write(ProjectsFile, project);
end;

procedure SetProjectRecordName(id: longint; var name: string;
    var ProjectsFile: FileOfProject);
var
    tmp: TProject;
begin
    GetProjectRecord(id, tmp, ProjectsFile); 
    tmp.name := name;
    SetProjectRecord(id, tmp, ProjectsFile);
end;

procedure SetProjectRecordRemoved(id: longint; var ProjectsFile: FileOfProject);
var
    tmp: TProject;
begin
    GetProjectRecord(id, tmp, ProjectsFile); 
    tmp.removed := not tmp.removed;
    SetProjectRecord(id, tmp, ProjectsFile);
end;

procedure AddProjectRecord(var name: string; var ProjectsFile: FileOfProject);
var
    tmp: TProject;
begin
    tmp.id := ProjectRecordCount(ProjectsFile);
    tmp.name := name;
    tmp.removed := false;
    SetProjectRecord(tmp.id, tmp, ProjectsFile);
end;

end.
