function combos = parameterSelectorExpandGrid(rows, methods, maxCombos)
%PARAMETERSELECTOREXPANDGRID  Sweep combinations for any set of steps.
%
%   combos = parameterSelectorExpandGrid(rows, methods, maxCombos)
%
% ARGUMENTS
%   rows       struct array from parameterSelectorStepRows, with .tune set
%              on the parameters to sweep (.min:.inc:.max for numeric ones;
%              .choices for logical and option-list ones). Untuned rows are
%              left at their live values.
%   methods    N-by-3 cell {stepPath, cellstr of candidate methods, current
%              method}; a step with several candidates, or one candidate
%              that is not its current method, has its .method set too.
%              {} when no step has a method choice.
%   maxCombos  optional limit (default 100000): error
%              parameterSelectorExpandGrid:tooMany beyond it.
%
% RETURNS
%   combos     struct array for funcSweepRun: combos(k).set is an N-by-2
%              cell {dotted path, value}.
%
% As in parameterSelectorExpandCombos, candidate methods of one step are
% UNIONED (method B's ranges never multiply method A's), a method's own
% fields and the fields shared by all methods are crossed, and the steps are
% crossed with each other. A candidate method with nothing tuned still
% contributes one combination.

% SPDX-License-Identifier: GPL-2.0-or-later

    if nargin < 3 || isempty(maxCombos), maxCombos = 100000; end
    if isempty(methods), methods = cell(0, 3); end

    steps = unique({rows([rows.tune]).step}, 'stable');
    steps = [methods(:,1)', setdiff(steps, methods(:,1)', 'stable')];

    % count first, so a huge grid is refused before it is built
    counts = zeros(1, numel(steps));
    for s = 1:numel(steps)
        counts(s) = stepCount(rows, steps{s}, stepMethods(methods, steps{s}));
    end
    total = prod(counts);
    if total > maxCombos
        error('parameterSelectorExpandGrid:tooMany', ...
            'The sweep has %d combinations; the limit is %d.', total, maxCombos);
    end

    perStep = cell(1, numel(steps));
    for s = 1:numel(steps)
        perStep{s} = stepSets(rows, steps{s}, methods);
    end

    combos = struct('set', cell(1, max(total, 1)));
    if isempty(steps)
        combos(1).set = cell(0, 2);
        return
    end
    nPer = cellfun(@numel, perStep);
    for k = 1:total
        idx = k - 1;
        set = cell(0, 2);
        for s = 1:numel(steps)
            set = [set; perStep{s}{mod(idx, nPer(s)) + 1}]; %#ok<AGROW>
            idx = floor(idx / nPer(s));
        end
        combos(k).set = set;
    end
end

function list = stepMethods(methods, step)
    list = {''};
    k = find(strcmp(methods(:,1), step), 1);
    if ~isempty(k), list = methods{k,2}; end
end

function n = stepCount(rows, step, list)
    n = 0;
    shared = valueCount(rows, step, '');
    for m = 1:numel(list)
        if isempty(list{m})
            n = n + shared;
        else
            n = n + shared * valueCount(rows, step, list{m});
        end
    end
end

function n = valueCount(rows, step, method)
    n = 1;
    for r = selected(rows, step, method)
        n = n * numel(rowValues(r));
    end
end

function r = selected(rows, step, method)
    r = rows([rows.tune] & strcmp({rows.step}, step) & strcmp({rows.method}, method));
end

function sets = stepSets(rows, step, methods)
    list = stepMethods(methods, step);
    shared = expandRows(selected(rows, step, ''));
    sets = {};
    k = find(strcmp(methods(:,1), step), 1);
    for m = 1:numel(list)
        if isempty(list{m})
            own = {cell(0, 2)};
        else
            own = expandRows(selected(rows, step, list{m}));
        end
        head = cell(0, 2);
        if ~isempty(k) && (numel(list) > 1 || ~strcmp(list{m}, methods{k,3}))
            head = {[step '.method'], list{m}};
        end
        for a = 1:numel(shared)
            for b = 1:numel(own)
                sets{end+1} = [head; shared{a}; own{b}]; %#ok<AGROW>
            end
        end
    end
end

function out = expandRows(r)
    n = numel(r);
    if n == 0
        out = {cell(0, 2)};
        return
    end
    vals = arrayfun(@rowValues, r, 'UniformOutput', false);
    nV = cellfun(@numel, vals);
    out = cell(1, prod(nV));
    for k = 1:numel(out)
        idx = k - 1;
        set = cell(n, 2);
        for i = 1:n
            set{i,1} = r(i).path;
            set{i,2} = vals{i}{mod(idx, nV(i)) + 1};
            idx = floor(idx / nV(i));
        end
        out{k} = set;
    end
end

function v = rowValues(r)
    if strcmp(r.type, 'numeric')
        x = r.min:r.inc:r.max;
        if isempty(x)
            error('parameterSelectorExpandGrid:emptyRange', ...
                'Parameter "%s" has an empty range [%.4g:%.4g:%.4g].', r.path, r.min, r.inc, r.max);
        end
        x = round(x, 10, 'significant');      % 0.1:0.1:0.3 without floating-point tails
        if r.integer, x = unique(round(x)); end
        v = num2cell(x);
    else
        v = r.choices;
    end
end
