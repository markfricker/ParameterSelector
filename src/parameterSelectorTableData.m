function T = parameterSelectorTableData(rows)
%PARAMETERSELECTORTABLEDATA  The sweep table as shown in the window.
%
%   T = parameterSelectorTableData(rows)
%
% One row per parameter. Min / Inc / Max are NaN for ticks and option lists,
% which sweep through every choice when Tune is ticked.

% SPDX-License-Identifier: GPL-2.0-or-later

    n = numel(rows);
    Step = cell(n, 1); Method = cell(n, 1); Parameter = cell(n, 1); Current = cell(n, 1);
    Tune = false(n, 1); Min = nan(n, 1); Inc = nan(n, 1); Max = nan(n, 1);
    for i = 1:n
        r = rows(i);
        parts = strsplit(r.step, '.');
        Step{i} = strjoin(parts(3:end), '.');
        Method{i} = r.method;
        Parameter{i} = r.parameter;
        Current{i} = valueText(r.current);
        Tune(i) = r.tune;
        if strcmp(r.type, 'numeric')
            Min(i) = r.min; Inc(i) = r.inc; Max(i) = r.max;
        end
    end
    T = table(Step, Method, Parameter, Current, Tune, Min, Inc, Max);
end

function s = valueText(v)
    if ischar(v) || isstring(v)
        s = char(v);
    elseif islogical(v)
        s = char(string(v));
    else
        s = sprintf('%g', v);
    end
end
