function [stim_ts, stim_labels] = stim_file_to_fcat(stim_file)

stim_ts = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];
stim_labels = bfw.make_stim_labels( numel(stim_file.stimulation_times), numel(stim_file.sham_times) );

end