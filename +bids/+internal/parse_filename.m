function p = parse_filename(filename, fields)
  %
  % Split a filename into its building constituents
  %
  % USAGE::
  %
  %   p = bids.internal.parse_filename(filename, fields)
  %
  % :param filename: fielname to parse that follows the pattern
  %                  ``sub-label[_entity-label]*_suffix.extension``
  % :type  filename: string
  % :param fields:   cell of strings of the entities to use for parsing
  % :type  fields:   cell
  %
  % Example:
  %
  %   filename = '../sub-16/anat/sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz';
  %
  %   bids.internal.parse_filename(filename)
  %
  %   ans =
  %
  %   struct with fields:
  %
  %     'filename', 'sub-16_ses-mri_run-1_acq-hd_T1w.nii.gz', ...
  %     'suffix', 'T1w', ...
  %     'ext', '.nii.gz', ...
  %     'entities', struct('sub', '16', ...
  %                        'ses', 'mri', ...
  %                        'run', '1', ...
  %                        'acq', 'hd');
  %
  % __________________________________________________________________________

  % Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
  % Copyright (C) 2018--, BIDS-MATLAB developers

  fields_order = {'filename', 'ext', 'suffix', 'entities', 'prefix'};
  p.filename = bids.internal.file_utils(filename, 'filename');

  % -Identify prefix as string coming before 'sub-'
  pos = strfind(p.filename, 'sub-');
  if numel(pos) ~= 1
    warning(['File name ' p.filename ' not bids compatible']);
    p = struct([]);
    return
  end
  p.prfix = p.filename(1:pos-1);
  basename = p.filename(pos:end);

  % -Identify all the BIDS entity-label pairs present in the filename (delimited by "_")
  [parts, dummy] = regexp(basename{end}, '(?:_)+', 'split', 'match'); %#ok<ASGLU>

  % -Identify the suffix and extension of this file
  [p.suffix, p.ext] = strtok(parts{end}, '.');

  % -Separate the entity from the label for each pair identified above
  for i = 1:numel(parts) - 1
    [d, dummy] = regexp(parts{i}, '(?:\-)+', 'split', 'match'); %#ok<ASGLU>
    try
      p.entities.(d{1}) = d{2};
    catch
      warning('bidsMatlab:incorrectNameFormat', ...
              'Ignoring incorrectly formatted file %s.', p.filename);
      p = struct([]);
    end
  end

  % -Extra fields can be added to the structure and ordered specifically.
  if nargin == 2
    for i = 1:numel(fields)
      p.entities = bids.internal.add_missing_field(p.entities, fields{i});
    end
    try
      p = orderfields(p, fields_order);
      p.entities = orderfields(p.entities, fields);
    catch
      warning('bidsMatlab:noMatchingTemplate', ...
              'Ignoring file %s not matching template.', p.filename);
      p = struct([]);
    end
  end

end
