function missing = diff(saved_conf, display)

%   DIFF -- Return missing fields in the saved config file.
%
%     missing = ... diff() compares the saved config file and the config
%     file that would be created by ... config.create(). Fields that are
%     present in the created config file but absent in the saved config
%     file are returned in `missing`. If no fields are missing, `missing`
%     is an empty cell array.
%
%     ... diff(), without an output argument, displays missing fields
%     in a human-readable way.
%
%     ... diff( conf ) uses the config file `conf` instead of the saved
%     config file.
%
%     ... diff( ..., false ) does not display missing fields.
%
%     IN:
%       - `saved_conf` (struct) |OPTIONAL|
%     OUT:
%       - `missing` (cell array of strings, {})

import shared_utils.assertions.*;

if ( nargin < 1 )
  saved_conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( saved_conf );
end
if ( nargin < 2 )
  if ( nargout == 0 )
    display = true;
  else
    display = false;
  end
else
  assert( isa(display, 'logical'), 'Display flag must be logical scalar.' );
end

created_conf = bfw.config.create( false ); % false to not save conf

missing = get_missing( created_conf, saved_conf, '', 0, {}, display );

if ( ~display ), return; end
if ( isempty(missing) ), fprintf( '\nAll up-to-date.' ); end
fprintf( '\n' );

end

function missed = get_missing( created, saved, parent, ntabs, missed, display )

%   GET_MISSING -- Identify missing fields, recursively.

if ( ~isstruct(created) ), return; end

created_fields = fieldnames( created );
saved_fields = fieldnames( saved );

missing = setdiff( created_fields, saved_fields );
shared = intersect( created_fields, saved_fields );

tabrep = @(x) repmat( '   ', 1, x );
join_func = @(x) sprintf( '%s.%s', parent, x );

if ( numel(missing) > 0 )
  if ( display )
    fprintf( '\n%s - %s', tabrep(ntabs), parent );
    cellfun( @(x) fprintf('\n%s - %s', tabrep(ntabs+1), x), missing, 'un', false );
  end
  missed(end+1:end+numel(missing)) = cellfun( join_func, missing, 'un', false );
end

for i = 1:numel(shared)
  created_ = created.(shared{i});
  saved_ = saved.(shared{i});
  missed = get_missing( created_, saved_, shared{i}, ntabs+1, missed, display );
end

end