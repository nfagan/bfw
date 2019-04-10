function name = cs_get_directory_name(p)

split = strsplit( p, filesep );

if ( numel(split) < 3 || ~strcmp(split{end-2}, 'intermediates') )
  name = split{end};
else
  name = strjoin( split(end-1:end), filesep );
end

end