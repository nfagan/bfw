function [ps, matched] = match_files(src_ps, varargin)

for i = 1:numel(varargin)
  varargin{i} = cellstr( varargin{i} );
  assert( numel(varargin{i}) == 1, 'Expected char or scalar folder path.' );
end

src_ps = cellstr( src_ps );
ps = cell( numel(src_ps), numel(varargin) + 1 );
ps(:, 1) = src_ps;

matched = false( size(ps) );
matched(:, 1) = true;

for i = 1:numel(src_ps)
  fname = shared_utils.io.filenames( src_ps{i}, true );
  for j = 1:numel(varargin)
    search_for = fullfile( varargin{j}, fname );
    if ( exist(search_for{1}, 'file') )
      matched(i, j+1) = true;
      ps(i, j+1) = search_for;
    end
  end
end

end