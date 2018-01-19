function f = make_intermediate_filename( base_filename, outer_dir, file_id )

f = sprintf( '%s_%s_%s.mat', base_filename, outer_dir, file_id);

end