function save_p = granger_save_p(components, varargin)

save_p = fullfile( bfw.dataroot(varargin{:}), 'analyses' ...
  , 'behavioral_granger', components{:} );

end