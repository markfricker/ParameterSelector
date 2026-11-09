function rows = parameterSelectorStepRows(stepPath, current, defaults, methods, meta)
%PARAMETERSELECTORSTEPROWS  The sweepable parameters of any pipeline step.
%
%   rows = parameterSelectorStepRows(stepPath, current, defaults, methods, meta)
%
% Builds the sweep table from the parameter schema, so that a step needs no
% code of its own to be swept. Values stay in the units the panels show (the
% step's run function converts them).
%
% ARGUMENTS
%   stepPath  dotted step path, e.g. 'organelle3d.segmentation.refine'
%   current   the step's live parameters, app.parameters.<stepPath>
%   defaults  the step's schema defaults (same shape)
%   methods   cellstr of candidate methods for a step with a .method field;
%             {} or [] for its current method only
%   meta      containers.Map from funcParameterSchemaMeta, or []
%
% RETURNS
%   rows      struct array, one per (method, parameter):
%               .step .method ('' for a field shared by every method)
%               .parameter .path (full dotted path, the owner of an aliased
%               field: paramSource methods keep base fields in their source)
%               .current .type ('numeric'|'logical'|'enum') .integer (schema
%               says integer: swept values are rounded) .options
%               .tune (false) .min .inc .max (a suggested range) .choices
%             Left out: use, method, *Previous, paramSource, *Options, input,
%             the channel/section/frame selection, and anything that is not a
%             finite scalar, a logical or an option list.
%
% A nested group without a method (organelle.refine.auto.refine) is included
% as its own step path, using its current method if it has one.

% SPDX-License-Identifier: GPL-2.0-or-later

    if nargin < 4, methods = {}; end
    if nargin < 5, meta = []; end
    rows = emptyRows();

    hasMethod = isfield(defaults, 'method') && ischar(defaults.method);
    if hasMethod
        if isempty(methods), methods = {current.method}; end
        for k = 1:numel(methods)
            rows = [rows, methodRows(stepPath, current, defaults, methods{k}, meta)]; %#ok<AGROW>
        end
    end

    names = fieldnames(defaults);
    for k = 1:numel(names)
        n = names{k};
        d = defaults.(n);
        if isstruct(d)
            if ~hasMethod
                cur = d;
                if isfield(current, n), cur = current.(n); end
                rows = [rows, parameterSelectorStepRows([stepPath '.' n], cur, d, {}, meta)]; %#ok<AGROW>
            end
            continue
        end
        if isExcluded(n), continue; end
        v = d;
        if isfield(current, n), v = current.(n); end
        r = makeRow(stepPath, '', n, [stepPath '.' n], v, d, meta);
        if ~isempty(r), rows = [rows, r]; end %#ok<AGROW>
    end
end

function rows = methodRows(stepPath, current, defaults, method, meta)
    rows = emptyRows();
    if ~isfield(defaults, method) || ~isstruct(defaults.(method)), return; end
    src = method;
    if isfield(defaults.(method), 'paramSource')
        src = defaults.(method).paramSource;
    end
    own = {};
    if ~strcmp(src, method)
        own = setdiff(fieldnames(defaults.(method)), {'paramSource'});
    end
    f = parameterSelectorMethodFields(defaults, current, method);
    for k = 1:numel(f)
        if isExcluded(f(k).name), continue; end
        owner = src;
        if ismember(f(k).name, own), owner = method; end
        d = defaults.(owner).(f(k).name);
        r = makeRow(stepPath, method, f(k).name, ...
            [stepPath '.' owner '.' f(k).name], f(k).current, d, meta);
        if ~isempty(r), rows = [rows, r]; end %#ok<AGROW>
    end
end

function tf = isExcluded(n)
    tf = any(strcmp(n, {'use','method','input','paramSource'})) ...
        || endsWith(n, 'Previous') || endsWith(n, 'Options') ...
        || ~isempty(regexp(n, '^(channel|section|frame)', 'once'));
end

function r = makeRow(stepPath, method, name, path, value, default, meta)
    r = [];
    e = funcParameterMetaResolve(meta, path, default);
    row = emptyRow();
    row.step = stepPath;  row.method = method;  row.parameter = name;
    row.path = path;      row.current = value;  row.type = e.type;
    switch e.type
        case 'logical'
            if ~isscalar(value), return; end
            row.choices = {false, true};
        case 'enum'
            if isempty(e.options), return; end
            row.options = e.options;
            row.choices = e.options;
        case 'numeric'
            if ~(isnumeric(value) && isscalar(value) && isfinite(value)), return; end
            % values are only forced to integers when the schema says so: a
            % whole-number default (bias = 1.0) does not make a field integer
            row.integer = isa(meta, 'containers.Map') && isKey(meta, path) ...
                && isfield(meta(path), 'class') && strcmp(meta(path).class, 'integer');
            [row.min, row.inc, row.max] = suggestRange(double(value), strcmp(e.class, 'integer'), e);
        otherwise
            return
    end
    r = row;
end

function [lo, inc, hi] = suggestRange(v, isInt, e)
    if isInt
        lo = v - 1;  inc = 1;  hi = v + 1;
    elseif v == 0
        lo = 0;  inc = 0.1;  hi = 0.2;
    else
        lo = round(v * 0.5, 3, 'significant');
        inc = round(abs(v) * 0.25, 3, 'significant');
        hi = round(v * 1.5, 3, 'significant');
        if lo > hi, [lo, hi] = deal(hi, lo); end
    end
    if ~isempty(e.min), lo = max(lo, e.min); end
    if ~isempty(e.max), hi = min(hi, e.max); end
end

function r = emptyRow()
    r = struct('step','', 'method','', 'parameter','', 'path','', 'current',[], ...
        'type','', 'integer',false, 'options',{{}}, 'tune',false, ...
        'min',[], 'inc',[], 'max',[], 'choices',{{}});
end

function r = emptyRows()
    r = emptyRow();
    r(1) = [];
end
