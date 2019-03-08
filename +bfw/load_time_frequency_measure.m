function [data, labels, freqs, t] = load_time_frequency_measure(mats, varargin)

defaults = struct();
defaults.get_data_func = @(x) x.data;
defaults.get_labels_func = @(x) fcat.from(x);
defaults.get_time_func = @(x) x.t;
defaults.get_freqs_func = @(x) x.f;
defaults.check_skip_func = @(x) false;

params = bfw.parsestruct( defaults, varargin );

all_data = cell( numel(mats), 1 );
all_labels = cell( size(all_data) );
ts = cell( size(all_data) );
fs = cell( size(all_data) );

is_ok = true( size(all_data) );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  measure_file = shared_utils.io.fload( mats{i} );
  
  if ( params.check_skip_func(measure_file) )
    is_ok(i) = false;
    continue;
  end
  
  all_data{i} = params.get_data_func( measure_file );
  all_labels{i} = params.get_labels_func( measure_file );
  ts{i} = params.get_time_func( measure_file );
  fs{i} = params.get_freqs_func( measure_file );
end

any_ok = nnz( is_ok ) > 0;

data = vertcat( all_data{is_ok} );
labels = vertcat( fcat(), all_labels{is_ok} );

if ( any_ok )
  first_ok = find( any_ok, 1 );
  
  freqs = fs{first_ok};
  t = ts{first_ok};
else
  freqs = [];
  t = [];
end

assert_ispair( data, labels );

end