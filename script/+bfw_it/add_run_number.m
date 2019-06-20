function labels = add_run_number(labels)

[I, unified_filenames] = findall( labels, 'unified_filename' );
addcat( labels, 'run_number' );

for i = 1:numel(I)
  un_filename = unified_filenames{i};
  task_str = 'image_control_';
  
  str_ind = max( strfind(un_filename, task_str) );
  dot_ind = min( strfind(un_filename, '.mat') );
  
  if ( ~isempty(str_ind) && ~isempty(dot_ind) && dot_ind > str_ind )
    num = str2double( un_filename(str_ind+numel(task_str):dot_ind-1) );
    run_str = sprintf( 'run_number-%d', num );
    setcat( labels, 'run_number', run_str, I{i} );
  end
end

end