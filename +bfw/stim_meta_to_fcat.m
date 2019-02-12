function f = stim_meta_to_fcat(stim_meta_file)

f = fcat.with( {'protocol_name'}, 1 );

if ( ~stim_meta_file.used_stimulation )
  protocol = 'no-stimulation';
else
  protocol = stim_meta_file.protocol_name;
end

setcat( f, 'protocol_name', protocol );

end