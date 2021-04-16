function out = bfw_to_cc_solo_event_format(varargin)

if ( nargin == 5 )
  sevt = varargin{1};
  events = varargin{2};
  event_labels = varargin{3};
  event_key = varargin{4};
  mask = varargin{5};
  
  src_rois = sevt(1).type;
  src_runs = sevt(1).runs;
else
  narginchk( 6, 6 );
  
  src_rois = varargin{1};
  src_runs = varargin{2};
  events = varargin{3};
  event_labels = varargin{4};
  event_key = varargin{5};
  mask = varargin{6};
end

assert_ispair( events, event_labels );

out = struct();
out.runs = src_runs;
out.type = src_rois;

for i = 1:numel(src_rois)
  roi_ind = find( event_labels, src_rois(i), mask );
  
  for j = 1:numel(src_runs)
    run_ind = find( event_labels, src_runs{j}, roi_ind );
    ts = events(run_ind, event_key('start_time'));
    durs = events(run_ind, event_key('duration'));
    out(i).time{j} = ts(:)';
    out(i).dur{j} = durs(:)' * 1e3; % to ms
  end
end

end