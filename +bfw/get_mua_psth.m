function [dat, labs, t, params] = get_mua_psth(files, varargin)

defaults = struct();
defaults.min_interspike_interval = 0;

params = bfw.parsestruct( defaults, varargin );

thresh = params.min_interspike_interval;

[dat, labs, ts, params] = bfw.cells( numel(files), 1 );

parfor i = 1:numel(files)
  shared_utils.general.progress( i, numel(files) );
  
  pt_mua_file = shared_utils.io.fload( files{i} );
  
  factor = 1 / pt_mua_file.params.window_size;
  measure = pt_mua_file.data;
  binned_spikes = measure.data;
  
  if ( thresh > 0 )
    binned_spikes = cellfun( @(x) remove_lt(x, thresh), binned_spikes, 'un', 0 );
  end
  
  fr = cellfun( @(x) numel(x) * factor, binned_spikes );
  
  labs{i} = fcat.from( measure.labels );
  dat{i} = fr;
  ts{i} = pt_mua_file.time;
  params{i} = pt_mua_file.params;
end

dat = vertcat( dat{:} );
labs = vertcat( fcat(), labs{:} );
t = ts{1};
params = params{1};

end

function y = remove_lt(x, thresh)

N = numel( x );

if ( N < 2 ), y = x; return; end

y = [];

stop = 2;
start = 1;
cont = true;

while ( cont )
  
  diffed = x(stop) - x(start);
  
  if ( diffed >= thresh )
    y(end+1) = x(start);
    start = stop;
  end
  
  stop = stop + 1;
  
  cont = start <= N && stop <= N;
end

end