function p = get_project_folder()

p = fileparts( which('bfw.util.get_project_folder') );

for i = 1:2
  p = fileparts( p );
end

end