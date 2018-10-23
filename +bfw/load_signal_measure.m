function [data, labs, freqs, t] = load_signal_measure(mats, varargin)

defaults = struct();
defaults.check_continue = @default_check_continue;
defaults.get_measure = @default_get_measure;
defaults.get_time = @default_get_time;
defaults.get_freqs = @default_get_freqs;
defaults.get_measure_type = @default_get_measure_type;

params = bfw.parsestruct( defaults, varargin );

%   funcs
check_continue = params.check_continue;
get_measure = params.get_measure;
get_measure_type = params.get_measure_type;
get_time = params.get_time;
get_freqs = params.get_freqs;

s = size( mats );

[data, labs, t, freqs] = mkcells( s );
empties = true( s );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  lfpfile = shared_utils.io.fload( mats{i} );
  
  if ( check_continue(lfpfile) ), continue; end
  
  measure = get_measure( lfpfile );
  meast = get_measure_type( lfpfile );
  onet = get_time( lfpfile );
  onefreqs = get_freqs( lfpfile );
  
  data{i} = measure.data;
  labs{i} = addsetcat( fcat.from(measure.labels), 'measure', meast );
  t{i} = onet;
  freqs{i} = onefreqs;
  
  assert( numel(onet) == size(data{i}, 3), 'Time series does not match data.' );
  assert( numel(onefreqs) == size(data{i}, 2), 'Frequencies do not match data.' );
  
  empties(i) = isempty( data{i} );
end

data(empties) = [];
labs(empties) = [];
t(empties) = [];
freqs(empties) = [];

data = vertcat( data{:} );
labs = vertcat( fcat, labs{:} );

assert_ispair( data, labs );

if ( ~isempty(freqs) )
  freqs = freqs{1}; 
else
  freqs = [];
end

if ( ~isempty(t) )
  t = t{1};
else
  t = [];
end

end

function varargout = mkcells( s )
for i = 1:nargout
  varargout{i} = cell( s );
end
end

function mt = default_get_measure_type(lfpfile)
mt = lfpfile.params.meas_type;
end

function tf = default_check_continue(lfpfile)
tf = bfw.field_or( lfpfile, 'is_link', false );
end

function f = default_get_freqs(lfpfile)
f = bfw.field_or( lfpfile, 'frequencies', [] );
end

function t = default_get_time(lfpfile)
ss = lfpfile.within_trial_params.step_size;
lb = lfpfile.align_params.look_back;
la = lfpfile.align_params.look_ahead;

t = lb:ss:la;
end

function meas = default_get_measure(lfpfile)
meas = bfw.field_or( lfpfile, 'measure', SignalContainer(Container()) );
end