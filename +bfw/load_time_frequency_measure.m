function [data, labels, freqs, t, is_ok] = load_time_frequency_measure(mats, varargin)

%   LOAD_TIME_FREQUENCY_MEASURE -- Load time frequency data from files.
%
%     [data, labels, freqs, t] = bfw.load_time_frequency_measure( mats );
%     loads and concatenates the contents of each .mat file given by
%     `mats`. `data` is the time frequency data; `labels` is an fcat array
%     identifying rows of `data`; `freqs` is a vector of frequencies; `t`
%     is a vector of time points.
%
%     Each .mat file is assumed to contain a single struct variable. For a
%     given file, `data` is file.data; `freqs` is file.f; `t` is file.t;
%     and `labels` is constructed from the file via fcat.from( file );
%
%     [...] = bfw.load_time_frequency_measure( ..., 'name', func ); uses
%     'name', value paired arguments to supply functions that control how
%     data, labels, freqs, and t are extracted from each file. Each
%     function receives the loaded file as an input and returns a single
%     output. In particular:
%
%       'load_func' -> Handle to a function that loads the file into one
%       struct.
%       'get_data_func' -> Handle to a function that returns `data`.
%       'get_labels_func' -> Handle to a function that returns `labels`.
%       'get_time_func' -> Handle to a function that returns `t`.
%       'get_freqs_func' -> Handle to a function that returns `freqs.
%
%     [...] = bfw.load_time_frequency_measure( ..., 'check_skip_func', func );
%     Gives a handle to a function `func` that accepts the loaded file as
%     an input and returns true if and only if the file should be excluded
%     from the output.
%
%     [...] = bfw.load_time_frequency_measure( ..., 'uniform_output', value ); 
%     uses the logical scalar `value` to indicate whether `data` has the
%     same size across `mats`, and whether `freqs` and `t` have the same
%     size and values across `mats`. Default is true. If false, then each
%     output is an Mx1 cell array where M is the number of files that were
%     not skipped with 'check_skip_func'.
%
%     [..., is_ok] = bfw.load_time_frequency_measure(...) also returns a 
%     logical vector whose true elements correspond to files in `mats` that 
%     were *not* skipped.
%
%     EX //
%
%     % Load time-frequency data from mat files given by `mats`. We pass in
%     % a custom 'get_freqs_func', because the frequencies in each file are
%     % accessible as file.freqs
%     [data, labels, freqs, t] = bfw.load_time_frequency_measure( mats ...
%       , 'get_freqs_func', @(file) file.freqs ...
%     );
%
%     See also fcat

defaults = struct();
defaults.get_data_func = @(x) x.data;
defaults.get_labels_func = @(x) fcat.from(x);
defaults.get_time_func = @(x) x.t;
defaults.get_freqs_func = @(x) x.f;
defaults.check_skip_func = @(x) false;
defaults.load_func = @shared_utils.io.fload;
defaults.uniform_output = true;

params = bfw.parsestruct( defaults, varargin );

all_data = cell( numel(mats), 1 );
all_labels = cell( size(all_data) );
ts = cell( size(all_data) );
fs = cell( size(all_data) );

is_ok = true( size(all_data) );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  measure_file = params.load_func( mats{i} );
  
  if ( params.check_skip_func(measure_file) )
    is_ok(i) = false;
    continue;
  end
  
  all_data{i} = params.get_data_func( measure_file );
  all_labels{i} = params.get_labels_func( measure_file );
  ts{i} = params.get_time_func( measure_file );
  fs{i} = params.get_freqs_func( measure_file );
end

if ( params.uniform_output )
  data = vertcat( all_data{is_ok} );
  labels = vertcat( fcat(), all_labels{is_ok} );

  first_ok = find( is_ok, 1 );

  if ( ~isempty(first_ok) )
    freqs = fs{first_ok};
    t = ts{first_ok};
  else
    freqs = [];
    t = [];
  end
else
  data = all_data(is_ok);
  labels = all_labels(is_ok);
  freqs = fs(is_ok);
  t = ts(is_ok);
end

assert_ispair( data, labels );

end