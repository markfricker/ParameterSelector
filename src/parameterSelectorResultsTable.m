function T = parameterSelectorResultsTable(results, metric)
%PARAMETERSELECTORRESULTSTABLE  Sweep results for display, best first.
%
%   T = parameterSelectorResultsTable(results, metric)
%
% results is funcSweepRun output. Ranked by metric, largest first, with
% combinations that have no score (NaN, or an error) last. The settings are
% shown without the shared strand.module prefix; 'combo' stays the index
% into the combinations for Apply.

% SPDX-License-Identifier: GPL-2.0-or-later

    T = results;
    if ismember(metric, T.Properties.VariableNames)
        T = sortrows(T, metric, 'descend', 'MissingPlacement', 'last');
    end
    T.settings = regexprep(string(T.settings), '(^|;)[^.;=]+\.[^.;=]+\.', '$1');
    drop = intersect(T.Properties.VariableNames, {'filename', 'rerunFrom'});
    T(:, drop) = [];
end
