function spike_file = require_spike_file(spike_p, spike_file)

if ( spike_file.is_link )
  spike_file = shared_utils.io.fload( fullfile(spike_p, spike_file.data_file) );
end

end