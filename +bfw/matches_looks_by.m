function matches = matches_looks_by(event_file, looks_by)

col = ismember( event_file.categories, 'looks_by' );
matches = ismember( event_file.labels(:, col), looks_by );

end