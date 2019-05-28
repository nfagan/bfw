function ac = acorr(spike_vector, window_size)

assert( issorted(spike_vector), 'Expected spike vector to be sorted in ascending order.' );

numtrain1 = length(spike_vector);
spike_vector = spike_vector .* 1e3;
% %set acorr parameter
binwidth = 1;
ac.binwidth = binwidth;
numbinsleft = window_size;
numbinsright = window_size;

window_left = -numbinsleft*binwidth - binwidth/2;
window_right = numbinsright*binwidth + binwidth/2;

bincenters = [-numbinsleft*binwidth:binwidth:numbinsright*binwidth];
window_length = length(bincenters);

ac.window_length = window_length;
ac.plot = zeros(1,window_length);
ac.bincenters = bincenters;

allRelTimes = zeros(1,20000); % to locate space, not sure this is optimal
numAllRelTimes = 0;

USE_MIN_INDS = true;
SPIKE_INDS = zeros( 1, numel(spike_vector) );
CURR_NUM_INDS = 0;
CURRENT_MIN_IND = 1;
  
% begin cc
for spike1idx = 1:length(spike_vector)
  reftime = spike_vector(spike1idx);
  leftcutoff = reftime + window_left;
  rightcutoff = reftime + window_right;

  if ( USE_MIN_INDS )
    find_spikes( spike_vector, leftcutoff, rightcutoff );
    st2indices = SPIKE_INDS(1:CURR_NUM_INDS);
  else
    st2indices = find( spike_vector > leftcutoff & spike_vector <= rightcutoff );
  end

  if ~isempty(st2indices)
    reltimes = spike_vector(st2indices) - reftime;       
    numRelTimes = length(reltimes);
    a = numAllRelTimes+1;
    b = numAllRelTimes+numRelTimes;
    allRelTimes(a:b) = reltimes;

    numAllRelTimes = numAllRelTimes + length(reltimes);
  end
end

if numAllRelTimes > 0
%     cc = convertToBins(cc,allRelTimes(1:numAllRelTimes));
%             numAllRelTimes = 0;
   ac.plot = histc(allRelTimes(1:numAllRelTimes), ac.bincenters-binwidth/2);

end

% normalization
ac.plot = ac.plot/numtrain1; % normalize by sqrt of lengths of both spike trains

  function find_spikes(spikes, min_t, max_t)
    % FIND_SPIKES -- Find spikes in the interval (min_t, max_t].
    %   `spikes` must be sorted in ascending order. Outer workspace
    %   variables are used to avoid creating a new indices array on each
    %   iteration.
    
    CURR_NUM_INDS = 0;
    need_find_start = true;
    
    for i = CURRENT_MIN_IND:numel(spikes)
      spk = spikes(i);
      
      if ( need_find_start && spk <= min_t )
        continue;
      else
        % spk > min_t
        if ( need_find_start )
          CURRENT_MIN_IND = i;
          need_find_start = false;
        end
        if ( spk <= max_t )
          % spk > min_t && spk <= max_t
          SPIKE_INDS(CURR_NUM_INDS+1) = i;
          CURR_NUM_INDS = CURR_NUM_INDS + 1;
        else
          % spk > max_t
          break;
        end
      end
    end

  end

end

