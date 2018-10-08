function tf = any_empty(varargin)

tf = any( cellfun(@isempty, varargin) );

end