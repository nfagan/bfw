function [stim_ts, labels] = files_to_pair(stim_file, stim_meta_file, meta_file)

[stim_ts, labels] = bfw.stim_file_to_pair( stim_file );
join( labels, bfw.struct2fcat(meta_file), bfw.stim_meta_to_fcat(stim_meta_file) );

end