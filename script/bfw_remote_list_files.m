function files = bfw_remote_list_files(exts, varargin)

exts = cellstr( exts );
out = bfw_remote_ls( varargin{:} );

match = false( size(out) );
for i = 1:numel(exts)
  match = match | contains(out, exts{i});
end

matched = out(match);
matched = matched(:);

files = {};
for i = 1:numel(matched)
  split = strsplit( matched{i}, ' ' );
  
  ok = false( size(split) );
  for j = 1:numel(exts)
    ok = ok | contains( split, exts{j} );
  end
  
  if ( sum(ok) == 1 )
    files{end+1, 1} = split{ok};    
  else
    warning( '%d matches for extensions: "%s"; skipping.', sum(ok), strjoin(exts, ' ') );
  end
end

end